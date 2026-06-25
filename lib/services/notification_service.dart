import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';
import 'package:tracker/main.dart';
import 'package:tracker/screens/add_log_screen.dart';


class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();
  

  static Future<void> init() async {
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload == 'ADD_LOG') {
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => const AddLogScreen()),
          );
        }
      },
    );
  }

  static Future<void> dailyReminder({
    required int id,
    required int hour,
    required int minute,
    required String body,
    required String title,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      _nextTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          '_daily_channel',
          'Daily Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime _nextTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
