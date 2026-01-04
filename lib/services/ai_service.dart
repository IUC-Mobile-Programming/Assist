import 'package:flutter/material.dart';
import 'package:Assist/data/models/task.dart';
import 'package:Assist/data/models/ai_recommendation.dart';

/// Abstraction for AI-related operations (recommendations, analysis).
abstract class AIService {
  Future<List<AIRecommendation>> fetchRecommendations(List<Task> context);
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
