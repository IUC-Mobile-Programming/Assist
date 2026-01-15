import 'package:flutter/material.dart';
import 'package:Assist/presentation/viewmodels/calendar_viewmodel.dart';
import 'package:Assist/services/localization_service.dart';
import 'package:provider/provider.dart';

class CalendarHeader extends StatelessWidget {
  final CalendarViewModel viewModel;

  const CalendarHeader({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final borderColor = theme.dividerColor.withAlpha((0.25 * 255).round());
    final shadowColor = Color.fromRGBO(0, 0, 0, isDarkMode ? 0.3 : 0.08);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildViewModeButton(
            mode: CalendarViewMode.month,
            label: localizationService.month,
            icon: Icons.calendar_month,
            theme: theme,
          ),
          const SizedBox(width: 6),
          _buildViewModeButton(
            mode: CalendarViewMode.week,
            label: localizationService.week,
            icon: Icons.view_week,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeButton({
    required CalendarViewMode mode,
    required String label,
    required IconData icon,
    required ThemeData theme,
  }) {
    final isSelected = viewModel.viewMode == mode;
    final primary = theme.primaryColor;
    final highlight = Color.lerp(primary, Colors.white, 0.2) ?? primary;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => viewModel.setViewMode(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(colors: [highlight, primary])
                  : null,
              border: Border.all(
                color: isSelected
                    ? primary.withAlpha((0.4 * 255).round())
                    : theme.dividerColor.withAlpha((0.2 * 255).round()),
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primary.withAlpha((0.25 * 255).round()),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? Colors.white
                      : theme.iconTheme.color,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? Colors.white
                        : theme.textTheme.bodyMedium?.color,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
