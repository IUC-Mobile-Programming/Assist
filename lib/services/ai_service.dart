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
Sen Assist uygulamasında çalışan bir kişisel sekretersin.
Amacın: kullanıcı görev yazarken onu netleştirmek ve uygulanabilir bir sonraki adım önermek.

Kurallar:
- Sadece düz metin yaz. JSON yazma.
- Kod yazma, teknik açıklama yapma.
- Soru sorma (belirsizse en iyi varsayımla ilerle).
- Kısa, net ve eylem odaklı ol.
- Gereksiz uzun yazma.
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
        'num_predict': 220,
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
  }

  String _buildRecommendationsPrompt(List<Task> tasks) {
    final taskList = tasks.take(10).map((t) {
      final due = t.date.toIso8601String().split('T').first;
      return '- ${t.title} (tarih: $due${t.isImportant ? ", önemli" : ""}${t.isCompleted ? ", tamamlandı" : ""})';
    }).join('\n');

    return '''
$systemPrompt

Kullanıcının görevlerine göre 3 kısa, uygulanabilir öneri üret.
Kurallar:
- Sadece düz metin yaz (JSON yok).
- 3 madde olacak.
- Her madde "•" ile başlayacak.
- Her madde en fazla 1 cümle.
- Türkçe.

Görevler:
$taskList

Öneriler:
''';
  }

  /// Returns list of (title, description, category) as tuples.
  List<(String, String, String)> _parseRecommendationsFromPlainText(String text) {
    // Expect bullets. If not, fallback to sentence splitting.
    final lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    List<String> bullets = lines.where((l) => l.startsWith('•')).toList();
    if (bullets.isEmpty) {
      // fallback: take up to 3 "sentences"
      bullets = text
          .split(RegExp(r'[.!?]\s+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .take(3)
          .toList();
    } else {
      bullets = bullets.take(3).toList();
      bullets = bullets.map((b) => b.replaceFirst('•', '').trim()).toList();
    }

    // Simple mapping: create a short title from first 3-5 words.
    String makeTitle(String s) {
      final words = s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      final take = words.take(words.length >= 5 ? 5 : words.length).join(' ');
      return take.isEmpty ? 'Öneri' : take;
    }

    // Category heuristic (optional)
    String guessCategory(String s) {
      final v = s.toLowerCase();
      if (v.contains('plan') || v.contains('takvim') || v.contains('saat')) return 'Plan';
      if (v.contains('sağlık') || v.contains('yürüyüş') || v.contains('spor')) return 'Sağlık';
      if (v.contains('finans') || v.contains('ödeme') || v.contains('fatura')) return 'Finans';
      if (v.contains('alışveriş') || v.contains('market')) return 'Alışveriş';
      if (v.contains('temiz') || v.contains('düzen')) return 'Düzen';
      return 'Genel';
    }

    final result = <(String, String, String)>[];
    for (final b in bullets) {
      final title = makeTitle(b);
      final desc = _ensurePeriod(b);
      final cat = guessCategory(b);
      result.add((title, desc, cat));
    }

    // If still empty, add one fallback
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
    return _firstLine(text, maxLines: 2);
  }

  String _buildDescriptionPrompt({required String title, required String category}) {
    return '''
$systemPrompt

Kullanıcı görev ekliyor. Görev için tek cümlelik açıklama öner.
Kurallar:
- Sadece düz metin yaz (JSON yok).
- En fazla 12 kelime.
- Nokta ile bitir.

Görev başlığı: "$title"
Kategori: "$category"

Açıklama:
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
        'num_predict': 35,
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
    return _firstLine(text, maxLines: 1);
  }

String _buildCompletionPromptPlainText({
  required String input,
  List<Task>? context,
}) {
  final safe = input.trim();
  final tasks = (context ?? []).take(4).map((t) => '- ${t.title}').join('\n');

  return '''
Sen Assist uygulamasında çalışan bir kişisel sekretersin.
Kullanıcının yazdığı görevi çok kısa şekilde tamamla.

ÇIKTI:
- Sadece tek satır yaz.
- 3-8 kelime arası.
- Türkçe.
- Kullanıcının yazdığı metni kopyalama.
- kullanıcının girdiğini tamamla.
- Kural/uyarı/etiket yazma.
- Tırnak kullanma.
- Nokta ile bitir.

Örnek:
Girdi: market
Çıktı: listesini çıkar ve eksikleri kontrol et.

Girdi: toplantı hazırlığı
Çıktı: yapılacak ve notlar toparlanacak.

Kullanıcı metni: $safe
${tasks.isNotEmpty ? "Bağlam görevler:\n$tasks\n" : ""}
Çıktı:
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
