import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Assist/presentation/viewmodels/calendar_viewmodel.dart';
import 'package:Assist/services/localization_service.dart';

class CalendarNavigation extends StatelessWidget {
  final CalendarViewModel viewModel;

  const CalendarNavigation({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final borderColor = theme.dividerColor.withAlpha((0.25 * 255).round());
    final shadowColor = Color.fromRGBO(0, 0, 0, isDarkMode ? 0.3 : 0.08);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavButton(
            icon: Icons.chevron_left,
            onTap: viewModel.navigateToPrevious,
            theme: theme,
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    viewModel.viewMode == CalendarViewMode.month
                        ? '${localizationService.getMonthName(viewModel.currentDate.month)} ${viewModel.currentDate.year}'
                        : viewModel.getWeekRange(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTodayButton(
                  label: localizationService.today,
                  onTap: viewModel.navigateToToday,
                  theme: theme,
                ),
              ],
            ),
          ),
          _buildNavButton(
            icon: Icons.chevron_right,
            onTap: viewModel.navigateToNext,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    final backgroundColor = theme.primaryColor.withAlpha((0.1 * 255).round());
    final borderColor = theme.primaryColor.withAlpha((0.25 * 255).round());

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Icon(icon, color: theme.primaryColor),
        ),
      ),
    );
  }

  Widget _buildTodayButton({
    required String label,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    final primary = theme.primaryColor;
    final highlight =
        Color.lerp(primary, Colors.white, 0.25) ?? theme.primaryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [highlight, primary]),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: primary.withAlpha((0.25 * 255).round()),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
  }
}
