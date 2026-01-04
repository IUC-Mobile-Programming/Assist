import 'package:flutter_test/flutter_test.dart';
import 'package:Assist/presentation/viewmodels/home_viewmodel.dart';
import 'package:Assist/domain/use_cases/task_use_cases.dart';
import 'package:Assist/data/models/task.dart';
import 'package:Assist/data/repositories/task_repository.dart';

class FakeTaskRepository implements TaskRepository {
  @override
  Future<List<Task>> getTasks() async => [
        Task(
          title: 'Test Task',
          date: DateTime.now(),
          description: 'A task for testing',
        )
      ];

  @override
  Future<List<Task>> getUpcomingTasks() async => await getTasks();
  @override
  Future<List<Task>> getCompletedTasks() async => [];
  @override
  Future<List<Task>> getImportantTasks() async => [];
  @override
  Future<Task> getTaskById(String id) async => (await getTasks()).first;
  @override
  Future<String> addTask(Task task) async => task.id;
  @override
  Future<void> updateTask(Task task) async {}
  @override
  Future<void> deleteTask(String id) async {}
  @override
  Future<void> toggleTaskCompletion(String id) async {}
}

void main() {
  test('HomeViewModel.loadTasks populates tasks', () async {
    final getTasksUseCase = GetTasksUseCase(FakeTaskRepository());
    final vm = HomeViewModel(getTasksUseCase: getTasksUseCase);

    // Wait for initial load (HomeViewModel triggers _loadInitialData in constructor)
    await Future.delayed(const Duration(milliseconds: 600));

    expect(vm.tasks.isNotEmpty, true);
    expect(vm.tasks.first.title, 'Test Task');
  });
}
