import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:android_intent_plus/android_intent.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(initSettings);

    await _configureLocalTimeZone();
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
      'pawplan_default','General', description: 'General', importance: Importance.max,
    ));
    await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
      'pawplan_sched_v2','Scheduled', description: 'Task reminders', importance: Importance.max,
    ));
  }

  static Future<void> requestPermissions() async {
    final Object? androidImpl =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null && Platform.isAndroid) {
      final dynamic d = androidImpl;
      try {
        await d.requestNotificationsPermission();
      } catch (_) {
        try {
          await d.requestPermission();
        } catch (_) {}
      }
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'pawplan_default',
          'General',
          channelDescription: 'General notifications',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // ใช้ช่องใหม่ + whileIdle + ยกเลิกคิวเดิมก่อนตั้ง
  static Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
  }) async {
    final now = DateTime.now();
    final safeTime = dateTime.isAfter(now.add(const Duration(seconds: 1)))
        ? dateTime
        : now.add(const Duration(seconds: 3));

    final tzTime = tz.TZDateTime.from(safeTime, tz.local);

    debugPrint('[notif] scheduleAt tz=${tz.local.name} at $tzTime (now=$now)');

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'pawplan_sched_v2',
          'Scheduled',
          channelDescription: 'Task reminders',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'scheduled',
    );

    final pending = await _plugin.pendingNotificationRequests();
    debugPrint('[notif] pending=${pending.map((e) => '${e.id}:${e.title}').toList()}');
  }

  static Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    try {
      final dynamic tzInfo = await FlutterTimezone.getLocalTimezone();
      final String currentTz = tzInfo is String 
          ? tzInfo 
          : (tzInfo?.name ?? tzInfo?.timezone ?? tzInfo?.timeZone ?? 'Asia/Bangkok');
      tz.setLocalLocation(tz.getLocation(currentTz));
      // ignore: avoid_print
      print('[notif] tz local set to $currentTz');
    } catch (e) {
      // ignore: avoid_print
      print('[notif] tz fallback to Asia/Bangkok ($e)');
      tz.setLocalLocation(tz.getLocation('Asia/Bangkok'));
    }
  }

  static Future<Map<String, dynamic>> debugStatus() async {
    final status = <String, dynamic>{};
    status['tzLocal'] = tz.local.name;
    status['now'] = DateTime.now().toString();
    return status;
  }

  static Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  static Future<void> openExactAlarmSettings() async {
    if (!Platform.isAndroid) return;
    const packageName = 'com.example.pawplan'; // ⚠️ เปลี่ยนให้ตรงกับโปรเจกต์
    final intent = AndroidIntent(
      action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
      data: 'package:$packageName',
    );
    try {
      await intent.launch();
    } catch (e) {
      final fallback = AndroidIntent(
        action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
        data: 'package:$packageName',
      );
      await fallback.launch();
      // ignore: avoid_print
      print('[notif] openExactAlarmSettings fallback: $e');
    }
  }

  static int notificationIdFrom(String key) => key.hashCode & 0x7fffffff;

  static Future<void> scheduleTask({
    required String taskId,
    required String title,
    required DateTime when,
  }) async {
    await scheduleAt(
      id: notificationIdFrom(taskId),
      title: 'Task reminder',
      body: title,
      dateTime: when,
    );
  }
}


