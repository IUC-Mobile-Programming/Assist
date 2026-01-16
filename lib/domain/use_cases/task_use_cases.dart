import 'package:Assist/data/models/task.dart';
import 'package:Assist/data/repositories/task_repository.dart';
import 'package:Assist/services/notification_service.dart';

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
  final NotificationService notificationService;
  AddTaskUseCase(this.repository, this.notificationService);
  Future<String> execute(Task task) async {
    final String taskId = await repository.addTask(task);
    if (task.reminder != null && task.reminder!.isAfter(DateTime.now())) {
      await notificationService.scheduleNotification(
        id: taskId,
        scheduledAt: task.reminder!,
        title: task.title,
        body: task.description,
      );
    }
    return taskId;
  }
}

class UpdateTaskUseCase {
  final TaskRepository repository;
  final NotificationService notificationService;
  UpdateTaskUseCase(this.repository, this.notificationService);
  Future<void> execute(Task task) async {
    await repository.updateTask(task);
    await notificationService.cancelNotification(task.id);
    if (task.reminder != null && task.reminder!.isAfter(DateTime.now())) {
      await notificationService.scheduleNotification(
        id: task.id,
        scheduledAt: task.reminder!,
        title: task.title,
        body: task.description,
      );
    }
  }
}

class DeleteTaskUseCase {
  final TaskRepository repository;
  final NotificationService notificationService;
  DeleteTaskUseCase(this.repository, this.notificationService);
  Future<void> execute(String id) async {
    await repository.deleteTask(id);
    await notificationService.cancelNotification(id);
  }
}

class ToggleTaskCompletionUseCase {
  final TaskRepository repository;
  ToggleTaskCompletionUseCase(this.repository);
  Future<void> execute(String id) async {
    return await repository.toggleTaskCompletion(id);
  }
}