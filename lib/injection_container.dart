import 'package:Assist/data/repositories/task_repository.dart';
import 'package:Assist/data/repositories/calendar_repository.dart';
import 'package:Assist/domain/use_cases/task_use_cases.dart';
import 'package:Assist/domain/use_cases/calendar_use_cases.dart';
import 'package:Assist/services/localization_service.dart';
import 'package:Assist/services/theme_service.dart';
import 'package:Assist/services/database_service.dart';
import 'package:Assist/presentation/viewmodels/home_viewmodel.dart';
import 'package:Assist/presentation/viewmodels/calendar_viewmodel.dart';
import 'package:Assist/presentation/viewmodels/settings_viewmodel.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal() {
    // Initialize singletons
    _taskRepository = TaskRepositoryImpl();
    _calendarRepository = CalendarRepositoryImpl();

    // Use cases
    _getTasksUseCase = GetTasksUseCase(_taskRepository);
    _addTaskUseCase = AddTaskUseCase(_taskRepository);
    _toggleTaskCompletionUseCase = ToggleTaskCompletionUseCase(_taskRepository);
    _getUpcomingTasksUseCase = GetUpcomingTasksUseCase(_taskRepository);

    _getEventsUseCase = GetEventsUseCase(_calendarRepository);
    _addEventUseCase = AddEventUseCase(_calendarRepository);
    _getEventsForDateUseCase = GetEventsForDateUseCase(_calendarRepository);

    // Services
    _localizationService = LocalizationService();
    _themeService = ThemeService();

    // ViewModels (long-lived singletons)
    _homeViewModel = HomeViewModel(
      getTasksUseCase: _getTasksUseCase,
      addTaskUseCase: _addTaskUseCase,
      toggleTaskCompletionUseCase: _toggleTaskCompletionUseCase,
      getUpcomingTasksUseCase: _getUpcomingTasksUseCase,
    );

    _calendarViewModel = CalendarViewModel(
      getEventsUseCase: _getEventsUseCase,
      addEventUseCase: _addEventUseCase,
      getEventsForDateUseCase: _getEventsForDateUseCase,
    );

    _settingsViewModel = SettingsViewModel(
      themeService: _themeService,
      localizationService: _localizationService,
    );
  }

  // Private backing fields
  late final TaskRepository _taskRepository;
  late final CalendarRepository _calendarRepository;

  late final GetTasksUseCase _getTasksUseCase;
  late final AddTaskUseCase _addTaskUseCase;
  late final ToggleTaskCompletionUseCase _toggleTaskCompletionUseCase;
  late final GetUpcomingTasksUseCase _getUpcomingTasksUseCase;

  late final GetEventsUseCase _getEventsUseCase;
  late final AddEventUseCase _addEventUseCase;
  late final GetEventsForDateUseCase _getEventsForDateUseCase;

  late final LocalizationService _localizationService;
  late final ThemeService _themeService;

  late final HomeViewModel _homeViewModel;
  late final CalendarViewModel _calendarViewModel;
  late final SettingsViewModel _settingsViewModel;

  // Repositories
  TaskRepository get taskRepository => _taskRepository;
  CalendarRepository get calendarRepository => _calendarRepository;

  // Use Cases
  GetTasksUseCase get getTasksUseCase => _getTasksUseCase;
  AddTaskUseCase get addTaskUseCase => _addTaskUseCase;
  ToggleTaskCompletionUseCase get toggleTaskCompletionUseCase => _toggleTaskCompletionUseCase;
  GetUpcomingTasksUseCase get getUpcomingTasksUseCase => _getUpcomingTasksUseCase;

  GetEventsUseCase get getEventsUseCase => _getEventsUseCase;
  AddEventUseCase get addEventUseCase => _addEventUseCase;
  GetEventsForDateUseCase get getEventsForDateUseCase => _getEventsForDateUseCase;

  // Services
  LocalizationService get localizationService => LocalizationService();
  ThemeService get themeService => ThemeService();
  final DatabaseService _databaseService = DatabaseService();
  DatabaseService get databaseService => _databaseService;

  // ViewModels
  HomeViewModel get homeViewModel => _homeViewModel;
  CalendarViewModel get calendarViewModel => _calendarViewModel;
  SettingsViewModel get settingsViewModel => _settingsViewModel;
}

void setupDependencies() {
  // Intentionally left for future async initializations (e.g., loading persisted preferences)
  // Currently ServiceLocator has been initialized lazily by its factory.
}