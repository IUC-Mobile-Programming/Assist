import 'dart:io';

import 'package:Assist/data/repositories/task_repository.dart';
import 'package:Assist/data/repositories/calendar_repository.dart';
import 'package:Assist/data/repositories/mocks/task_repository_mock.dart';
import 'package:Assist/data/repositories/mocks/calendar_repository_mock.dart';
import 'package:Assist/domain/use_cases/task_use_cases.dart';
import 'package:Assist/domain/use_cases/calendar_use_cases.dart';
import 'package:Assist/services/ai_service.dart';
import 'package:Assist/services/database_service.dart';
import 'package:Assist/services/notification_service.dart';
import 'package:Assist/services/voice_service.dart';
import 'package:Assist/services/localization_service.dart';
import 'package:Assist/services/theme_service.dart';
import 'package:Assist/presentation/viewmodels/home_viewmodel.dart';
import 'package:Assist/presentation/viewmodels/calendar_viewmodel.dart';
import 'package:Assist/presentation/viewmodels/settings_viewmodel.dart';

class ServiceLocator {
  late final TaskRepository _taskRepository;
  late final CalendarRepository _calendarRepository;

  late final GetTasksUseCase _getTasksUseCase;
  late final AddTaskUseCase _addTaskUseCase;
  late final UpdateTaskUseCase _updateTaskUseCase;
  late final DeleteTaskUseCase _deleteTaskUseCase;
  late final ToggleTaskCompletionUseCase _toggleTaskCompletionUseCase;
  late final GetUpcomingTasksUseCase _getUpcomingTasksUseCase;

  late final GetEventsUseCase _getEventsUseCase;
  late final AddEventUseCase _addEventUseCase;
  late final GetEventsForDateUseCase _getEventsForDateUseCase;

  late final LocalizationService _localizationService;
  late final ThemeService _themeService;
  late final AIService _aiService;
  late final DatabaseService _databaseService;
  late final NotificationService _notificationService;
  late final VoiceService _voiceService;

  late final HomeViewModel _homeViewModel;
  late final CalendarViewModel _calendarViewModel;
  late final SettingsViewModel _settingsViewModel;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;

  ServiceLocator._internal() {
    _notificationService = LocalNotificationService();
    _databaseService = DatabaseService();
    _voiceService = VoiceService();
    _localizationService = LocalizationService();
    _themeService = ThemeService();
    _taskRepository = InMemoryTaskRepository();
    _calendarRepository = InMemoryCalendarRepository();

    final ollamaBaseUrl = Platform.isAndroid
        ? 'http://10.0.2.2:11434'
        : 'http://127.0.0.1:11434';
    _aiService = OllamaAIService(
      baseUrl: ollamaBaseUrl,
      model: 'neural-chat:latest',
      localizationService: _localizationService,
    );

    _getTasksUseCase = GetTasksUseCase(_taskRepository);
    _addTaskUseCase = AddTaskUseCase(_taskRepository, _notificationService);
    _updateTaskUseCase = UpdateTaskUseCase(_taskRepository, _notificationService);
    _deleteTaskUseCase = DeleteTaskUseCase(_taskRepository, _notificationService);
    _toggleTaskCompletionUseCase = ToggleTaskCompletionUseCase(_taskRepository);
    _getUpcomingTasksUseCase = GetUpcomingTasksUseCase(_taskRepository);

    _getEventsUseCase = GetEventsUseCase(_calendarRepository);
    _addEventUseCase = AddEventUseCase(_calendarRepository);
    _getEventsForDateUseCase = GetEventsForDateUseCase(_calendarRepository);

    _homeViewModel = HomeViewModel(
      getTasksUseCase: _getTasksUseCase,
      addTaskUseCase: _addTaskUseCase,
      toggleTaskCompletionUseCase: _toggleTaskCompletionUseCase,
      getUpcomingTasksUseCase: _getUpcomingTasksUseCase,
      databaseService: _databaseService,
      aiService: _aiService,
      notificationService: _notificationService,
    );

    _calendarViewModel = CalendarViewModel(
      getEventsUseCase: _getEventsUseCase,
      addEventUseCase: _addEventUseCase,
      getEventsForDateUseCase: _getEventsForDateUseCase,
      localizationService: _localizationService,
      databaseService: _databaseService,
    );

    _settingsViewModel = SettingsViewModel(
      themeService: _themeService,
      localizationService: _localizationService,
    );
  }

  TaskRepository get taskRepository => _taskRepository;
  CalendarRepository get calendarRepository => _calendarRepository;
  GetTasksUseCase get getTasksUseCase => _getTasksUseCase;
  AddTaskUseCase get addTaskUseCase => _addTaskUseCase;
  UpdateTaskUseCase get updateTaskUseCase => _updateTaskUseCase;
  DeleteTaskUseCase get deleteTaskUseCase => _deleteTaskUseCase;
  ToggleTaskCompletionUseCase get toggleTaskCompletionUseCase => _toggleTaskCompletionUseCase;
  GetUpcomingTasksUseCase get getUpcomingTasksUseCase => _getUpcomingTasksUseCase;
  GetEventsUseCase get getEventsUseCase => _getEventsUseCase;
  AddEventUseCase get addEventUseCase => _addEventUseCase;
  GetEventsForDateUseCase get getEventsForDateUseCase => _getEventsForDateUseCase;
  LocalizationService get localizationService => _localizationService;
  ThemeService get themeService => _themeService;
  AIService get aiService => _aiService;
  DatabaseService get databaseService => _databaseService;
  NotificationService get notificationService => _notificationService;
  VoiceService get voiceService => _voiceService;
  HomeViewModel get homeViewModel => _homeViewModel;
  CalendarViewModel get calendarViewModel => _calendarViewModel;
  SettingsViewModel get settingsViewModel => _settingsViewModel;
}

Future<void> setupDependencies() async {
  final locator = ServiceLocator();
  if (locator._isInitialized) return;
  
  // Async servisleri başlat
  await Future.wait([
    locator.notificationService.init(),
    locator.databaseService.database.then((_) {}),
  ]);
  
  locator._isInitialized = true;
}
