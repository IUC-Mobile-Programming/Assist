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
