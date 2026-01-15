import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications_linux/flutter_local_notifications_linux.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// Abstraction for scheduling and displaying notifications (local/remote).
abstract class NotificationService {
  Future<void> init();
  Future<void> scheduleNotification({required String id, required DateTime scheduledAt, required String title, String? body});
  Future<void> cancelNotification(String id);
}

class LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  Future<void> init() async {
    if (kIsWeb) {
      return;
    }
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    final LinuxInitializationSettings initializationSettingsLinux =
        const LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    if (defaultTargetPlatform == TargetPlatform.linux) {
      final linuxPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              LinuxFlutterLocalNotificationsPlugin>();
      await linuxPlugin?.initialize(
        initializationSettingsLinux,
        onDidReceiveNotificationResponse:
            (NotificationResponse response) async {
          // Handle notification tap
        },
      );
      return;
    }

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
      },
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.requestNotificationsPermission();
  }

  @override
  Future<void> scheduleNotification({
    required String id,
    required DateTime scheduledAt,
    required String title,
    String? body,
  }) async {
    // Generate a unique int ID from the string ID
    final int notificationId = id.hashCode;

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body ?? '',
        tz.TZDateTime.from(scheduledAt, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminders',
            'Task Reminders',
            channelDescription: 'Notifications for task reminders',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
          linux: LinuxNotificationDetails(
            timeout: LinuxNotificationTimeout.expiresNever(),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  @override
  Future<void> cancelNotification(String id) async {
    final int notificationId = id.hashCode;
    await flutterLocalNotificationsPlugin.cancel(notificationId);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
