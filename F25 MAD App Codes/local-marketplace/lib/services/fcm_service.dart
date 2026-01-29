import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'local_notifications_service.dart';

/// Handle background FCM messages (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📩 Background message received: ${message.notification?.title}');
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalNotificationService _localNotifications = LocalNotificationService();

  String? _fcmToken;

  /// Initialize FCM
  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ FCM permission granted');

      // Get FCM token
      _fcmToken = await _fcm.getToken();
      print('📱 FCM Token: $_fcmToken');

      // Save token to Firestore for current user
      await _saveFCMToken(_fcmToken);

      // Listen for token refresh
      _fcm.onTokenRefresh.listen(_saveFCMToken);

      // Setup message handlers
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      _setupForegroundHandler();
      _setupMessageOpenedHandler();
    } else {
      print('❌ FCM permission denied');
    }
  }

  /// Save FCM token to user document
  Future<void> _saveFCMToken(String? token) async {
    if (token == null) return;

    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('✅ FCM token saved for user: ${user.uid}');
    }
  }

  /// Handle foreground messages
  void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Foreground message received: ${message.notification?.title}');

      // Show local notification
      if (message.notification != null) {
        _localNotifications.showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: message.notification!.title ?? 'Notification',
          body: message.notification!.body ?? '',
          payload: message.data['type'] ?? 'general',
        );
      }
    });
  }

  /// Handle notification tap when app is in background/terminated
  void _setupMessageOpenedHandler() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📩 Notification tapped: ${message.data}');
      // Handle navigation based on notification type
      _handleNotificationNavigation(message.data);
    });

    // Handle initial message (when app is opened from terminated state)
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('📩 App opened from notification: ${message.data}');
        _handleNotificationNavigation(message.data);
      }
    });
  }

  /// Navigate to appropriate screen based on notification type
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'];
    // Navigation logic will be implemented in main app with GlobalKey<NavigatorState>
    print('🔔 Navigate to: $type with data: $data');
  }

  /// Send FCM notification to specific user
  Future<void> sendFCMToUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, String>? additionalData,
  }) async {
    try {
      // Get user's FCM token from Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken == null) {
        print('⚠️ No FCM token found for user: $userId');
        return;
      }

      // In production, use Firebase Cloud Functions to send FCM
      // For now, we'll store the notification in Firestore
      // and let Cloud Functions handle the actual FCM push
      await _firestore.collection('fcm_queue').add({
        'token': fcmToken,
        'notification': {
          'title': title,
          'body': body,
        },
        'data': {
          'type': type,
          ...?additionalData,
        },
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      print('✅ FCM queued for user: $userId');
    } catch (e) {
      print('❌ Error sending FCM: $e');
    }
  }

  /// Clear FCM token on logout
  Future<void> clearToken() async {
    await _fcm.deleteToken();
    _fcmToken = null;

    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': FieldValue.delete(),
      });
    }
  }
}
