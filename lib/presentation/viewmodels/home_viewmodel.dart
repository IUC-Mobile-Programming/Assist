import 'package:flutter/material.dart';
import 'package:assist_ai/data/models/task.dart';
import 'package:assist_ai/data/models/ai_recommendation.dart';
import 'package:assist_ai/domain/use_cases/task_use_cases.dart';
import 'package:assist_ai/data/repositories/task_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final GetTasksUseCase? _getTasksUseCase;
  final AddTaskUseCase? _addTaskUseCase;
  final ToggleTaskCompletionUseCase? _toggleTaskCompletionUseCase;
  final GetUpcomingTasksUseCase? _getUpcomingTasksUseCase;

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
  }) : _getTasksUseCase = getTasksUseCase,
        _addTaskUseCase = addTaskUseCase,
        _toggleTaskCompletionUseCase = toggleTaskCompletionUseCase,
        _getUpcomingTasksUseCase = getUpcomingTasksUseCase {
    _loadInitialData();
  }

  // Factory method for creating a ViewModel with default dependencies
  factory HomeViewModel.create() {
    final taskRepository = TaskRepositoryImpl();
    return HomeViewModel(
      getTasksUseCase: GetTasksUseCase(taskRepository),
      addTaskUseCase: AddTaskUseCase(taskRepository),
      toggleTaskCompletionUseCase: ToggleTaskCompletionUseCase(taskRepository),
      getUpcomingTasksUseCase: GetUpcomingTasksUseCase(taskRepository),
    );
  }

  Future<void> _loadInitialData() async {
    await loadTasks();
    _loadRecommendations();
  }

  Future<void> loadTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_getTasksUseCase != null) {
        _tasks = await _getTasksUseCase!.execute();
      } else {
        // Fallback to mock data
        _tasks = _getMockTasks();
      }

      if (_getUpcomingTasksUseCase != null) {
        _upcomingTasks = await _getUpcomingTasksUseCase!.execute();
      } else {
        _upcomingTasks = _tasks.where((task) => !task.isCompleted).toList();
      }
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

  void _loadRecommendations() {
    _recommendations = [
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
    notifyListeners();
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