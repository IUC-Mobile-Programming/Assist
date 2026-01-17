import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications_linux/flutter_local_notifications_linux.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

abstract class NotificationService {
  Future<void> init();
  Future<void> scheduleNotification({
    required String id,
    required DateTime scheduledAt,
    required String title,
    String? body,
  });
  Future<void> cancelNotification(String id);
  Future<void> cancelAllNotifications();
}

class LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  @override
  Future<void> init() async {
    if (kIsWeb) return;

    tz.initializeTimeZones();

    try {
      // Paket ismi 'plus' olsa da sınıf ismi 'FlutterTimezone' olarak kalmış olabilir
      final String? timeZoneName = await FlutterTimezone.getLocalTimezone();
      if (timeZoneName != null) {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      }
    } catch (e) {
      debugPrint("Timezone hatası: $e");
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      linux: linuxSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint("Bildirime tıklandı: ${details.payload}");
      },
    );

    if (Platform.isAndroid) {
      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  @override
  Future<void> scheduleNotification({
    required String id,
    required DateTime scheduledAt,
    required String title,
    String? body,
  }) async {
    if (scheduledAt.isBefore(DateTime.now())) return;

    final int notificationId = id.hashCode.abs();

    await _notifications.zonedSchedule(
      notificationId,
      title,
      body ?? '',
      tz.TZDateTime.from(scheduledAt, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'assist_channel',
          'Görev Hatırlatıcıları',
          channelDescription: 'Görevleriniz için zamanlanmış bildirimler',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  @override
  Future<void> cancelNotification(String id) async {
    await _notifications.cancel(id.hashCode.abs());
  }

  @override
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
