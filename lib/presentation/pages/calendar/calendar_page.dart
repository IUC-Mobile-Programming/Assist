import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:assist_ai/presentation/viewmodels/calendar_viewmodel.dart';
import 'package:assist_ai/presentation/widgets/calendar_header.dart';
import 'package:assist_ai/presentation/widgets/calendar_grid.dart';
import 'package:assist_ai/presentation/widgets/calendar_navigation.dart';
import 'package:assist_ai/services/localization_service.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoading && viewModel.events.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (viewModel.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(viewModel.error!),
                ElevatedButton(
                  onPressed: () => viewModel.loadEvents(),
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            CalendarNavigation(viewModel: viewModel),
            const SizedBox(height: 16),
            CalendarHeader(viewModel: viewModel),
            const SizedBox(height: 16),
            Expanded(
              child: CalendarGrid(viewModel: viewModel),
            ),
          ],
        );
      },
    );
  }
}