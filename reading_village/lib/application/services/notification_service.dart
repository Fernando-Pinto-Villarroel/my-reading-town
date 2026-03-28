import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static const int _dailyNotificationId = 1000;
  static const int _constructionBaseId = 2000;

  static const String _dailyChannelId = 'daily_reminder';
  static const String _dailyChannelName = 'Daily Reading Reminder';
  static const String _constructionChannelId = 'construction';
  static const String _constructionChannelName = 'Construction Updates';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  tz.TZDateTime _fromDeviceMs(int epochMs) =>
      tz.TZDateTime.fromMillisecondsSinceEpoch(tz.UTC, epochMs);

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  Future<void> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    await android.requestNotificationsPermission();
    await android.requestExactAlarmsPermission();
  }

  Future<void> scheduleDailyReminder({
    required String title,
    required String body,
  }) async {
    if (!_initialized) return;
    await _plugin.cancel(_dailyNotificationId);
    final random = Random();
    final hour = 7 + random.nextInt(16);
    final minute = random.nextInt(60);
    // DateTime.now() is device-local time — compute target in local time
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, hour, minute);
    if (!target.isAfter(now)) {
      target = target.add(const Duration(days: 1));
    }
    final scheduledDate = _fromDeviceMs(target.millisecondsSinceEpoch);
    await _plugin.zonedSchedule(
      _dailyNotificationId,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _dailyChannelId,
          _dailyChannelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleConstructionComplete({
    required int buildingId,
    required String buildingName,
    required Duration remaining,
    required String title,
    required String body,
  }) async {
    if (!_initialized) return;
    final notificationId = _constructionBaseId + buildingId;
    await _plugin.cancel(notificationId);
    if (remaining <= Duration.zero) return;
    // DateTime.now().add(remaining) is correct regardless of timezone
    final scheduledDate =
        _fromDeviceMs(DateTime.now().add(remaining).millisecondsSinceEpoch);
    await _plugin.zonedSchedule(
      notificationId,
      title,
      '$buildingName $body',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _constructionChannelId,
          _constructionChannelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelConstructionNotification(int buildingId) async {
    if (!_initialized) return;
    await _plugin.cancel(_constructionBaseId + buildingId);
  }
}
