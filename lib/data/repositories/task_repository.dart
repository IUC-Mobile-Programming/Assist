import 'package:Assist/data/models/task.dart';

abstract class TaskRepository {
  Future<List<Task>> getTasks();
  Future<List<Task>> getUpcomingTasks();
  Future<List<Task>> getCompletedTasks();
  Future<List<Task>> getImportantTasks();
  Future<Task> getTaskById(String id);
  Future<String> addTask(Task task);
  Future<void> updateTask(Task task);
  Future<void> deleteTask(String id);
  Future<void> toggleTaskCompletion(String id);
}

class TaskRepositoryImpl implements TaskRepository {
  final List<Task> _tasks = [
    Task(
      title: 'Toplantı Hazırlığı',
      date: DateTime.now().add(const Duration(hours: 2)),
      description: 'Sunum slaytlarını tamamla',
      isImportant: true,
    ),
    Task(
      title: 'Market Alışverişi',
      date: DateTime.now().add(const Duration(days: 1)),
      description: 'Süt, ekmek, yumurta al',
      isCompleted: true,
    ),
    Task(
      title: 'Spor Antrenmanı',
      date: DateTime.now().add(const Duration(days: 1, hours: 4)),
      description: 'Futbol antrenmanı - 19:00',
      isImportant: true,
    ),
  ];

  @override
  Future<List<Task>> getTasks() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    return List.from(_tasks);
  }

  @override
  Future<List<Task>> getUpcomingTasks() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    return _tasks
        .where((task) => !task.isCompleted && task.date.isAfter(now))
        .toList();
  }

  @override
  Future<List<Task>> getCompletedTasks() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _tasks.where((task) => task.isCompleted).toList();
  }

  @override
  Future<List<Task>> getImportantTasks() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _tasks.where((task) => task.isImportant).toList();
  }

  @override
  Future<Task> getTaskById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final task = _tasks.firstWhere((task) => task.id == id);
    return task.copyWith();
  }

  @override
  Future<String> addTask(Task task) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _tasks.add(task);
    return task.id;
  }

  @override
  Future<void> updateTask(Task task) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task.copyWith(updatedAt: DateTime.now());
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _tasks.removeWhere((task) => task.id == id);
  }

  @override
  Future<void> toggleTaskCompletion(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final task = await getTaskById(id);
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    await updateTask(updatedTask);
  }
}