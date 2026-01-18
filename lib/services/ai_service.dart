import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:Assist/data/models/task.dart';
import 'package:Assist/data/models/ai_recommendation.dart';
import 'package:Assist/services/localization_service.dart';
import 'package:http/http.dart' as http;

/// Abstraction for AI-related operations (recommendations, analysis).
/// Kept backward-compatible with existing callers in your project.
abstract class AIService {
  Future<List<AIRecommendation>> fetchRecommendations(List<Task> context);

  Future<String?> generateTaskDescriptionSuggestion({
    String? title,
    String? category,
  });

  /// Legacy name kept for compatibility.
  /// Returns a very short continuation for typing (plain text).
  Future<String?> generateAssistantCompletion({
    required String input,
    List<Task>? context,
  });
}

class OllamaAIService implements AIService {
  final String baseUrl;
  final String model;
  final Duration timeout;
  final http.Client _client;
  final LocalizationService? localizationService;

  /// Prompt tuning center: adjust assistant behavior here.
  /// (No code writing, no JSON output.)
  final String? _systemPromptOverride;

  OllamaAIService({
    // Android emulator note: you may need http://10.0.2.2:11434
    this.baseUrl = 'http://localhost:11434',
    this.model = 'neural-chat:latest',
    Duration? timeout,
    http.Client? client,
    this.localizationService,
    String? systemPrompt,
  })  : timeout = timeout ?? const Duration(seconds: 25),
        _client = client ?? http.Client(),
        _systemPromptOverride = systemPrompt;

  AppLanguage _currentLanguage() {
    return localizationService?.currentLanguage ?? AppLanguage.turkish;
  }

  String _systemPrompt(AppLanguage language) {
    if (_systemPromptOverride != null) return _systemPromptOverride!;
    if (language == AppLanguage.english) {
      return '''
You are an AI assistant inside the Assist app.
Your job: write short, direct, result-oriented text for the user.

Strict rules:
1. Output only what is asked.
2. Never write meta text like "Here is" or "I will".
3. Do not use quotation marks.
4. Respond in English only.
''';
    }
    return '''
Sen Assist uygulamasında çalışan bir yapay zeka asistanısın.
Görevin: Kullanıcı için kısa, doğrudan ve sonuca odaklı metinler üretmek.

Kesin Kurallar:
1. Sadece istenen çıktıyı ver.
2. "Bunu yapıyorum", "İşte önerim", "Kullanıcı görev ekliyor" gibi giriş/meta cümleleri ASLA yazma.
3. Tırnak işareti kullanma.
4. Sadece Türkçe yanıt ver.
''';
  }

  List<String> _allowedCategories(AppLanguage language) {
    final loc = localizationService;
    if (loc != null) {
      return [
        loc.categoryWork,
        loc.categoryPersonal,
        loc.categoryShopping,
        loc.categoryHealth,
        loc.categoryOther,
      ];
    }
    if (language == AppLanguage.english) {
      return ['Work', 'Personal', 'Shopping', 'Health', 'Other'];
    }
    return ['İş', 'Kişisel', 'Alışveriş', 'Sağlık', 'Diğer'];
  }

