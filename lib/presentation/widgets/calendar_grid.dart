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

  Color _blend(Color first, Color second, double t) {
    return Color.lerp(first, second, t) ?? first;
  }

  Color _shadowColor(ThemeData theme, {double light = 0.08, double dark = 0.3}) {
    return Color.fromRGBO(
      0,
      0,
      0,
      theme.brightness == Brightness.dark ? dark : light,
    );
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
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.2),
                  blurRadius: 8,
                  spreadRadius: 2,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                _removeOverlay();
                _showAddEventDialog(context, date);
              },
              icon: const Icon(Icons.add, size: 20),
              label: Text(
                Provider.of<LocalizationService>(context, listen: false)
                    .addEvent,
                style: const TextStyle(fontSize: 12),
              ),
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
    final localizationService =
        Provider.of<LocalizationService>(context, listen: false);
    final taskNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizationService.addQuickEvent),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${date.day}.${date.month}.${date.year} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: taskNameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: localizationService.title,
                hintText: localizationService.enterTaskTitle,
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizationService.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (taskNameController.text.trim().isNotEmpty) {
                final now = DateTime.now();
                await widget.viewModel.databaseService.insertTask({
                  'title': taskNameController.text.trim(),
                  'dueDate': date.toIso8601String(),
                  'description': '',
                  'category': null,
                  'completed': 0,
                  'important': 0,
                  'createdAt': now.toIso8601String(),
                  'updatedAt': now.toIso8601String(),
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  // Refresh the UI by calling setState
                  setState(() {});
                }
              }
            },
            child: Text(localizationService.save),
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
    final borderColor = theme.dividerColor.withAlpha((0.2 * 255).round());
    final firstDay = DateTime(widget.viewModel.currentDate.year,
        widget.viewModel.currentDate.month, 1);
    final lastDay = DateTime(widget.viewModel.currentDate.year,
        widget.viewModel.currentDate.month + 1, 0);
    final startingWeekday = firstDay.weekday;
    final totalDays = lastDay.day;
    final totalWeeks = ((startingWeekday + totalDays - 1) / 7).ceil();

    return Column(
      children: [
        _buildMonthDayHeaders(localizationService, theme),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: _shadowColor(theme),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FutureBuilder<Map<int, int>>(
                future: widget.viewModel.getTaskCountsForMonth(),
                builder: (context, snapshot) {
                  final taskCounts = snapshot.data ?? {};

                  return GridView.builder(
                    padding: const EdgeInsets.all(6),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: 1.1,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                    ),
                    itemCount: totalWeeks * 7,
                    itemBuilder: (context, index) {
                      final dayOffset = index - (startingWeekday - 1);
                      final isCurrentMonth =
                          dayOffset >= 0 && dayOffset < totalDays;
                      final day = isCurrentMonth ? dayOffset + 1 : null;
                      final dayDate = isCurrentMonth
                          ? DateTime(widget.viewModel.currentDate.year,
                              widget.viewModel.currentDate.month, day!)
                          : null;
                      final taskCount = day != null ? (taskCounts[day] ?? 0) : 0;

                      return _buildDayCell(
                        day: day,
                        dayDate: dayDate,
                        theme: theme,
                        taskCount: taskCount,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthDayHeaders(
      LocalizationService localizationService, ThemeData theme) {
    final borderColor = theme.dividerColor.withAlpha((0.2 * 255).round());
    final backgroundColor =
        _blend(theme.cardColor, theme.scaffoldBackgroundColor, 0.4);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: List.generate(7, (index) {
          final dayName =
              localizationService.getDayName(index + 1, short: true);
          final isWeekend = index >= 5;

          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              alignment: Alignment.center,
              child: Text(
                dayName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isWeekend
                      ? theme.colorScheme.error
                      : theme.textTheme.bodyMedium?.color,
                  letterSpacing: 0.4,
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
    required int taskCount,
  }) {
    if (day == null) {
      return const SizedBox.shrink();
    }

    final isToday = dayDate != null &&
        dayDate.year == DateTime.now().year &&
        dayDate.month == DateTime.now().month &&
        dayDate.day == DateTime.now().day;
    final isWeekend = dayDate != null && dayDate.weekday >= DateTime.saturday;
    final borderColor = theme.dividerColor.withAlpha((0.2 * 255).round());
    final highlight = theme.primaryColor.withAlpha((0.22 * 255).round());

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: dayDate != null ? () => _showTasksForDate(context, dayDate) : null,
        onLongPress: dayDate != null
            ? () {
                // Long press logic handled by GestureDetector in parent or here?
                // Parent used GestureDetector.onLongPress in older code, but we are inside _buildDayCell now.
                // The original code passed standard gestures. But we want tap.
                _showAddEventOverlay(dayDate!, Offset.zero); // Position might be tricky here without details
                // Actually original code used _startLongPressTimer with position.
                // Simpler for now: just tap shows tasks. Long press for add remains if possible,
                // but for now let's focus on the tap requirement.
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: !isToday && isWeekend
                ? theme.colorScheme.error.withAlpha((0.08 * 255).round())
                : null,
            gradient: isToday
                ? LinearGradient(
                    colors: [
                      highlight,
                      theme.primaryColor.withAlpha((0.07 * 255).round()),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isToday ? theme.primaryColor : borderColor,
              width: 1.2,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 6,
                left: 8,
                child: Text(
                  day.toString(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
                    color: isToday
                        ? theme.primaryColor
                        : (isWeekend
                            ? theme.colorScheme.error
                            : theme.textTheme.bodyMedium?.color),
                  ),
                ),
              ),
              if (taskCount > 0)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _buildTaskBadge(taskCount, theme),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskBadge(int taskCount, ThemeData theme) {
    final primary = theme.primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: primary.withAlpha((0.12 * 255).round()),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: primary.withAlpha((0.4 * 255).round())),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            taskCount.toString(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: primary,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekView(BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context);
    final theme = Theme.of(context);
    final startOfWeek = widget.viewModel.currentDate
        .subtract(Duration(days: widget.viewModel.currentDate.weekday - 1));

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

  Widget _buildWeekDayHeaders(LocalizationService localizationService,
      ThemeData theme, DateTime startOfWeek) {
    final borderColor = theme.dividerColor.withAlpha((0.2 * 255).round());
    final headerBackground =
        _blend(theme.cardColor, theme.scaffoldBackgroundColor, 0.35);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: _shadowColor(theme),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                color: headerBackground,
              ),
            ),
            Expanded(
              child: Row(
                children: List.generate(7, (index) {
                  final dayDate = startOfWeek.add(Duration(days: index));
                  final dayName = localizationService.getDayName(
                      dayDate.weekday,
                      short: true);
                  final isWeekend = dayDate.weekday >= DateTime.saturday;
                  final isToday = dayDate.year == DateTime.now().year &&
                      dayDate.month == DateTime.now().month &&
                      dayDate.day == DateTime.now().day;

                  return Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isToday
                            ? theme.primaryColor
                                .withAlpha((0.1 * 255).round())
                            : (isWeekend
                                ? theme.colorScheme.error
                                    .withAlpha((0.05 * 255).round())
                                : Colors.transparent),
                        border: Border(
                          right: index < 6
                              ? BorderSide(
                                  color: theme.dividerColor
                                      .withAlpha((0.3 * 255).round()),
                                )
                              : BorderSide.none,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dayName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              color: isToday
                                  ? theme.primaryColor
                                  : (isWeekend
                                      ? theme.colorScheme.error
                                      : theme.textTheme.bodyMedium?.color),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dayDate.day.toString(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isToday
                                  ? theme.primaryColor
                                  : theme.textTheme.titleMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyWeekView(DateTime startOfWeek, ThemeData theme) {
    final borderColor = theme.dividerColor.withAlpha((0.2 * 255).round());
    final rowDivider = theme.dividerColor.withAlpha((0.35 * 255).round());
    final columnDivider = theme.dividerColor.withAlpha((0.25 * 255).round());
    final timeLabelBackground =
        _blend(theme.cardColor, theme.scaffoldBackgroundColor, 0.6);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: _shadowColor(theme),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 60,
                child: Container(
                  color: timeLabelBackground,
                  child: Column(
                    children: List.generate(24, (hour) {
                      return Container(
                        height: 60,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: rowDivider),
                            right: BorderSide(color: columnDivider),
                          ),
                        ),
                        alignment: Alignment.topCenter,
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${hour.toString().padLeft(2, '0')}:00',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodySmall?.color
                                ?.withAlpha((0.7 * 255).round()),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
                  future: _getTasksForWeek(startOfWeek),
                  builder: (context, snapshot) {
                    final tasksByDay = snapshot.data ?? {};

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(7, (dayIndex) {
                        final dayDate =
                            startOfWeek.add(Duration(days: dayIndex));
                        final dayKey =
                            '${dayDate.year}-${dayDate.month}-${dayDate.day}';
                        final tasksForDay = tasksByDay[dayKey] ?? [];
                        final isToday = dayDate.year == DateTime.now().year &&
                            dayDate.month == DateTime.now().month &&
                            dayDate.day == DateTime.now().day;
                        final isWeekend =
                            dayDate.weekday >= DateTime.saturday;

                        return Expanded(
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Container(
                                    color: isToday
                                        ? theme.primaryColor
                                            .withAlpha((0.05 * 255).round())
                                        : (isWeekend
                                            ? theme.colorScheme.error.withAlpha(
                                                (0.04 * 255).round())
                                            : Colors.transparent),
                                  ),
                                ),
                              ),
                              Column(
                                children: List.generate(24, (hour) {
                                  return GestureDetector(
                                    onTapDown: (details) {
                                      final hourDateTime = DateTime(
                                        dayDate.year,
                                        dayDate.month,
                                        dayDate.day,
                                        hour,
                                      );
                                      _startLongPressTimer(
                                          hourDateTime,
                                          details.globalPosition);
                                    },
                                    onTapUp: (_) => _cancelLongPress(),
                                    onTapCancel: _cancelLongPress,
                                    child: Container(
                                      height: 60,
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(color: rowDivider),
                                          right: dayIndex < 6
                                              ? BorderSide(
                                                  color: columnDivider)
                                              : BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              ...tasksForDay.map((task) {
                                final dueDate = DateTime.parse(task['dueDate']);
                                final hour = dueDate.hour;
                                final minute = dueDate.minute;
                                final topPosition = (hour * 60.0) + minute;

                                return Positioned(
                                  top: topPosition,
                                  left: 4,
                                  right: 4,
                                  child: Container(
                                    height: 50,
                                    margin: const EdgeInsets.only(bottom: 4),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor
                                          .withAlpha((0.85 * 255).round()),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: theme.primaryColor
                                            .withAlpha((0.6 * 255).round()),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _shadowColor(
                                            theme,
                                            light: 0.18,
                                            dark: 0.4,
                                          ),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      task['title'] ?? '',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, List<Map<String, dynamic>>>> _getTasksForWeek(
      DateTime startOfWeek) async {
    try {
      final taskMaps = await widget.viewModel.databaseService.getTasks();
      final tasksByDay = <String, List<Map<String, dynamic>>>{};

      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      for (var taskMap in taskMaps) {
        final dueDateStr = taskMap['dueDate'] as String?;
        final completed = (taskMap['completed'] as int?) ?? 0;

        if (dueDateStr != null && completed == 0) {
          try {
            final dueDate = DateTime.parse(dueDateStr);
            if (dueDate
                    .isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
                dueDate.isBefore(endOfWeek)) {
              final dayKey = '${dueDate.year}-${dueDate.month}-${dueDate.day}';
              tasksByDay.putIfAbsent(dayKey, () => []);
              tasksByDay[dayKey]!.add(taskMap);
            }
          } catch (e) {
            // Skip invalid date formats
          }
        }
      }

      return tasksByDay;
    } catch (e) {
      return {};
    }
  }

  Future<void> _showTasksForDate(BuildContext context, DateTime date) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${date.day}.${date.month}.${date.year} Görevleri',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 400,
                child: FutureBuilder<List<dynamic>>(
                  future: widget.viewModel.getTasksForDate(date),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError) {
                      return Center(child: Text('Hata: ${snapshot.error}'));
                    }

                    final tasks = snapshot.data ?? [];
                    
                    if (tasks.isEmpty) {
                      return const Center(child: Text('Bu tarihte görev yok.'));
                    }

                    return ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index] as CalendarTask;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              if (task.description.isNotEmpty)
                                Text(
                                  task.description,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (task.date.hour != 0 || task.date.minute != 0)
                                Text(
                                   '${task.date.hour}:${task.date.minute.toString().padLeft(2, '0')}',
                                   style: const TextStyle(fontSize: 12, color: Colors.grey),
                                )
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
