import 'package:flutter/material.dart';
import 'package:Assist/data/models/task.dart';
import 'package:Assist/data/models/ai_recommendation.dart';
import 'package:Assist/domain/use_cases/task_use_cases.dart';
import 'package:Assist/data/repositories/task_repository.dart';
import 'package:Assist/services/database_service.dart';
import 'package:Assist/services/ai_service.dart';

class HomeViewModel extends ChangeNotifier {
  final GetTasksUseCase? _getTasksUseCase;
  final AddTaskUseCase? _addTaskUseCase;
  final ToggleTaskCompletionUseCase? _toggleTaskCompletionUseCase;
  final GetUpcomingTasksUseCase? _getUpcomingTasksUseCase;
  final DatabaseService? _databaseService;
  final AIService? _aiService;

  List<Task> _tasks = [];
  List<Task> get tasks => _tasks;

  List<Task> _upcomingTasks = [];
  List<Task> get upcomingTasks => _upcomingTasks;

  List<AIRecommendation> _recommendations = [];
  List<AIRecommendation> get recommendations => _recommendations;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Constructor for dependency injection (for testing)
  HomeViewModel({
    GetTasksUseCase? getTasksUseCase,
    AddTaskUseCase? addTaskUseCase,
    ToggleTaskCompletionUseCase? toggleTaskCompletionUseCase,
    GetUpcomingTasksUseCase? getUpcomingTasksUseCase,
    DatabaseService? databaseService,
    AIService? aiService,
  }) : _getTasksUseCase = getTasksUseCase,
        _addTaskUseCase = addTaskUseCase,
        _toggleTaskCompletionUseCase = toggleTaskCompletionUseCase,
        _getUpcomingTasksUseCase = getUpcomingTasksUseCase,
        _databaseService = databaseService,
        _aiService = aiService {
    _loadInitialData();
  }

  // Note: Default instances are provided by the application's ServiceLocator.

  Future<void> _loadInitialData() async {
    await loadTasks();
  }

  Future<void> loadTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_databaseService != null) {
        // Fetch from database
        final dbTasks = await _databaseService!.getTasks();
        
        // Convert database maps to Task objects
        _tasks = [];
        for (var taskMap in dbTasks) {
          try {
            final task = Task(
              id: taskMap['id']?.toString(),
              title: taskMap['title'] ?? '',
              date: taskMap['dueDate'] != null 
                  ? DateTime.parse(taskMap['dueDate']) 
                  : DateTime.now(),
              description: taskMap['description'] ?? '',
              isCompleted: (taskMap['completed'] ?? 0) == 1,
              isImportant: (taskMap['important'] ?? 0) == 1,
              category: taskMap['category'] ?? 'Diğer',
            );
            _tasks.add(task);
          } catch (taskError) {
            // Skip invalid tasks
          }
        }
      } else if (_getTasksUseCase != null) {
        _tasks = await _getTasksUseCase!.execute();
      } else {
        // Fallback to mock data
        _tasks = _getMockTasks();
      }

      // Filter upcoming tasks - use simple filter for database tasks
      if (_databaseService != null) {
        // For database tasks, show all incomplete tasks sorted by date, limit to 3
        _upcomingTasks = _tasks
            .where((task) => !task.isCompleted)
            .toList()
            ..sort((a, b) => a.date.compareTo(b.date));
        
        // Limit to 3 closest tasks
        if (_upcomingTasks.length > 3) {
          _upcomingTasks = _upcomingTasks.sublist(0, 3);
        }
      } else if (_getUpcomingTasksUseCase != null) {
        _upcomingTasks = await _getUpcomingTasksUseCase!.execute();
      } else {
        _upcomingTasks = _tasks.where((task) => !task.isCompleted).toList();
      }

      await _loadRecommendations(notify: false);
    } catch (e) {
      _error = 'Görevler yüklenirken bir hata oluştu: $e';
      // Fallback to mock data on error
      _tasks = _getMockTasks();
      _upcomingTasks = _tasks.where((task) => !task.isCompleted).toList();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Task> _getMockTasks() {
    return [
      Task(
        title: 'Toplantı Hazırlığı',
        date: DateTime.now().add(const Duration(hours: 2)),
        description: 'Sunum slaytlarını tamamla',
        isCompleted: false,
        isImportant: true,
      ),
      Task(
        title: 'Market Alışverişi',
        date: DateTime.now().add(const Duration(days: 1)),
        description: 'Süt, ekmek, yumurta al',
        isCompleted: true,
        isImportant: false,
      ),
      Task(
        title: 'Spor Antrenmanı',
        date: DateTime.now().add(const Duration(days: 1, hours: 4)),
        description: 'Futbol antrenmanı - 19:00',
        isCompleted: false,
        isImportant: true,
      ),
    ];
  }

  Future<void> _loadRecommendations({bool notify = true}) async {
    try {
      if (_aiService != null) {
        _recommendations = await _aiService!.fetchRecommendations(_tasks);
      } else {
        _recommendations = _getMockRecommendations();
      }
    } catch (_) {
      _recommendations = _getMockRecommendations();
    }

    if (notify) {
      notifyListeners();
    }
  }

  List<AIRecommendation> _getMockRecommendations() {
    return [
      AIRecommendation(
        id: '1',
        title: 'Toplantıdan önce kahve molası ekle',
        description: '15 dakikalık bir mola verimliliği artırır',
        category: 'Verimlilik',
        icon: Icons.coffee,
        createdAt: DateTime.now(),
      ),
      AIRecommendation(
        id: '2',
        title: 'Market listesine meyve ekle',
        description: 'Sağlıklı atıştırmalıklar ekleyin',
        category: 'Sağlık',
        icon: Icons.apple,
        createdAt: DateTime.now(),
      ),
      AIRecommendation(
        id: '3',
        title: 'Spor çantasını hazırla',
        description: 'Antrenman için gerekli eşyaları hazırlayın',
        category: 'Hazırlık',
        icon: Icons.sports,
        createdAt: DateTime.now(),
      ),
    ];
  }

  int get pendingTasksCount =>
      _tasks.where((task) => !task.isCompleted).length;

  Future<void> addTask(Task task) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_addTaskUseCase != null) {
        await _addTaskUseCase!.execute(task);
      }
      await loadTasks(); // Refresh tasks
    } catch (e) {
      _error = 'Görev eklenirken bir hata oluştu: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleTaskCompletion(String taskId) async {
    try {
      // If a database is configured, delete the task directly from SQLite
      if (_databaseService != null) {
        final dbId = int.tryParse(taskId);
        if (dbId == null) {
          _error = 'Geçersiz görev kimliği';
          notifyListeners();
          return;
        }

        await _databaseService!.deleteTask(dbId);
        await loadTasks();
        return;
      }

      if (_toggleTaskCompletionUseCase != null) {
        await _toggleTaskCompletionUseCase!.execute(taskId);
      } else {
        // Fallback implementation
        final task = _tasks.firstWhere((t) => t.id == taskId);
        task.isCompleted = !task.isCompleted;
      }
      await loadTasks(); // Refresh tasks
    } catch (e) {
      _error = 'Görev durumu değiştirilirken bir hata oluştu: $e';
      notifyListeners();
    }
  }

  void applyRecommendation(String recommendationId) {
    final index = _recommendations.indexWhere((r) => r.id == recommendationId);
    if (index != -1) {
      _recommendations[index] =
          _recommendations[index].copyWith(isApplied: true);
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
