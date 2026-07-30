import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/check_in_settings.dart';

class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const int _baseCheckInId = 700;
  static const int _everyOtherDayWindow = 16;
  static const NotificationDetails _checkInDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'vitamind_check_ins',
      'Wellness check-ins',
      channelDescription: 'Gentle VitaMind daily wellness check-in reminders.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentSound: false,
      threadIdentifier: 'vitamind_check_ins',
    ),
    macOS: DarwinNotificationDetails(
      presentAlert: true,
      presentSound: false,
      threadIdentifier: 'vitamind_check_ins',
    ),
  );

  bool _initialized = false;
  bool _available = true;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tz_data.initializeTimeZones();
    await _setLocalTimeZone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _notifications.initialize(settings: initializationSettings);
      _available = true;
    } on Object catch (error) {
      debugPrint('VitaMind: notification plugin failed to initialize: $error');
      _available = false;
    }

    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    await initialize();

    if (!_available) {
      return false;
    }

    final androidGranted =
        await _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission() ??
        true;
    final iOSGranted =
        await _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: false, sound: false) ??
        true;
    final macOSGranted =
        await _notifications
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: false, sound: false) ??
        true;

    return androidGranted && iOSGranted && macOSGranted;
  }

  Future<void> applyCheckInSettings(CheckInSettings settings) async {
    await initialize();

    if (!_available) {
      return;
    }

    await _cancelCheckIns();

    if (!settings.enabled) {
      return;
    }

    final granted = await requestPermissions();
    if (!granted) {
      return;
    }

    switch (settings.frequency) {
      case CheckInFrequency.daily:
        try {
          await _scheduleRecurring(
            id: _baseCheckInId,
            date: _nextInstanceOfTime(settings.time),
            matchComponents: DateTimeComponents.time,
          );
        } on Object catch (error) {
          debugPrint('VitaMind: failed to schedule daily check-in: $error');
          _available = false;
        }
        break;
      case CheckInFrequency.everyOtherDay:
        try {
          await _scheduleEveryOtherDay(settings.time);
        } on Object catch (error) {
          debugPrint(
            'VitaMind: failed to schedule every-other-day check-in: $error',
          );
          _available = false;
        }
        break;
      case CheckInFrequency.weekly:
        try {
          await _scheduleRecurring(
            id: _baseCheckInId,
            date: _nextInstanceOfTime(settings.time),
            matchComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        } on Object catch (error) {
          debugPrint('VitaMind: failed to schedule weekly check-in: $error');
          _available = false;
        }
        break;
    }

    // TODO: Add Firebase Cloud Messaging later for opt-in cross-device reminders.
  }

  Future<void> cancelAllCheckIns() async {
    await initialize();

    if (!_available) {
      return;
    }

    await _cancelCheckIns();
  }

  Future<bool> showTestCheckIn() async {
    await initialize();

    if (!_available) {
      return false;
    }

    final granted = await requestPermissions();
    if (!granted) {
      return false;
    }

    try {
      await _notifications.show(
        id: _baseCheckInId + 99,
        title: 'VitaMind Check-In',
        body: 'How are you feeling today?',
        notificationDetails: _checkInDetails,
        payload: 'test_check_in',
      );
      return true;
    } on Object catch (error) {
      debugPrint('VitaMind: failed to show test check-in: $error');
      _available = false;
      return false;
    }
  }

  Future<void> _setLocalTimeZone() async {
    try {
      final timeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZone.identifier));
    } on Object catch (error) {
      debugPrint('VitaMind: failed to resolve local time zone: $error');
      tz.setLocalLocation(tz.UTC);
    }
  }

  Future<void> _cancelCheckIns() async {
    for (var index = 0; index <= _everyOtherDayWindow; index++) {
      await _notifications.cancel(id: _baseCheckInId + index);
    }
  }

  Future<void> _scheduleEveryOtherDay(TimeOfDay time) async {
    var date = _nextInstanceOfTime(time);
    for (var index = 0; index < _everyOtherDayWindow; index++) {
      await _scheduleRecurring(id: _baseCheckInId + index, date: date);
      date = tz.TZDateTime(
        tz.local,
        date.year,
        date.month,
        date.day + 2,
        time.hour,
        time.minute,
      );
    }
  }

  Future<void> _scheduleRecurring({
    required int id,
    required tz.TZDateTime date,
    DateTimeComponents? matchComponents,
  }) async {
    await _notifications.zonedSchedule(
      id: id,
      title: 'VitaMind Check-In',
      body: 'How are you feeling today?',
      scheduledDate: date,
      notificationDetails: _checkInDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: matchComponents,
      payload: 'check_in',
    );
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }
}