  // -----------------------------
  // 1) Recommendations (NO JSON)
  // -----------------------------
  @override
  Future<List<AIRecommendation>> fetchRecommendations(List<Task> context) async {
    final uri = Uri.parse('$baseUrl/api/generate');

    final language = _currentLanguage();
    final prompt = _buildRecommendationsPrompt(context, language);

    final payload = <String, dynamic>{
      'model': model,
      'prompt': prompt,
      'stream': false,
      // No format: 'json'
      'options': {
        'temperature': 0.35,
        'top_p': 0.9,
        'num_predict': 260,
      },
      'raw': true,
    };

    try {
      final response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception('Ollama error: ${response.statusCode} ${response.body}');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final text = decoded['response']?.toString().trim() ?? '';

      // Convert plain text into 3 recommendations.
      final recs = _parseRecommendationsFromPlainText(text, language, context);

      final now = DateTime.now();
      return [
        for (var i = 0; i < recs.length; i++)
          AIRecommendation(
            id: 'ai-${now.millisecondsSinceEpoch}-$i',
            title: recs[i].$1,
            description: recs[i].$2,
            category: recs[i].$3,
            icon: _iconForCategory(recs[i].$3),
            createdAt: now,
          ),
      ];
    } catch (e) {
       print('AI Service Error (Recs): $e');
       // Fallback mock data
       final now = DateTime.now();
       final categories = _allowedCategories(language);
       if (language == AppLanguage.english) {
         return [
           AIRecommendation(
             id: 'ai-mock-1',
             title: 'Plan your day',
             description: 'Pick the top 3 tasks for today.',
             category: categories.last,
             icon: Icons.event,
             createdAt: now,
           ),
           AIRecommendation(
             id: 'ai-mock-2',
             title: 'Take a short break',
             description: 'Do a 5-minute breathing exercise.',
             category: categories[3],
             icon: Icons.favorite,
             createdAt: now,
           ),
         ];
       }
       return [
        AIRecommendation(
          id: 'ai-mock-1',
          title: 'Günlük planını yap',
          description: 'Bugün için en önemli 3 görevi belirle.',
          category: categories.last,
          icon: Icons.event,
          createdAt: now,
        ),
        AIRecommendation(
          id: 'ai-mock-2',
          title: 'Kısa mola ver',
          description: 'Verimliliğini artırmak için 5 dakika nefes egzersizi yap.',
          category: categories[3],
          icon: Icons.favorite,
          createdAt: now,
        ),
       ];
    }
  }

  String _buildRecommendationsPrompt(List<Task> tasks, AppLanguage language) {
    final categories = _allowedCategories(language);
    final categoryList = categories.join(', ');
    final taskList = tasks.take(10).map((t) {
      final due = t.date.toIso8601String().split('T').first;
      final category = (t.category == null || t.category!.trim().isEmpty)
          ? categories.last
          : t.category!;
      final flags = [
        if (t.isImportant) language == AppLanguage.english ? 'important' : 'önemli',
        if (t.isCompleted) language == AppLanguage.english ? 'completed' : 'tamamlandı',
      ].join(', ');
      final flagText = flags.isEmpty ? '' : ', $flags';
      return language == AppLanguage.english
          ? '- ${t.title} (date: $due, category: $category$flagText)'
          : '- ${t.title} (tarih: $due, kategori: $category$flagText)';
    }).join('\n');

    if (language == AppLanguage.english) {
      return '''
${_systemPrompt(language)}

Create 3 actionable recommendations based on the user's tasks.
Format (STRICT):
• Title | Description | Category

Rules:
- Title: 3-6 words, start with a verb.
- Description: one sentence, ends with a period.
- Category: use exactly one of: $categoryList.
- Prioritize incomplete and important tasks.
- Prefer the user's task categories when possible.
- Do not invent new category names.
- If a task's category is Other, infer a better category from the task text.
- Do not output headers or labels like "Title" or "Description".
- Do not include the word "category" in the title or description.
- Each recommendation must be different and focus on a different task or action.
- Plain text only (no JSON).
- English.

Tasks:
$taskList

Recommendations:
''';
    }

    return '''
${_systemPrompt(language)}

Kullanıcının görevlerine göre 3 uygulanabilir öneri üret.
Format (KESİN):
• Başlık | Açıklama | Kategori

Kurallar:
- Başlık 3-6 kelime, eylem fiiliyle başlasın.
- Açıklama tek cümle olsun ve nokta ile bitsin.
- Kategori şu listeden biri olsun: $categoryList.
- Tamamlanmamış ve önemli görevlere öncelik ver.
- Mümkünse kullanıcının görev kategorilerini kullan.
- Yeni kategori adı uydurma.
- Kategori "Diğer" ise metinden daha uygun kategori çıkar.
- "Başlık", "Açıklama" gibi etiketleri yazma.
- Başlık veya açıklamada "kategori" kelimesini kullanma.
- Her öneri farklı olsun, farklı bir görev ya da aksiyona odaklansın.
- Sadece düz metin yaz (JSON yok).
- Türkçe.

Görevler:
$taskList

Öneriler:
''';
  }

