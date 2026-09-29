import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class AlarmService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'goal_alarms';
  static const String _channelName = 'Goal Alarms';
  static const String _channelDescription = 'Daily reminders for your goals';
  Future<void> initialize() async {
    tz.initializeTimeZones();

    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    try {
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (e) {
      tz.setLocalLocation(tz.UTC);
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(settings: initializationSettings);

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
      ),
    );
  }

  Future<void> scheduleGoalAlarms({
    required String goalId,
    required String title,
    int? startTime,
    int? endTime,
    required bool startAlarmEnabled,
    required bool endAlarmEnabled,
  }) async {
    // Remove any old alarms first.
    await cancelGoalAlarms(goalId);

    if (startAlarmEnabled && startTime != null) {
      await _scheduleDailyAlarm(
        id: _startAlarmId(goalId),
        title: 'Time to start',
        body: 'It is time to work on "$title".',
        minutesFromMidnight: startTime,
      );
    }

    if (endAlarmEnabled && endTime != null) {
      await _scheduleDailyAlarm(
        id: _endAlarmId(goalId),
        title: 'Goal time is ending',
        body: 'Your scheduled time for "$title" is ending.',
        minutesFromMidnight: endTime,
      );
    }
  }

  Future<void> _scheduleDailyAlarm({
    required int id,
    required String title,
    required String body,
    required int minutesFromMidnight,
  }) async {
    final hour = minutesFromMidnight ~/ 60;
    final minute = minutesFromMidnight % 60;

    final now = tz.TZDateTime.now(tz.local);

    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Cancel both alarms belonging to a goal.
  Future<void> cancelGoalAlarms(String goalId) async {
    await _notifications.cancel(id: _startAlarmId(goalId));

    await _notifications.cancel(id: _endAlarmId(goalId));
  }

  /// Cancel only the start alarm.
  Future<void> cancelStartAlarm(String goalId) async {
    await _notifications.cancel(id: _startAlarmId(goalId));
  }

  /// Cancel only the end alarm.
  Future<void> cancelEndAlarm(String goalId) async {
    await _notifications.cancel(id: _endAlarmId(goalId));
  }

  /// Unique notification ID for the start alarm.
  int _startAlarmId(String goalId) {
    return '${goalId}_start'.hashCode;
  }

  /// Unique notification ID for the end alarm.
  int _endAlarmId(String goalId) {
    return '${goalId}_end'.hashCode;
  }
}
