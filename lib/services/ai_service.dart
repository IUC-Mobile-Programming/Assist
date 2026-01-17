import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:Assist/data/models/task.dart';
import 'package:Assist/data/models/ai_recommendation.dart';
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

  /// Prompt tuning center: adjust assistant behavior here.
  /// (No code writing, no JSON output.)
  final String systemPrompt;

  OllamaAIService({
    // Android emulator note: you may need http://10.0.2.2:11434
    this.baseUrl = 'http://localhost:11434',
    this.model = 'neural-chat:latest',
    Duration? timeout,
    http.Client? client,
    String? systemPrompt,
  })  : timeout = timeout ?? const Duration(seconds: 25),
        _client = client ?? http.Client(),
        systemPrompt = systemPrompt ??
    '''
Sen Assist uygulamasında çalışan bir yapay zeka asistanısın.
Görevin: Kullanıcı için kısa, doğrudan ve sonuca odaklı metinler üretmek.

Kesin Kurallar:
1. Sadece istenen çıktıyı ver.
2. "Bunu yapıyorum", "İşte önerim", "Kullanıcı görev ekliyor" gibi giriş/meta cümleleri ASLA yazma.
3. Tırnak işareti kullanma.
4. Sadece Türkçe yanıt ver.
''';

  // -----------------------------
  // 1) Recommendations (NO JSON)
  // -----------------------------
  @override
  Future<List<AIRecommendation>> fetchRecommendations(List<Task> context) async {
    final uri = Uri.parse('$baseUrl/api/generate');

    final prompt = _buildRecommendationsPrompt(context);

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
      final recs = _parseRecommendationsFromPlainText(text);

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
       return [
        AIRecommendation(
          id: 'ai-mock-1',
          title: 'Günlük planını yap',
          description: 'Bugün için en önemli 3 görevi belirle.',
          category: 'Plan',
          icon: Icons.event,
          createdAt: now,
        ),
        AIRecommendation(
          id: 'ai-mock-2',
          title: 'Kısa mola ver',
          description: 'Verimliliğini artırmak için 5 dakika nefes egzersizi yap.',
          category: 'Sağlık',
          icon: Icons.favorite,
          createdAt: now,
        ),
       ];
    }
  }

  String _buildRecommendationsPrompt(List<Task> tasks) {
    final taskList = tasks.take(10).map((t) {
      final due = t.date.toIso8601String().split('T').first;
      final category = (t.category == null || t.category!.trim().isEmpty) ? 'Genel' : t.category!;
      final flags = [
        if (t.isImportant) 'önemli',
        if (t.isCompleted) 'tamamlandı',
      ].join(', ');
      final flagText = flags.isEmpty ? '' : ', $flags';
      return '- ${t.title} (tarih: $due, kategori: $category$flagText)';
    }).join('\n');

    return '''
$systemPrompt

Kullanıcının görevlerine göre 3 uygulanabilir öneri üret.
Format (KESİN):
• Başlık | Açıklama | Kategori

Kurallar:
- Başlık 3-6 kelime, eylem fiiliyle başlasın.
- Açıklama tek cümle olsun ve nokta ile bitsin.
- Kategori 1-2 kelime olsun (ör: Plan, Sağlık, Finans, Alışveriş, Düzen, Genel).
- Tamamlanmamış ve önemli görevlere öncelik ver.
- Sadece düz metin yaz (JSON yok).
- Türkçe.

Görevler:
$taskList

Öneriler:
''';
  }

  /// Returns list of (title, description, category) as tuples.
  List<(String, String, String)> _parseRecommendationsFromPlainText(String text) {
    final lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    String stripPrefix(String value) {
      return value.replaceFirst(RegExp(r'^[•\-\d\.\)\s]+'), '').trim();
    }

    String normalizeTitle(String value) {
      var v = value.trim();
      v = v.replaceAll('"', '').replaceAll("'", '');
      v = v.replaceAll(RegExp(r'[.!?]+$'), '');
      if (v.isEmpty) return 'Öneri';
      return v;
    }

    String guessCategory(String s) {
      final v = s.toLowerCase();
      if (v.contains('plan') || v.contains('takvim') || v.contains('saat')) return 'Plan';
      if (v.contains('sağlık') || v.contains('yürüyüş') || v.contains('spor')) return 'Sağlık';
      if (v.contains('finans') || v.contains('ödeme') || v.contains('fatura')) return 'Finans';
      if (v.contains('alışveriş') || v.contains('market')) return 'Alışveriş';
      if (v.contains('temiz') || v.contains('düzen')) return 'Düzen';
      return 'Genel';
    }

    String makeTitle(String s) {
      final words = s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      final take = words.take(words.length >= 5 ? 5 : words.length).join(' ');
      return take.isEmpty ? 'Öneri' : take;
    }

    final result = <(String, String, String)>[];
    for (final line in lines) {
      if (result.length >= 3) break;
      final cleaned = stripPrefix(line);
      if (cleaned.isEmpty) continue;

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
        desc = _ensurePeriod(parts[1]);
        cat = parts[2].trim();
      } else if (parts.length == 2) {
        title = normalizeTitle(parts[0]);
        desc = _ensurePeriod(parts[1]);
        cat = guessCategory(desc);
      } else {
        final dashParts = cleaned.split(RegExp(r'\s[-–—]\s'));
        if (dashParts.length >= 2) {
          title = normalizeTitle(dashParts.first);
          desc = _ensurePeriod(dashParts.sublist(1).join(' - ').trim());
          cat = guessCategory(desc);
        } else {
          title = normalizeTitle(makeTitle(cleaned));
          desc = _ensurePeriod(cleaned);
          cat = guessCategory(cleaned);
        }
      }

      if (cat.isEmpty) {
        cat = guessCategory(desc);
      }

      result.add((title, desc, cat));
    }

    if (result.isEmpty) {
      result.add(('Küçük bir adım seç', 'Bugün tamamlayabileceğin tek bir adımı belirle.', 'Genel'));
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
    final prompt = _buildDescriptionPrompt(title: t, category: c);

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
      if (t.isNotEmpty) return '$t için detayları belirle ve uygula.';
      return 'Görevi tek cümleyle özetle.';
    }
  }

  String _buildDescriptionPrompt({required String title, required String category}) {
    return '''
$systemPrompt

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
    final prompt = _buildCompletionPromptPlainText(input: safeInput, context: context);

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
}) {
  final safe = input.trim();
  final tasks = (context ?? []).take(4).map((t) => '- ${t.title}').join('\n');

  return '''
$systemPrompt

GÖREV: Kullanıcının cümlesini tamamla.
ÇOK ÖNEMLİ: Kullanıcının yazdığı kısmı TEKRAR ETME. Sadece devamını yaz.
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
    var result = completion.trim();
    if (result.isEmpty) return null;

    final inputTrimmed = input.trim();
    if (inputTrimmed.isEmpty) return result;

    String normalize(String s) {
      return s
          .toLowerCase()
          .replaceAll(RegExp(r'[\\s\\p{P}]+', unicode: true), ' ')
          .trim();
    }

    final normalizedInput = normalize(inputTrimmed);
    final normalizedCompletion = normalize(result);

    if (normalizedCompletion.startsWith(normalizedInput)) {
      // Remove the exact input prefix when possible.
      result = result.substring(inputTrimmed.length).trimLeft();
    } else {
      final index = normalizedCompletion.indexOf(normalizedInput);
      if (index == 0) {
        result = result.substring(inputTrimmed.length).trimLeft();
      } else if (index > 0) {
        // If input is repeated later, keep only the tail.
        final rawIndex = result.toLowerCase().indexOf(inputTrimmed.toLowerCase());
        if (rawIndex >= 0) {
          result = result.substring(rawIndex + inputTrimmed.length).trimLeft();
        }
      }
    }

    if (result.isEmpty) return null;
    return result;
  }

  IconData _iconForCategory(String category) {
    final value = category.toLowerCase();
    if (value.contains('sağlık')) return Icons.favorite;
    if (value.contains('plan')) return Icons.event;
    if (value.contains('finans')) return Icons.payments;
    if (value.contains('alışveriş')) return Icons.shopping_cart;
    if (value.contains('düzen')) return Icons.checklist;
    return Icons.lightbulb;
  }
}

/// In-memory mock implementation (kept backward-compatible).
class InMemoryAIService implements AIService {
  @override
  Future<List<AIRecommendation>> fetchRecommendations(List<Task> context) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final now = DateTime.now();
    return [
      AIRecommendation(
        id: 'ai-${now.millisecondsSinceEpoch}-0',
        title: 'Günü netleştir',
        description: 'Bugün tamamlayacağın en önemli 1 görevi seç.',
        category: 'Plan',
        icon: Icons.event,
        createdAt: now,
      ),
      AIRecommendation(
        id: 'ai-${now.millisecondsSinceEpoch}-1',
        title: 'Küçük adım belirle',
        description: 'Her görev için ilk 10 dakikalık adımı yaz.',
        category: 'Genel',
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
    return 'ilk adımı belirle ve saat ekle.';
  }
}
