import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'local_notifications_service.dart';
import 'fcm_service.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalNotificationService _localNotifications = LocalNotificationService();
  final FCMService _fcmService = FCMService();

  /// Send notification to Firestore AND send FCM push notification
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
    bool showLocal = true,
  }) async {
    try {
      // Save to Firestore
      await _firestore.collection('notifications').add({
        'userId':  userId,
        'title': title,
        'message': message,
        'type': type,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
        'data': data ??  {},
      });

      // ✅ Send FCM to user's device (works across devices)
      await _fcmService.sendFCMToUser(
        userId: userId,
        title: title,
        body: message,
        type: type,
        additionalData: data?.map((key, value) => MapEntry(key, value.toString())),
      );

      print('✅ Notification sent to Firestore and FCM: $title');
    } catch (e) {
      print('❌ Error sending notification: $e');
    }
  }

  /// Notify seller when someone favorites their car
  Future<void> notifyCarFavorited({
    required String carId,
    required String carName,
    required String sellerUid,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid == sellerUid) return;

    final userName = currentUser.displayName ?? 'Someone';

    await sendNotification(
      userId:  sellerUid,
      title: '❤️ Someone liked your car!',
      message:  '$userName added your $carName to favorites',
      type: 'favorite',
      data: {
        'carId': carId,
        'carName': carName,
        'favoritedBy': currentUser.uid,
      },
    );
  }

  /// Notify seller when someone books a test drive
  Future<void> notifyTestDriveBooked({
    required String carId,
    required String carName,
    required String sellerUid,
    required String buyerName,
    required String date,
    required String time,
    String? bookingId,
  }) async {
    await sendNotification(
      userId: sellerUid,
      title: '🚗 New Test Drive Booking!',
      message: '$buyerName booked a test drive for $carName on $date at $time',
      type: 'test_drive_booking',
      data: {
        'carId': carId,
        'carName': carName,
        'buyerName': buyerName,
        'date': date,
        'time': time,
        'bookingId': bookingId ?? '',
      },
    );
  }

  /// Notify seller when someone starts a chat
  Future<void> notifyNewMessage({
    required String receiverUid,
    required String senderName,
    required String message,
    required String chatId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid == receiverUid) return;

    await sendNotification(
      userId: receiverUid,
      title: '💬 New message from $senderName',
      message: message.length > 50 ? '${message.substring(0, 50)}...' : message,
      type: 'message',
      data: {
        'chatId': chatId,
        'senderId': currentUser.uid,
        'senderName': senderName,
      },
    );
  }

  /// Notify when car is sold
  Future<void> notifyCarSold({
    required String carId,
    required String carName,
    required String buyerName,
    required String sellerUid,
  }) async {
    await sendNotification(
      userId:  sellerUid,
      title: '🎉 Your car was sold!',
      message:  'Congratulations! Your $carName was sold to $buyerName',
      type: 'sale',
      data: {
        'carId': carId,
        'carName': carName,
        'buyerName':  buyerName,
      },
    );
  }

  /// Notify when new car is listed
  Future<void> notifyNewCarListing({
    required String carName,
    required String carId,
    required String location,
  }) async {
    // This would be sent to interested users
    // For demo, we'll just show local notification
    await _localNotifications.notifyNewCarListing(
      carName: carName,
      location: location,
    );
  }

  /// Notify when price is reduced
  Future<void> notifyPriceReduced({
    required String carId,
    required String carName,
    required String oldPrice,
    required String newPrice,
    required List<String> interestedUserIds,
  }) async {
    for (var userId in interestedUserIds) {
      await sendNotification(
        userId: userId,
        title: '💰 Price reduced!',
        message: '$carName price reduced from $oldPrice to $newPrice',
        type: 'price_drop',
        data: {
          'carId': carId,
          'carName': carName,
          'oldPrice':  oldPrice,
          'newPrice': newPrice,
        },
      );
    }
  }
}