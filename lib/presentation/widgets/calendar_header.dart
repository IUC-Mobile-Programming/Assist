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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildViewModeButton(
            mode: CalendarViewMode.month,
            label: localizationService.month,
            icon: Icons.calendar_month,
            theme: theme,
          ),
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

    return Expanded(
      child: GestureDetector(
        onTap: () => viewModel.setViewMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? theme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : theme.iconTheme.color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}