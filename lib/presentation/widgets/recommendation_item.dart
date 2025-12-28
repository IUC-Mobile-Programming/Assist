import 'package:flutter/material.dart';
import 'package:assist_ai/data/models/ai_recommendation.dart';

class RecommendationItem extends StatelessWidget {
  final AIRecommendation recommendation;
  final VoidCallback onApply;

  const RecommendationItem({
    super.key,
    required this.recommendation,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? Colors.green[800]! : Colors.green.shade100,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.green[900]! : Colors.green.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              recommendation.icon,
              size: 20,
              color: isDarkMode ? Colors.green[300] : Colors.green.shade800,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Öneri: ${recommendation.category}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDarkMode ? Colors.green[300] : Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              recommendation.isApplied ? Icons.check_circle : Icons.add_circle_outline,
              color: isDarkMode ? Colors.green[300] : Colors.green,
            ),
            onPressed: recommendation.isApplied ? null : onApply,
          ),
        ],
      ),
    );
  }
}