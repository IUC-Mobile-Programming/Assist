import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:Assist/data/models/task.dart';
import 'package:Assist/data/models/ai_recommendation.dart';
import 'package:http/http.dart' as http;

/// Abstraction for AI-related operations (recommendations, analysis).
abstract class AIService {
  Future<List<AIRecommendation>> fetchRecommendations(List<Task> context);
}

class OllamaAIService implements AIService {
  final String baseUrl;
  final String model;
  final Duration timeout;
  final http.Client _client;

  OllamaAIService({
    this.baseUrl = 'http://localhost:11434',
    this.model = 'qwen2.5:7b',
    Duration? timeout,
    http.Client? client,
  }) : timeout = timeout ?? const Duration(seconds: 20),
       _client = client ?? http.Client();

  @override
  Future<List<AIRecommendation>> fetchRecommendations(List<Task> context) async {
    final uri = Uri.parse('$baseUrl/api/generate');
    final payload = <String, dynamic>{
      'model': model,
      'prompt': _buildPrompt(context),
      'stream': false,
      'format': 'json',
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
    final raw = decoded['response'];

    dynamic parsed;
    if (raw is String) {
      parsed = jsonDecode(raw);
    } else {
      parsed = raw;
    }

    final items = _extractItems(parsed);
    final now = DateTime.now();

    return [
      for (var i = 0; i < items.length; i++)
        _toRecommendation(items[i], now, i),
    ];
  }

  String _buildPrompt(List<Task> tasks) {
    final taskList = tasks
        .take(10)
        .map((task) => {
              'title': task.title,
              'dueDate': task.date.toIso8601String(),
              'description': task.description,
              'category': task.category,
              'important': task.isImportant,
              'completed': task.isCompleted,
            })
        .toList();

    return '''
Sen bir kişisel asistan uygulamasısın. Kullanıcının görevlerine göre 3 kısa, uygulanabilir öneri üret.
Çıktıyı SADECE JSON olarak ver, ek açıklama ekleme.

Çıktı şeması:
{"recommendations":[{"title":"...","description":"...","category":"..."}]}

Görevler (JSON):
${jsonEncode(taskList)}
''';
  }

  List<Map<String, dynamic>> _extractItems(dynamic parsed) {
    if (parsed is Map<String, dynamic> && parsed['recommendations'] is List) {
      return List<Map<String, dynamic>>.from(
        parsed['recommendations'] as List,
      );
    }
    if (parsed is List) {
      return List<Map<String, dynamic>>.from(parsed);
    }
    return [];
  }

  AIRecommendation _toRecommendation(
    Map<String, dynamic> item,
    DateTime createdAt,
    int index,
  ) {
    final title = (item['title'] ?? '').toString().trim();
    final description = (item['description'] ?? '').toString().trim();
    final category = (item['category'] ?? 'Genel').toString().trim();

    return AIRecommendation(
      id: 'ai-${createdAt.millisecondsSinceEpoch}-$index',
      title: title.isEmpty ? 'Öneri' : title,
      description: description.isEmpty ? 'Kısa bir iyileştirme önerisi' : description,
      category: category.isEmpty ? 'Genel' : category,
      icon: _iconForCategory(category),
      createdAt: createdAt,
      actionUrl: item['actionUrl']?.toString(),
    );
  }

  IconData _iconForCategory(String category) {
    final value = category.toLowerCase();
    if (value.contains('sağlık')) return Icons.favorite;
    if (value.contains('verim')) return Icons.bolt;
    if (value.contains('hazır')) return Icons.checklist;
    if (value.contains('plan')) return Icons.event;
    if (value.contains('finans')) return Icons.payments;
    if (value.contains('eğitim')) return Icons.school;
    return Icons.lightbulb;
  }
}

/// In-memory mock implementation returning sample recommendations.
class InMemoryAIService implements AIService {
  @override
  Future<List<AIRecommendation>> fetchRecommendations(List<Task> context) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      AIRecommendation(
        id: 'ai-1',
        title: 'Kısa bir yürüyüş ekle',
        description: '15 dakikalık yürüyüş odaklanmaya yardımcı olur',
        category: 'Sağlık',
        icon: Icons.directions_walk,
        createdAt: DateTime.now(),
      ),
    ];
  }
}