  /// Returns list of (title, description, category) as tuples.
  List<(String, String, String)> _parseRecommendationsFromPlainText(
    String text,
    AppLanguage language,
    List<Task> tasks,
  ) {
    final lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    String stripPrefix(String value) {
      return value.replaceFirst(RegExp(r'^[•\-\d\.\)\s]+'), '').trim();
    }

    final categories = _allowedCategories(language);
    final workCategory = categories[0];
    final personalCategory = categories[1];
    final shoppingCategory = categories[2];
    final healthCategory = categories[3];
    final otherCategory = categories[4];
    final fallbackTitle =
        language == AppLanguage.english ? 'Recommendation' : 'Öneri';

    String normalizeKey(String value) {
      return value
          .toLowerCase()
          .replaceAll('\u0307', '')
          .replaceAll('ı', 'i')
          .replaceAll('İ', 'i')
          .replaceAll('ş', 's')
          .replaceAll('ğ', 'g')
          .replaceAll('ü', 'u')
          .replaceAll('ö', 'o')
          .replaceAll('ç', 'c')
          .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }

    bool containsWord(String text, String word) {
      return RegExp(r'\b' + RegExp.escape(word) + r'\b').hasMatch(text);
    }

    String stripCategoryFromDescription(String value) {
      var v = value.trim();
      v = v.replaceAll(
        RegExp(r'\s*\((category|kategori)\s*:\s*[^)]+\)\.?', caseSensitive: false),
        '',
      );
      v = v.replaceAll(
        RegExp(r'\s*-\s*(category|kategori)\s*:\s*.*$', caseSensitive: false),
        '',
      );
      v = v.replaceAll(
        RegExp(r'\s*(category|kategori)\s*:\s*.*$', caseSensitive: false),
        '',
      );
      return v.trim();
    }

    String stripLabelPrefix(String value, {required String labelPattern}) {
      return value
          .trim()
          .replaceFirst(RegExp(labelPattern, caseSensitive: false), '')
          .trim();
    }

    String stripTitleLabel(String value) {
      return stripLabelPrefix(value, labelPattern: r'^(title|başlık|baslik)\s*:\s*');
    }

    String stripDescriptionLabel(String value) {
      return stripLabelPrefix(value, labelPattern: r'^(description|açıklama|aciklama)\s*:\s*');
    }

    String stripCategoryLabel(String value) {
      return stripLabelPrefix(value, labelPattern: r'^(category|kategori)\s*:\s*');
    }

    bool isTemplateLine(String value) {
      final normalized = normalizeKey(value);
      if (language == AppLanguage.english) {
        return normalized == 'title description category' ||
            normalized == 'title description';
      }
      return normalized == 'baslik aciklama kategori' ||
          normalized == 'baslik aciklama';
    }

    bool isPlaceholderEntry(String title, String desc) {
      final t = normalizeKey(title);
      final d = normalizeKey(desc);
      if (language == AppLanguage.english) {
        return (t == 'title' && d == 'description') ||
            (t == 'title' && d.isEmpty) ||
            (t.isEmpty && d == 'description');
      }
      return (t == 'baslik' && d == 'aciklama') ||
          (t == 'baslik' && d.isEmpty) ||
          (t.isEmpty && d == 'aciklama');
    }

    bool looksNonEnglishForEnglish(String value) {
      if (language != AppLanguage.english) return false;
      final raw = value.trim();
      if (raw.isEmpty) return false;
      if (RegExp(r'[^\x00-\x7F]').hasMatch(raw)) return true;
      final normalized = normalizeKey(raw);
      return RegExp(
        r'\b(gorev|toplanti|yarin|bugun|icin|hazirlik|okul|liste|kontrol|eksik|basla|baslangic|odeme|fatura|alisveris|saglik|egzersiz|yuruyus|duzenle|planla)\b',
      ).hasMatch(normalized);
    }

    String normalizeTitle(String value) {
      var v = stripTitleLabel(value).trim();
      v = v.replaceAll('"', '').replaceAll("'", '');
      v = v.replaceAll(RegExp(r'[.!?]+$'), '');
      if (v.isEmpty) return fallbackTitle;
      return v;
    }

    String makeTitle(String s) {
      final words = s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      final take = words.take(words.length >= 5 ? 5 : words.length).join(' ');
      return take.isEmpty ? fallbackTitle : take;
    }

    String guessCategory(String s) {
      final v = normalizeKey(s);
      if (language == AppLanguage.english) {
        if (RegExp(r'\b(health|doctor|dentist|appointment|medicine|medication|gym|workout|exercise|run|walk|yoga|sleep|wellness)\b')
            .hasMatch(v)) {
          return healthCategory;
        }
        if (RegExp(r'\b(shop|shopping|grocery|groceries|market|store|buy|purchase|order)\b')
            .hasMatch(v)) {
          return shoppingCategory;
        }
        if (RegExp(r'\b(work|meeting|deadline|project|report|client|email|call|presentation|review|proposal|agenda)\b')
            .hasMatch(v)) {
          return workCategory;
        }
        if (RegExp(r'\b(personal|family|home|house|birthday|vacation|travel|trip|hobby|study|course|learn)\b')
            .hasMatch(v)) {
          return personalCategory;
        }
        return otherCategory;
      }
      if (RegExp(r'\b(saglik|doktor|disci|randevu|ilac|spor|egzersiz|kosu|yuruyus|uyku|beslenme|diyet)\b')
          .hasMatch(v)) {
        return healthCategory;
      }
      if (RegExp(r'\b(alisveris|market|magaza|siparis|satin)\b')
          .hasMatch(v)) {
        return shoppingCategory;
      }
      if (RegExp(r'\b(toplanti|is|proje|teslim|rapor|musteri|eposta|mail|sunum|gorusme|ajanda|takvim)\b')
          .hasMatch(v)) {
        return workCategory;
      }
      if (RegExp(r'\b(kisisel|aile|ev|dogumgunu|tatil|seyahat|gezi|hobi|ders|kurs|ogren)\b')
          .hasMatch(v)) {
        return personalCategory;
      }
      return otherCategory;
    }

    String normalizeCategory(String raw, String title, String desc) {
      final cleanedRaw = stripCategoryLabel(raw);
      final combined = '$cleanedRaw $title $desc';
      final rawKey = normalizeKey(cleanedRaw);
      if (rawKey.isNotEmpty) {
        for (final allowed in categories) {
          final allowedKey = normalizeKey(allowed);
          if (rawKey == allowedKey || containsWord(rawKey, allowedKey)) {
            if (allowed == otherCategory) {
              return guessCategory(combined);
            }
            return allowed;
          }
        }
      }
      return guessCategory(combined);
    }

    // First, try parsing labeled format (Başlık:/Title: on separate lines)
    final labeledResult = <(String, String, String)>[];
    final _seenLabeled = <String>{};
    String? currentTitle;
    String? currentDesc;
    String? currentCat;
    
    for (final line in lines) {
      final trimmed = line.trim();
      
      // Check for title line
      if (RegExp(r'^[•\-\d\.\)\s]*(Başlık|Title|baslik):\s*(.+)', caseSensitive: false).hasMatch(trimmed)) {
        // Save previous recommendation if complete
        if (currentTitle != null && currentDesc != null && currentCat != null) {
          final key = normalizeKey(currentTitle);
          if (!_seenLabeled.contains(key)) {
            labeledResult.add((currentTitle, _ensurePeriod(currentDesc), currentCat));
            _seenLabeled.add(key);
          }
        }
        // Extract new title
        final match = RegExp(r'^[•\-\d\.\)\s]*(Başlık|Title|baslik):\s*(.+)', caseSensitive: false).firstMatch(trimmed);
        currentTitle = match?.group(2)?.trim();
        currentDesc = null;
        currentCat = null;
      }
      // Check for description line
      else if (RegExp(r'^\s*(Açıklama|Description|aciklama):\s*(.+)', caseSensitive: false).hasMatch(trimmed)) {
        final match = RegExp(r'^\s*(Açıklama|Description|aciklama):\s*(.+)', caseSensitive: false).firstMatch(trimmed);
        currentDesc = match?.group(2)?.trim();
      }
      // Check for category line
      else if (RegExp(r'^\s*(Kategori|Category):\s*(.+)', caseSensitive: false).hasMatch(trimmed)) {
        final match = RegExp(r'^\s*(Kategori|Category):\s*(.+)', caseSensitive: false).firstMatch(trimmed);
        currentCat = match?.group(2)?.trim();
        // Normalize category
        if (currentCat != null) {
          currentCat = normalizeCategory(currentCat, currentTitle ?? '', currentDesc ?? '');
        }
      }
    }
    
    // Save last recommendation
    if (currentTitle != null && currentDesc != null && currentCat != null && labeledResult.length < 3) {
      final key = normalizeKey(currentTitle);
      if (!_seenLabeled.contains(key)) {
        labeledResult.add((currentTitle, _ensurePeriod(currentDesc), currentCat));
      }
    }
    
    // If we parsed labeled format successfully, return it
    if (labeledResult.isNotEmpty) {
      return labeledResult;
    }

    // Fallback: try pipe-delimited format
    final result = <(String, String, String)>[];
    final _seenTitles = <String>{};
    final _seenDescriptions = <String>{};
    final _seenPairs = <String>{};
    for (final line in lines) {
      if (result.length >= 3) break;
      final cleaned = stripPrefix(line);
      if (cleaned.isEmpty) continue;
      if (isTemplateLine(cleaned)) continue;
      if (!cleaned.contains('|')) {
        final normalized = normalizeKey(cleaned);
        if (normalized.startsWith('title ') ||
            normalized.startsWith('description ') ||
            normalized.startsWith('category ') ||
            normalized.startsWith('baslik ') ||
            normalized.startsWith('aciklama ') ||
            normalized.startsWith('kategori ')) {
          continue;
        }
      }

      final parts = cleaned
          .split('|')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      String title;
      String desc;
      String cat;

      if (parts.length >= 3) {
        title = normalizeTitle(parts[0]);
        desc = _ensurePeriod(
          stripCategoryFromDescription(stripDescriptionLabel(parts[1])),
        );
        cat = normalizeCategory(stripCategoryLabel(parts[2]), title, desc);
      } else if (parts.length == 2) {
        title = normalizeTitle(parts[0]);
        desc = _ensurePeriod(
          stripCategoryFromDescription(stripDescriptionLabel(parts[1])),
        );
        cat = normalizeCategory('', title, desc);
      } else {
        final dashParts = cleaned.split(RegExp(r'\s[-–—]\s'));
        if (dashParts.length >= 2) {
          title = normalizeTitle(dashParts.first);
          desc = _ensurePeriod(
            stripCategoryFromDescription(
              stripDescriptionLabel(dashParts.sublist(1).join(' - ').trim()),
            ),
          );
          cat = normalizeCategory('', title, desc);
        } else {
          title = normalizeTitle(makeTitle(cleaned));
          desc = _ensurePeriod(
            stripCategoryFromDescription(stripDescriptionLabel(cleaned)),
          );
          cat = normalizeCategory('', title, desc);
        }
      }

      if (isPlaceholderEntry(title, desc)) {
        continue;
      }

      if (looksNonEnglishForEnglish(title) || looksNonEnglishForEnglish(desc)) {
        continue;
      }

      if (cat.isEmpty) {
        cat = normalizeCategory('', title, desc);
      }

      final titleKey = normalizeKey(title);
      final descKey = normalizeKey(desc);
      final pairKey = '$titleKey|$descKey';
      if (titleKey.isNotEmpty && _seenTitles.contains(titleKey)) {
        continue;
      }
      if (descKey.isNotEmpty && _seenDescriptions.contains(descKey)) {
        continue;
      }
      if (_seenPairs.contains(pairKey)) {
        continue;
      }

      result.add((title, desc, cat));
      _seenTitles.add(titleKey);
      _seenDescriptions.add(descKey);
      _seenPairs.add(pairKey);
    }

    if (result.length < 3) {
      final pending = tasks.where((t) => !t.isCompleted).toList();
      final pool = pending.isNotEmpty ? pending : tasks;
      final usedTitles = result.map((r) => normalizeKey(r.$1)).toSet();
      final usedDescriptions = result.map((r) => normalizeKey(r.$2)).toSet();
      final verbs = language == AppLanguage.english
          ? ['Finish', 'Review', 'Prepare', 'Plan', 'Schedule', 'Organize']
          : ['Tamamla', 'Gözden geçir', 'Hazırla', 'Planla', 'Programla', 'Düzenle'];

      String fallbackTitleFromTask(Task task, int index) {
        final verb = verbs[index % verbs.length];
        final rawTitle = task.title.trim();
        if (language == AppLanguage.english && looksNonEnglishForEnglish(rawTitle)) {
          return 'Finish a key task';
        }
        final words =
            rawTitle.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
        final take = words.take(4).join(' ');
        if (take.isEmpty) {
          return language == AppLanguage.english
              ? 'Finish a key task'
              : 'Önemli bir görevi tamamla';
        }
        return '$verb $take';
      }

      String fallbackDescriptionFromTask(Task task) {
        final t = task.title.trim();
        final desc = task.description.trim();
        if (desc.isNotEmpty && !looksNonEnglishForEnglish(desc)) {
          return desc;
        }
        if (t.isEmpty || looksNonEnglishForEnglish(t)) {
          return language == AppLanguage.english
              ? 'Complete one important task today.'
              : 'Bugün önemli bir görevi tamamla.';
        }
        return language == AppLanguage.english
            ? 'Complete the next step for $t.'
            : '$t için bir sonraki adımı tamamla.';
      }

      var fallbackIndex = 0;
      for (final task in pool) {
        if (result.length >= 3) break;
        final title = fallbackTitleFromTask(task, fallbackIndex);
        final titleKey = normalizeKey(title);
        if (usedTitles.contains(titleKey)) continue;
        final desc = fallbackDescriptionFromTask(task);
        final descKey = normalizeKey(desc);
        if (usedDescriptions.contains(descKey)) continue;
        final cat = normalizeCategory(task.category ?? '', title, desc);
        result.add((title, _ensurePeriod(desc), cat));
        usedTitles.add(titleKey);
        usedDescriptions.add(descKey);
        fallbackIndex += 1;
      }
    }

    if (result.isEmpty) {
      if (language == AppLanguage.english) {
        result.add(('Choose a small step', 'Pick one task you can finish today.', otherCategory));
      } else {
        result.add(('Küçük bir adım seç', 'Bugün tamamlayabileceğin tek bir adımı belirle.', otherCategory));
      }
    }

    return result;
  }

