import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone database
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission:  true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for Android 13+
    await _requestPermissions();

    _initialized = true;
    print('✅ Local notifications initialized');
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // You can navigate to specific screens based on payload
  }

  /// Show a basic notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'getcars_channel',
      'Get Cars Notifications',
      channelDescription: 'Notifications for Get Cars app',
      importance:  Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF1E3A5F),
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS:  iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  /// Show notification for car favorited
  Future<void> notifyCarFavorited({
    required String carName,
    required String userName,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '❤️ Someone liked your car!',
      body:  '$userName added your $carName to favorites',
      payload: 'favorite',
    );
  }

  /// Show notification for test drive booked
  Future<void> notifyTestDriveBooked({
    required String carName,
    required String buyerName,
    required String date,
    required String time,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '🚗 New Test Drive Booking!',
      body: '$buyerName booked a test drive for $carName on $date at $time',
      payload: 'test_drive',
    );
  }

  /// Show notification for new message
  Future<void> notifyNewMessage({
    required String senderName,
    required String message,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title:  '💬 New message from $senderName',
      body: message. length > 50 ? '${message.substring(0, 50)}...' : message,
      payload: 'message',
    );
  }

  /// Show notification for car sold
  Future<void> notifyCarSold({
    required String carName,
    required String buyerName,
  }) async {
    await showNotification(
      id: DateTime. now().millisecondsSinceEpoch ~/ 1000,
      title: '🎉 Your car was sold!',
      body: 'Congratulations! Your $carName was sold to $buyerName',
      payload: 'sale',
    );
  }

  /// Show notification for new car listing
  Future<void> notifyNewCarListing({
    required String carName,
    required String location,
  }) async {
    await showNotification(
      id: DateTime. now().millisecondsSinceEpoch ~/ 1000,
      title: '🚘 New car available! ',
      body: 'A new $carName is now available in $location',
      payload: 'new_listing',
    );
  }

  /// Show notification for price drop
  Future<void> notifyPriceDrop({
    required String carName,
    required String oldPrice,
    required String newPrice,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '💰 Price reduced!',
      body: '$carName price dropped from $oldPrice to $newPrice',
      payload: 'price_drop',
    );
  }

  /// Show immediate notification for test drive reminder
  /// Note: This is for immediate reminders, not scheduled ones.
  /// For scheduled reminders, use TestDriveReminderService instead.
  Future<void> notifyTestDriveReminder({
    required String carName,
    required String time,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: '⏰ Test Drive Reminder',
      body: 'You have a test drive for $carName tomorrow at $time',
      payload: 'test_drive_reminder',
    );
  }

  /// Schedule a notification for future delivery
  Future<int> scheduleNotification({
    required int id,
    required DateTime scheduledTime,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'getcars_channel',
      'Get Cars Notifications',
      channelDescription: 'Notifications for Get Cars app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF1E3A5F),
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      try {
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          tz.TZDateTime.from(scheduledTime, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          // uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
        print('✅ Notification scheduled for $scheduledTime with ID: $id');
        return id;
      } catch (e) {
        print('❌ Error scheduling notification: $e');
        return -1;
      }
      print('✅ Notification scheduled for $scheduledTime with ID: $id');
      return id;
    } catch (e) {
      print('❌ Error scheduling notification: $e');
      return -1;
    }
  }

  /// Cancel a notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}