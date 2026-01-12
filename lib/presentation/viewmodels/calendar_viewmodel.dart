import 'package:flutter/material.dart';
import 'package:Assist/data/models/calendar_event.dart';
import 'package:Assist/domain/use_cases/calendar_use_cases.dart';
import 'package:Assist/services/localization_service.dart';
import 'package:Assist/services/database_service.dart';

enum CalendarViewMode { month, week }

class CalendarViewModel extends ChangeNotifier {
  final GetEventsUseCase _getEventsUseCase;
  final AddEventUseCase _addEventUseCase;
  final GetEventsForDateUseCase _getEventsForDateUseCase;
  final LocalizationService _localizationService;
  final DatabaseService _databaseService;

  Map<DateTime, List<CalendarEvent>> _events = {};
  Map<DateTime, List<CalendarEvent>> get events => _events;

  CalendarViewMode _viewMode = CalendarViewMode.month;
  CalendarViewMode get viewMode => _viewMode;

  DateTime _currentDate = DateTime.now();
  DateTime get currentDate => _currentDate;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  DatabaseService get databaseService => _databaseService;

  CalendarViewModel({
    required GetEventsUseCase getEventsUseCase,
    required AddEventUseCase addEventUseCase,
    required GetEventsForDateUseCase getEventsForDateUseCase,
    required LocalizationService localizationService,
    required DatabaseService databaseService,
  })  : _getEventsUseCase = getEventsUseCase,
        _addEventUseCase = addEventUseCase,
        _getEventsForDateUseCase = getEventsForDateUseCase,
        _localizationService = localizationService,
        _databaseService = databaseService {
    loadEvents();
  }

  Future<void> loadEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _events = await _getEventsUseCase.execute();
    } catch (e) {
      _error = 'Etkinlikler yüklenirken bir hata oluştu: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<CalendarEvent>> getEventsForDate(DateTime date) async {
    try {
      return await _getEventsForDateUseCase.execute(date);
    } catch (e) {
      _error = 'Tarih için etkinlikler yüklenirken bir hata oluştu: $e';
      notifyListeners();
      return [];
    }
  }

  Future<void> addEvent(CalendarEvent event) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _addEventUseCase.execute(event);
      await loadEvents();
    } catch (e) {
      _error = 'Etkinlik eklenirken bir hata oluştu: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setViewMode(CalendarViewMode mode) {
    _viewMode = mode;
    notifyListeners();
  }

  void navigateToPrevious() {
    if (_viewMode == CalendarViewMode.month) {
      _currentDate = DateTime(_currentDate.year, _currentDate.month - 1, 1);
    } else {
      _currentDate = _currentDate.subtract(const Duration(days: 7));
    }
    notifyListeners();
  }

  void navigateToNext() {
    if (_viewMode == CalendarViewMode.month) {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + 1, 1);
    } else {
      _currentDate = _currentDate.add(const Duration(days: 7));
    }
    notifyListeners();
  }

  void navigateToToday() {
    _currentDate = DateTime.now();
    notifyListeners();
  }

  String getWeekRange() {
    final startOfWeek =
        _currentDate.subtract(Duration(days: _currentDate.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return '${startOfWeek.day} ${_localizationService.getMonthName(startOfWeek.month)} - ${endOfWeek.day} ${_localizationService.getMonthName(endOfWeek.month)} ${endOfWeek.year}';
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<Map<int, int>> getTaskCountsForMonth() async {
    try {
      final taskMaps = await _databaseService.getTasks();
      final taskCounts = <int, int>{};

      for (var taskMap in taskMaps) {
        final dueDateStr = taskMap['dueDate'] as String?;
        final completed = (taskMap['completed'] as int?) ?? 0;

        if (dueDateStr != null && completed == 0) {
          try {
            final dueDate = DateTime.parse(dueDateStr);
            if (dueDate.year == _currentDate.year &&
                dueDate.month == _currentDate.month) {
              final day = dueDate.day;
              taskCounts[day] = (taskCounts[day] ?? 0) + 1;
            }
          } catch (e) {
            // Skip invalid date formats
          }
        }
      }

      return taskCounts;
    } catch (e) {
      _error = 'Görevler yüklenirken bir hata oluştu: $e';
      notifyListeners();
      return {};
    }
  }
}