  // -----------------------------
  // 2) Task description suggestion (NO JSON)
  // -----------------------------
  @override
  Future<String?> generateTaskDescriptionSuggestion({
    String? title,
    String? category,
  }) async {
    final t = title?.trim() ?? '';
    final c = category?.trim() ?? '';
    if (t.isEmpty && c.isEmpty) return null;

    final uri = Uri.parse('$baseUrl/api/generate');
    final language = _currentLanguage();
    final prompt = _buildDescriptionPrompt(title: t, category: c, language: language);

    final payload = <String, dynamic>{
      'model': model,
      'prompt': prompt,
      'stream': false,
      'options': {
        'temperature': 0.25,
        'top_p': 0.9,
        'num_predict': 120,
      },
      'raw': true,
    };

    try {
      final response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception('Ollama error: ${response.statusCode} ${response.body}');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final text = decoded['response']?.toString().trim();

      if (text == null || text.isEmpty) return null;
      return _firstLine(text, maxLines: 2);
    } catch (e) {
      // Fallback if AI service is offline
      print('AI Service Error (Suggestion): $e');
      if (language == AppLanguage.english) {
        if (t.isNotEmpty) return 'Clarify the details for $t.';
        return 'Summarize the task in one sentence.';
      }
      if (t.isNotEmpty) return '$t için detayları belirle ve uygula.';
      return 'Görevi tek cümleyle özetle.';
    }
  }

