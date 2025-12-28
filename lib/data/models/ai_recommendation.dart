import 'package:flutter/material.dart';

class AIRecommendation {
  final String id;
  final String title;
  final String description;
  final String category;
  final IconData icon;
  final DateTime createdAt;
  final bool isApplied;
  final String? actionUrl;

  const AIRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.createdAt,
    this.isApplied = false,
    this.actionUrl,
  });

  AIRecommendation copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    IconData? icon,
    DateTime? createdAt,
    bool? isApplied,
    String? actionUrl,
  }) {
    return AIRecommendation(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      isApplied: isApplied ?? this.isApplied,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'icon': icon.codePoint,
      'createdAt': createdAt.toIso8601String(),
      'isApplied': isApplied,
      'actionUrl': actionUrl,
    };
  }

  factory AIRecommendation.fromMap(Map<String, dynamic> map) {
    return AIRecommendation(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      category: map['category'],
      icon: IconData(map['icon'], fontFamily: 'MaterialIcons'),
      createdAt: DateTime.parse(map['createdAt']),
      isApplied: map['isApplied'],
      actionUrl: map['actionUrl'],
    );
  }
}