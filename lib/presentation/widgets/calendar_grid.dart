import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Assist/presentation/viewmodels/calendar_viewmodel.dart';
import 'package:Assist/data/models/calendar_event.dart';
import 'package:Assist/services/localization_service.dart';

class CalendarGrid extends StatefulWidget {
  final CalendarViewModel viewModel;

  const CalendarGrid({super.key, required this.viewModel});

  @override
  State<CalendarGrid> createState() => _CalendarGridState();
}

class _CalendarGridState extends State<CalendarGrid> {
  OverlayEntry? _overlayEntry;
  DateTime? _longPressedDate;
  Offset? _longPressPosition;
  Timer? _longPressTimer;

  @override
  void dispose() {
    _removeOverlay();
    _longPressTimer?.cancel();
    super.dispose();
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  void _startLongPressTimer(DateTime date, Offset position) {
    _longPressTimer?.cancel();
    _longPressedDate = date;
    _longPressPosition = position;

    _longPressTimer = Timer(const Duration(milliseconds: 500), () {
      if (_longPressedDate != null && _longPressPosition != null) {
        _showAddEventOverlay(_longPressedDate!, _longPressPosition!);
      }
    });
  }

  void _cancelLongPress() {
    _longPressTimer?.cancel();
    _longPressedDate = null;
    _longPressPosition = null;
  }

  void _showAddEventOverlay(DateTime date, Offset position) {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx - 60,
        top: position.dy - 25,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 120,
            height: 50,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.2),
                  blurRadius: 8,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                _removeOverlay();
                _showAddEventDialog(context, date);
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Etkinlik Ekle', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _showAddEventDialog(BuildContext context, DateTime date) {
    // TODO: Implement add event dialog with ViewModel integration
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Etkinlik Ekle'),
        content: Text('Etkinlik ekleme dialogu için ${date.day}.${date.month}.${date.year}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              // Add event using ViewModel
              final newEvent = CalendarEvent(
                title: 'Yeni Etkinlik',
                description: 'Açıklama',
                startTime: const TimeOfDay(hour: 14, minute: 30),
                endTime: const TimeOfDay(hour: 15, minute: 30),
                date: date,
                color: Colors.blue,
              );
              widget.viewModel.addEvent(newEvent);
              Navigator.pop(context);
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _removeOverlay();
        _cancelLongPress();
      },
      child: widget.viewModel.viewMode == CalendarViewMode.month
          ? _buildMonthView(context)
          : _buildWeekView(context),
    );
  }

  Widget _buildMonthView(BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context);
    final theme = Theme.of(context);
    final firstDay = DateTime(widget.viewModel.currentDate.year, widget.viewModel.currentDate.month, 1);
    final lastDay = DateTime(widget.viewModel.currentDate.year, widget.viewModel.currentDate.month + 1, 0);
    final startingWeekday = firstDay.weekday;
    final totalDays = lastDay.day;
    final totalWeeks = ((startingWeekday + totalDays - 1) / 7).ceil();

    return Column(
      children: [
        _buildMonthDayHeaders(localizationService, theme),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.2,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: totalWeeks * 7,
            itemBuilder: (context, index) {
              final dayOffset = index - (startingWeekday - 1);
              final isCurrentMonth = dayOffset >= 0 && dayOffset < totalDays;
              final day = isCurrentMonth ? dayOffset + 1 : null;
              final dayDate = isCurrentMonth
                  ? DateTime(widget.viewModel.currentDate.year, widget.viewModel.currentDate.month, day!)
                  : null;

              return _buildDayCell(
                day: day,
                dayDate: dayDate,
                theme: theme,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMonthDayHeaders(LocalizationService localizationService, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: List.generate(7, (index) {
          final dayName = localizationService.getDayName(index + 1, short: true);
          final isWeekend = index >= 5;

          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              child: Text(
                dayName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isWeekend ? Colors.red : theme.textTheme.bodyMedium?.color,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayCell({
    required int? day,
    required DateTime? dayDate,
    required ThemeData theme,
  }) {
    if (day == null) {
      return Container();
    }

    final isToday = dayDate != null &&
        dayDate.year == DateTime.now().year &&
        dayDate.month == DateTime.now().month &&
        dayDate.day == DateTime.now().day;

    // Get events for this day
    final eventsForDay = widget.viewModel.events[DateTime(dayDate!.year, dayDate.month, dayDate.day)] ?? [];

    return GestureDetector(
      onTapDown: (details) => _startLongPressTimer(dayDate, details.globalPosition),
      onTapUp: (_) => _cancelLongPress(),
      onTapCancel: _cancelLongPress,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isToday ? theme.primaryColor.withAlpha((0.2 * 255).round()) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isToday ? theme.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                day.toString(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isToday ? theme.primaryColor : theme.textTheme.bodyMedium?.color,
                ),
              ),
            ),
            if (eventsForDay.isNotEmpty) ...[
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 4),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: eventsForDay.length > 2 ? 2 : eventsForDay.length,
                  itemBuilder: (context, index) {
                    final event = eventsForDay[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: event.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (eventsForDay.length > 2)
                Padding(
                  padding: const EdgeInsets.only(right: 4, bottom: 4),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '+${eventsForDay.length - 2}',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeekView(BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context);
    final theme = Theme.of(context);
    final startOfWeek = widget.viewModel.currentDate.subtract(Duration(days: widget.viewModel.currentDate.weekday - 1));

    return Column(
      children: [
        _buildWeekDayHeaders(localizationService, theme, startOfWeek),
        const SizedBox(height: 8),
        Expanded(
          child: _buildHourlyWeekView(startOfWeek, theme),
        ),
      ],
    );
  }

  Widget _buildWeekDayHeaders(LocalizationService localizationService, ThemeData theme, DateTime startOfWeek) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: List.generate(7, (index) {
          final dayDate = startOfWeek.add(Duration(days: index));
          final dayName = localizationService.getDayName(dayDate.weekday, short: true);
          final isWeekend = dayDate.weekday >= 6;
          final isToday = dayDate.year == DateTime.now().year &&
              dayDate.month == DateTime.now().month &&
              dayDate.day == DateTime.now().day;

          return Expanded(
            child: GestureDetector(
              onTapDown: (details) => _startLongPressTimer(dayDate, details.globalPosition),
              onTapUp: (_) => _cancelLongPress(),
              onTapCancel: _cancelLongPress,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isToday ? theme.primaryColor.withAlpha((0.2 * 255).round()) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dayName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isToday
                            ? theme.primaryColor
                            : (isWeekend ? Colors.red : theme.textTheme.bodyMedium?.color),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dayDate.day.toString(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isToday ? theme.primaryColor : theme.textTheme.titleSmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHourlyWeekView(DateTime startOfWeek, ThemeData theme) {
    // This is a simplified hourly view. You would need to implement the full version
    // with events positioned at their specific times.
    return Row(
      children: [
        // Time labels column
        SizedBox(
          width: 60,
          child: ListView.builder(
            itemCount: 24,
            itemBuilder: (context, hour) {
              return Container(
                height: 60,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: theme.dividerColor),
                  ),
                ),
                child: Center(
                  child: Text(
                    '${hour.toString().padLeft(2, '0')}:00',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              );
            },
          ),
        ),
        // Days columns
        Expanded(
          child: Row(
            children: List.generate(7, (dayIndex) {
              final dayDate = startOfWeek.add(Duration(days: dayIndex));

              return Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: theme.dividerColor),
                      right: dayIndex == 6 ? BorderSide(color: theme.dividerColor) : BorderSide.none,
                    ),
                  ),
                  child: Column(
                    children: List.generate(24, (hour) {
                      return GestureDetector(
                        onTapDown: (details) => _startLongPressTimer(dayDate, details.globalPosition),
                        onTapUp: (_) => _cancelLongPress(),
                        onTapCancel: _cancelLongPress,
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: theme.dividerColor),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}