  String _buildDescriptionPrompt({
    required String title,
    required String category,
    required AppLanguage language,
  }) {
    if (language == AppLanguage.english) {
      return '''
${_systemPrompt(language)}

TASK: Write one clear sentence for the title and category below.

INPUT:
Title: "$title"
Category: "$category"

OUTPUT (Single sentence, ends with a period):
''';
    }
    return '''
${_systemPrompt(language)}

GÖREV: Aşağıdaki başlık ve kategori için tek bir cümlelik net bir açıklama yaz.

GİRDİ:
Başlık: "$title"
Kategori: "$category"

ÇIKTI (Sadece tek cümle, nokta ile biten tam bir cümle):
''';
  }

  // -----------------------------
  // 3) Typing completion (legacy name, NO JSON)
  // -----------------------------
  @override
  Future<String?> generateAssistantCompletion({
    required String input,
    List<Task>? context,
  }) async {
    final safeInput = input.trim();
    if (safeInput.isEmpty) return null;

    final uri = Uri.parse('$baseUrl/api/generate');
    final language = _currentLanguage();
    final prompt = _buildCompletionPromptPlainText(
      input: safeInput,
      context: context,
      language: language,
    );

    final payload = <String, dynamic>{
      'model': model,
      'prompt': prompt,
      'stream': false,
      'options': {
        'temperature': 0.2,
        'top_p': 0.9,
        'num_predict': 80,
      },
      'raw': true,
    };

    final response = await _client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw Exception('Ollama error: ${response.statusCode} ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final text = decoded['response']?.toString().trim();
    if (text == null || text.isEmpty) return null;

    // Keep it short and clean.
    final completion = _firstLine(text, maxLines: 1);
    return _stripRepeatedPrefix(completion, safeInput);
  }

String _buildCompletionPromptPlainText({
  required String input,
  List<Task>? context,
  required AppLanguage language,
}) {
  final safe = input.trim();
  final tasks = (context ?? []).take(4).map((t) => '- ${t.title}').join('\n');

  if (language == AppLanguage.english) {
    return '''
${_systemPrompt(language)}

TASK: Complete the user's sentence.
IMPORTANT: Do NOT repeat the user's input. Only write the continuation.
Do NOT use quotation marks.
The continuation must be one complete sentence and end with a period.

Examples:
Input: "From the store"
Output: "buy milk and bread."
(WRONG: "From the store buy milk and bread.")

Input: "Tomorrow at 3"
Output: "attend the meeting."

Input: "My homework"
Output: "review and finish it."

User text: "$safe"
${tasks.isNotEmpty ? "Context (Existing Tasks):\n$tasks\n" : ""}

OUTPUT (Only the continuation):
''';
  }

  return '''
${_systemPrompt(language)}

GÖREV: Kullanıcının cümlesini tamamla.
ÇOK ÖNEMLİ: Kullanıcının yazdığı kısmı TEKRAR ETME. Sadece devamını yaz.
Tırnak işareti kullanma.
Devamı tek, tamamlanmış bir cümle olsun ve nokta ile bitsin.

Örnekler:
Girdi: "Marketten"
Çıktı: "süt ve ekmek al."
(YANLIŞ ÇIKTI: "Marketten süt ve ekmek al.")

Girdi: "Yarın saat 3'te"
Çıktı: "toplantıya katıl."

Girdi: "Ödevlerimi"
Çıktı: "kontrol et ve tamamla."

Kullanıcı metni: "$safe"
${tasks.isNotEmpty ? "Bağlam (Mevcut Görevler):\n$tasks\n" : ""}

ÇIKTI (Sadece devamı):
''';
}

  // -----------------------------
  // Utils
  // -----------------------------
  String _firstLine(String text, {int maxLines = 1}) {
    final lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (lines.isEmpty) return text.trim();
    final take = lines.take(maxLines).join(' ');
    return _ensurePeriod(take);
  }

  String _ensurePeriod(String s) {
    var t = s.trim();
    if (t.isEmpty) return t;
    if (!t.endsWith('.') && !t.endsWith('!') && !t.endsWith('?')) {
      t = '$t.';
    }
    return t;
  }

  String? _stripRepeatedPrefix(String completion, String input) {
    String stripQuotes(String value) {
      return value
          .replaceAll(RegExp("^[\"']+"), '')
          .replaceAll(RegExp("[\"']+\$"), '')
          .trim();
    }

    String stripInputPrefixRegex(String value, String rawInput) {
      final wordMatches = RegExp(r"\p{L}[\p{L}\p{M}\p{N}'-]*", unicode: true)
          .allMatches(rawInput);
      final words = wordMatches.map((m) => m.group(0)!).toList();
      if (words.isEmpty) return value;
      final pattern = words.map(RegExp.escape).join(r'\W+');
      final re = RegExp(
        "^[\"'\\s]*" + pattern + "(?:\\W+|\$)",
        caseSensitive: false,
        unicode: true,
      );
      return value.replaceFirst(re, '');
    }

    var result = stripQuotes(completion.trim());
    if (result.isEmpty) return null;

    final inputTrimmed = input.trim();
    if (inputTrimmed.isEmpty) return result;

    String normalize(String s) {
      return s
          .toLowerCase()
          .replaceAll(RegExp(r'[\s\p{P}]+', unicode: true), ' ')
          .trim();
    }

    result = stripInputPrefixRegex(result, inputTrimmed).trimLeft();
    result = stripQuotes(result);

    final normalizedInput = normalize(inputTrimmed);
    final normalizedCompletion = normalize(result);

    if (normalizedCompletion.startsWith(normalizedInput)) {
      // Remove the input prefix even if punctuation or quotes are present.
      result = stripInputPrefixRegex(result, inputTrimmed).trimLeft();
    }

    result = stripQuotes(result);
    result = result.replaceFirst(RegExp(r'^[\s,;:\-–—]+'), '').trimLeft();

    if (result.isEmpty) return null;
    return result;
  }

  IconData _iconForCategory(String category) {
    final value = category.toLowerCase();
    if (value.contains('sağlık') || value.contains('health')) return Icons.favorite;
    if (value.contains('alışveriş') || value.contains('shopping')) return Icons.shopping_cart;
    if (value.contains('iş') || value.contains('work')) return Icons.work;
    if (value.contains('kişisel') || value.contains('personal')) return Icons.person;
    if (value.contains('plan')) return Icons.event;
    if (value.contains('finans') || value.contains('finance')) return Icons.payments;
    if (value.contains('düzen') || value.contains('home')) return Icons.checklist;
    return Icons.lightbulb;
  }
}

/// In-memory mock implementation (kept backward-compatible).
class InMemoryAIService implements AIService {
  final LocalizationService? localizationService;

