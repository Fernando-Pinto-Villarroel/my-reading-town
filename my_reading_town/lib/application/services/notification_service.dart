import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static const int _dailyBaseId = 1000;
  static const int _maxDailySlots = 70;
  static const int _constructionBaseId = 2000;

  static const String _dailyChannelId = 'daily_reminder';
  static const String _dailyChannelName = 'Daily Reading Reminder';
  static const String _constructionChannelId = 'construction';
  static const String _constructionChannelName = 'Construction Updates';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  tz.TZDateTime _fromDeviceMs(int epochMs) =>
      tz.TZDateTime.fromMillisecondsSinceEpoch(tz.local, epochMs);

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.local);
    } catch (_) {}
    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings: initSettings);
    _initialized = true;
  }

  Future<void> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    await android.requestNotificationsPermission();
    await android.requestExactAlarmsPermission();
  }

  Future<void> cancelAllDailyReminders() async {
    if (!_initialized) return;
    for (int i = _dailyBaseId; i < _dailyBaseId + _maxDailySlots; i++) {
      await _plugin.cancel(id: i);
    }
  }

  Future<void> scheduleNotifications({
    required List<bool> activeDays,
    required int startHour,
    required int endHour,
    required int notificationsPerDay,
    required List<Map<String, String>> messages,
  }) async {
    if (!_initialized) return;
    await cancelAllDailyReminders();

    if (messages.isEmpty) return;
    final range = endHour - startHour;
    if (range <= 0) return;

    final random = Random();
    final now = DateTime.now();
    int notifId = _dailyBaseId;

    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      if (notifId >= _dailyBaseId + _maxDailySlots) break;
      final targetDay = now.add(Duration(days: dayOffset));
      final dayIndex = targetDay.weekday - 1;
      if (dayIndex < 0 || dayIndex >= activeDays.length) continue;
      if (!activeDays[dayIndex]) continue;

      for (int n = 0; n < notificationsPerDay; n++) {
        if (notifId >= _dailyBaseId + _maxDailySlots) break;
        final randomHour = startHour + random.nextInt(range);
        final randomMinute = random.nextInt(60);

        final target = DateTime(
          targetDay.year,
          targetDay.month,
          targetDay.day,
          randomHour,
          randomMinute,
        );

        if (!target.isAfter(now)) continue;

        final msgIndex = random.nextInt(messages.length);
        final msg = messages[msgIndex];

        final scheduledDate = _fromDeviceMs(target.millisecondsSinceEpoch);
        await _plugin.zonedSchedule(
          id: notifId++,
          title: msg['title'] ?? '',
          body: msg['body'] ?? '',
          scheduledDate: scheduledDate,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _dailyChannelId,
              _dailyChannelName,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/launcher_icon',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    }
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
    await _plugin.cancel(id: notificationId);
    if (remaining <= Duration.zero) return;
    final scheduledDate =
        _fromDeviceMs(DateTime.now().add(remaining).millisecondsSinceEpoch);
    await _plugin.zonedSchedule(
      id: notificationId,
      title: title,
      body: '$buildingName $body',
      scheduledDate: scheduledDate,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _constructionChannelId,
          _constructionChannelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelConstructionNotification(int buildingId) async {
    if (!_initialized) return;
    await _plugin.cancel(id: _constructionBaseId + buildingId);
  }
}
