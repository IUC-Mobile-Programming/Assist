import 'package:assist_ai/data/repositories/task_repository.dart';
import 'package:assist_ai/data/repositories/calendar_repository.dart';
import 'package:assist_ai/domain/use_cases/task_use_cases.dart';
import 'package:assist_ai/domain/use_cases/calendar_use_cases.dart';
import 'package:assist_ai/services/localization_service.dart';
import 'package:assist_ai/services/theme_service.dart';
import 'package:assist_ai/presentation/viewmodels/home_viewmodel.dart';
import 'package:assist_ai/presentation/viewmodels/calendar_viewmodel.dart';
import 'package:assist_ai/presentation/viewmodels/settings_viewmodel.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  // Repositories
  TaskRepository get taskRepository => TaskRepositoryImpl();
  CalendarRepository get calendarRepository => CalendarRepositoryImpl();

  // Use Cases
  GetTasksUseCase get getTasksUseCase => GetTasksUseCase(taskRepository);
  AddTaskUseCase get addTaskUseCase => AddTaskUseCase(taskRepository);
  ToggleTaskCompletionUseCase get toggleTaskCompletionUseCase =>
      ToggleTaskCompletionUseCase(taskRepository);
  GetUpcomingTasksUseCase get getUpcomingTasksUseCase =>
      GetUpcomingTasksUseCase(taskRepository);

  GetEventsUseCase get getEventsUseCase => GetEventsUseCase(calendarRepository);
  AddEventUseCase get addEventUseCase => AddEventUseCase(calendarRepository);
  GetEventsForDateUseCase get getEventsForDateUseCase =>
      GetEventsForDateUseCase(calendarRepository);

  // Services
  LocalizationService get localizationService => LocalizationService();
  ThemeService get themeService => ThemeService();

  // ViewModels
  HomeViewModel get homeViewModel => HomeViewModel(
    getTasksUseCase: getTasksUseCase,
    addTaskUseCase: addTaskUseCase,
    toggleTaskCompletionUseCase: toggleTaskCompletionUseCase,
    getUpcomingTasksUseCase: getUpcomingTasksUseCase,
  );

  CalendarViewModel get calendarViewModel => CalendarViewModel(
    getEventsUseCase: getEventsUseCase,
    addEventUseCase: addEventUseCase,
    getEventsForDateUseCase: getEventsForDateUseCase,
  );

  SettingsViewModel get settingsViewModel => SettingsViewModel(
    themeService: themeService,
    localizationService: localizationService,
  );
}

void setupDependencies() {
  // Initialize any dependencies here
}