  InMemoryAIService({this.localizationService});

  AppLanguage _currentLanguage() {
    return localizationService?.currentLanguage ?? AppLanguage.turkish;
  }

  List<String> _allowedCategories(AppLanguage language) {
    final loc = localizationService;
    if (loc != null) {
      return [
        loc.categoryWork,
        loc.categoryPersonal,
        loc.categoryShopping,
        loc.categoryHealth,
        loc.categoryOther,
      ];
    }
    if (language == AppLanguage.english) {
      return ['Work', 'Personal', 'Shopping', 'Health', 'Other'];
    }
    return ['İş', 'Kişisel', 'Alışveriş', 'Sağlık', 'Diğer'];
  }

  @override
  Future<List<AIRecommendation>> fetchRecommendations(List<Task> context) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final now = DateTime.now();
    final language = _currentLanguage();
    final categories = _allowedCategories(language);
    if (language == AppLanguage.english) {
      return [
        AIRecommendation(
          id: 'ai-${now.millisecondsSinceEpoch}-0',
          title: 'Clarify the day',
          description: 'Choose the most important task for today.',
          category: categories.last,
          icon: Icons.event,
          createdAt: now,
        ),
        AIRecommendation(
          id: 'ai-${now.millisecondsSinceEpoch}-1',
          title: 'Define a small step',
          description: 'Write the first 10-minute action for each task.',
          category: categories.last,
          icon: Icons.lightbulb,
          createdAt: now,
        ),
      ];
    }
    return [
      AIRecommendation(
        id: 'ai-${now.millisecondsSinceEpoch}-0',
        title: 'Günü netleştir',
        description: 'Bugün tamamlayacağın en önemli 1 görevi seç.',
        category: categories.last,
        icon: Icons.event,
        createdAt: now,
      ),
      AIRecommendation(
        id: 'ai-${now.millisecondsSinceEpoch}-1',
        title: 'Küçük adım belirle',
        description: 'Her görev için ilk 10 dakikalık adımı yaz.',
        category: categories.last,
        icon: Icons.lightbulb,
        createdAt: now,
      ),
    ];
  }

  @override
  Future<String?> generateTaskDescriptionSuggestion({
    String? title,
    String? category,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final t = (title ?? '').trim();
    final c = (category ?? '').trim();
    if (_currentLanguage() == AppLanguage.english) {
      if (t.isNotEmpty) return 'Define the first step for $t.';
      if (c.isNotEmpty) return 'Write the next step for $c.';
      return 'Clarify the task with a single step.';
    }
    if (t.isNotEmpty) return '$t için ilk adımı belirle.';
    if (c.isNotEmpty) return '$c ile ilgili bir sonraki adımı yaz.';
    return 'Görevi tek bir adımla netleştir.';
  }

  @override
  Future<String?> generateAssistantCompletion({
    required String input,
    List<Task>? context,
  }) async {
    await Future.delayed(const Duration(milliseconds: 120));
    if (input.trim().isEmpty) return null;
    if (_currentLanguage() == AppLanguage.english) {
      return 'define the first step and add a time.';
    }
    return 'ilk adımı belirle ve saat ekle.';
  }
}
