/// Abstraction for scheduling and displaying notifications (local/remote).
abstract class NotificationService {
  Future<void> init();
  Future<void> scheduleNotification({required String id, required DateTime scheduledAt, required String title, String? body});
  Future<void> cancelNotification(String id);
}

/// A simple in-memory stub that doesn't schedule platform notifications.
class InMemoryNotificationService implements NotificationService {
  @override
  Future<void> init() async {
    // no-op for in-memory
  }

  @override
  Future<void> scheduleNotification({required String id, required DateTime scheduledAt, required String title, String? body}) async {
    // no-op stub
  }

  @override
  Future<void> cancelNotification(String id) async {
    // no-op stub
  }
}

