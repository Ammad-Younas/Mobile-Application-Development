import 'package:cloud_firestore/cloud_firestore.dart';
import 'local_notifications_service.dart';

class TestDriveReminderService {
  static final TestDriveReminderService _instance = TestDriveReminderService._internal();
  factory TestDriveReminderService() => _instance;
  TestDriveReminderService._internal();

  final LocalNotificationService _localNotifications = LocalNotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate unique notification ID for test drive reminders
  static int generateNotificationId(DateTime testDriveDateTime, String buyerUid) {
    return (testDriveDateTime.millisecondsSinceEpoch + buyerUid.hashCode) & 0x7FFFFFFF;
  }

  /// Schedule a test drive reminder notification 24 hours before the test drive
  Future<int> scheduleTestDriveReminder({
    required DateTime testDriveDateTime,
    required String carName,
    required String time,
    required String buyerUid,
    String? bookingId,
  }) async {
    try {
      final now = DateTime.now();
      
      // Calculate notification time (24 hours before)
      final reminderTime = testDriveDateTime.subtract(const Duration(hours: 24));
      
      // Only schedule if reminder time is in future
      if (reminderTime.isBefore(now)) {
        print('⚠️ Reminder time is in the past, not scheduling');
        return -1;
      }

      // Generate unique notification ID
      final notificationId = generateNotificationId(testDriveDateTime, buyerUid);

      // Schedule the notification
      final scheduledId = await _localNotifications.scheduleNotification(
        id: notificationId,
        scheduledTime: reminderTime,
        title: '⏰ Test Drive Reminder',
        body: 'You have a test drive for $carName tomorrow at $time',
        payload: 'test_drive_reminder',
      );

      if (scheduledId != -1) {
        print('✅ Test drive reminder scheduled for $reminderTime with ID: $scheduledId');
        
        // Store reminder notification in Firestore for the buyer
        await _firestore.collection('notifications').add({
          'userId': buyerUid,
          'title': '⏰ Test Drive Reminder',
          'message': 'You have a test drive for $carName tomorrow at $time',
          'type': 'test_drive_reminder',
          'isRead': false,
          'timestamp': Timestamp.fromDate(reminderTime),
          'data': {
            'carName': carName,
            'time': time,
            'testDriveDateTime': Timestamp.fromDate(testDriveDateTime),
            'notificationId': notificationId,
            'bookingId': bookingId ?? '',
          },
          'scheduled': true,
          'scheduledFor': Timestamp.fromDate(reminderTime),
        });
      }

      return scheduledId;
    } catch (e) {
      print('❌ Error scheduling test drive reminder: $e');
      return -1;
    }
  }

  /// Cancel a scheduled reminder notification
  Future<void> cancelReminder(int notificationId) async {
    try {
      await _localNotifications.cancelNotification(notificationId);
      print('✅ Cancelled reminder notification: $notificationId');
    } catch (e) {
      print('❌ Error cancelling reminder: $e');
    }
  }

  /// Cancel reminder by booking ID
  Future<void> cancelReminderByBookingId(String bookingId) async {
    try {
      // Find the notification with this booking ID
      final notifications = await _firestore
          .collection('notifications')
          .where('data.bookingId', isEqualTo: bookingId)
          .where('type', isEqualTo: 'test_drive_reminder')
          .get();

      for (var doc in notifications.docs) {
        final data = doc.data();
        final notificationId = data['data']?['notificationId'] as int?;
        
        if (notificationId != null) {
          await cancelReminder(notificationId);
        }
        
        // Delete the notification from Firestore
        await doc.reference.delete();
      }
      
      print('✅ Cancelled all reminders for booking: $bookingId');
    } catch (e) {
      print('❌ Error cancelling reminder by booking ID: $e');
    }
  }
}
