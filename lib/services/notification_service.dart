import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  // 1. Hàm khởi tạo hệ thống thông báo
  static Future<void> init() async {
    tz.initializeTimeZones();

    // Ép cấu hình múi giờ Việt Nam để tránh lỗi tz.local chưa được set trên máy ảo
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    } catch (e) {
      print("Lỗi cấu hình múi giờ: $e");
    }

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(settings: initializationSettings);
    await requestPermissions();
  }

  static Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  // 2. Hàm đặt lịch hẹn giờ bật thông báo công khai
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int secondsFromNow,
  }) async {
    await _notificationsPlugin.cancel(id: id);

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.now(tz.local).add(Duration(seconds: secondsFromNow)),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'homeplant_care',
          'Nhắc nhở chăm sóc cây',
          channelDescription: 'Thông báo nhắc lịch tưới nước bón phân',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // 3. Hàm hủy thông báo khi cây bị xóa khỏi vườn
  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }
}