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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: theme.primaryColor),
            onPressed: viewModel.navigateToPrevious,
          ),
          Column(
            children: [
              Text(
                viewModel.viewMode == CalendarViewMode.month
                    ? '${localizationService.getMonthName(viewModel.currentDate.month)} ${viewModel.currentDate.year}'
                    : viewModel.getWeekRange(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor.withAlpha((0.1 * 255).round()),
                  foregroundColor: theme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                ),
                onPressed: viewModel.navigateToToday,
                child: Text(localizationService.today),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: theme.primaryColor),
            onPressed: viewModel.navigateToNext,
          ),
        ],
      ),
    );
  }
}