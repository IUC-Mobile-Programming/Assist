import 'package:assist_ai/data/models/task.dart';
import 'package:assist_ai/data/repositories/task_repository.dart';

class GetTasksUseCase {
  final TaskRepository repository;

  GetTasksUseCase(this.repository);

  Future<List<Task>> execute() async {
    return await repository.getTasks();
  }
}

class GetUpcomingTasksUseCase {
  final TaskRepository repository;

  GetUpcomingTasksUseCase(this.repository);

  Future<List<Task>> execute() async {
    return await repository.getUpcomingTasks();
  }
}

class GetCompletedTasksUseCase {
  final TaskRepository repository;

  GetCompletedTasksUseCase(this.repository);

  Future<List<Task>> execute() async {
    return await repository.getCompletedTasks();
  }
}

class GetImportantTasksUseCase {
  final TaskRepository repository;

  GetImportantTasksUseCase(this.repository);

  Future<List<Task>> execute() async {
    return await repository.getImportantTasks();
  }
}

class GetTaskByIdUseCase {
  final TaskRepository repository;

  GetTaskByIdUseCase(this.repository);

  Future<Task> execute(String id) async {
    return await repository.getTaskById(id);
  }
}

class AddTaskUseCase {
  final TaskRepository repository;

  AddTaskUseCase(this.repository);

  Future<String> execute(Task task) async {
    return await repository.addTask(task);
  }
}

class UpdateTaskUseCase {
  final TaskRepository repository;

  UpdateTaskUseCase(this.repository);

  Future<void> execute(Task task) async {
    return await repository.updateTask(task);
  }
}

class DeleteTaskUseCase {
  final TaskRepository repository;

  DeleteTaskUseCase(this.repository);

  Future<void> execute(String id) async {
    return await repository.deleteTask(id);
  }
}

class ToggleTaskCompletionUseCase {
  final TaskRepository repository;

  ToggleTaskCompletionUseCase(this.repository);

  Future<void> execute(String id) async {
    return await repository.toggleTaskCompletion(id);
  }
}