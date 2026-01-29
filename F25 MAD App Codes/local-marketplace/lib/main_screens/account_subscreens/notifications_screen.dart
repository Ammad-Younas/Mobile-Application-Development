import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'chatdetails_screen.dart';
import 'booked_cars.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create test notifications
  Future<void> _createTestNotification() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final testNotifications = [
      {
        'userId': currentUser. uid,
        'title': 'New Message',
        'message': 'You have a new message from John about the car listing',
        'type': 'message',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      },
      {
        'userId': currentUser.uid,
        'title': 'Someone liked your car! ',
        'message': 'Your Toyota Camry 2020 was added to favorites',
        'type': 'favorite',
        'isRead': false,
        'timestamp': FieldValue. serverTimestamp(),
      },
      {
        'userId': currentUser.uid,
        'title': 'New Car Listing',
        'message': 'A new Honda Civic 2021 matches your search criteria',
        'type': 'car_listing',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      },
      {
        'userId': currentUser.uid,
        'title': 'System Update',
        'message': 'GetCars app has been updated with new features!',
        'type': 'system',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      },
    ];

    try {
      for (var notification in testNotifications) {
        await _firestore.collection('notifications').add(notification);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test notifications created!'),
            backgroundColor: Colors. green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error creating test notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context). showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _firestore. collection('notifications').doc(notificationId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete notification'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // REQUIRES INDEX: [userId, isRead]
      // Firebase will prompt you to create it when first used
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  void _handleNotificationTap(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'message':
        // Navigate to ChatDetailScreen
        final chatId = data['chatId'] as String?;
        final senderName = data['senderName'] as String? ?? 'User';
        final senderId = data['senderId'] as String?;
        
        if (chatId != null && senderId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(
                chatId: chatId,
                otherUserId: senderId,
                name: senderName,
                avatarColor: Colors.blue,
              ),
            ),
          );
        }
        break;
      
      case 'test_drive_booking':
      case 'test_drive_reminder':
        // Navigate to BookedCarsScreen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BookedCarsScreen(),
          ),
        );
        break;
      
      default:
        // For other notification types, just mark as read
        break;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'message':
        return Icons.message;
      case 'favorite':
        return Icons.favorite;
      case 'car_listing':
        return Icons.directions_car;
      case 'test_drive_booking':
        return Icons.event_available;
      case 'test_drive_reminder':
        return Icons.alarm;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'message':
        return Colors.blue;
      case 'favorite':
        return Colors.red;
      case 'car_listing':
        return Colors.green;
      case 'test_drive_booking':
        return Colors.blue;
      case 'test_drive_reminder':
        return Colors.orange;
      case 'system':
        return Colors.orange;
      default:
        return const Color(0xFF1E3A5F);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFE8C87C),
      floatingActionButton: FloatingActionButton(
        onPressed: _createTestNotification,
        backgroundColor: const Color(0xFF1E3A5F),
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Create Test Notifications',
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A5F),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'GC',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE8C87C),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      // Mark all as read button
                      IconButton(
                        icon: const Icon(
                          Icons.done_all,
                          color: Color(0xFF1E3A5F),
                        ),
                        tooltip: 'Mark all as read',
                        onPressed: _markAllAsRead,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.menu,
                          color: Color(0xFF1E3A5F),
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Notifications Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A5F),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.notifications,
                  color: Colors.orange[700],
                  size: 28,
                ),
              ],
            ),
            const SizedBox(height: 30),
            // Notifications List with Real-time Updates
            Expanded(
              child: currentUser == null
                  ? const Center(
                child: Text(
                  'Please log in to view notifications',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1E3A5F),
                  ),
                ),
              )
                  : StreamBuilder<QuerySnapshot>(
                // REQUIRES INDEX: [userId, timestamp DESC]
                // Firebase will automatically prompt you to create it when first used
                stream: _firestore
                    .collection('notifications')
                    .where('userId', isEqualTo: currentUser.uid)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 60,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF1E3A5F),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Try creating the Firestore index',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1E3A5F),
                      ),
                    );
                  }

                  final notifications = snapshot. data?. docs ?? [];

                  if (notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the + button to create test notifications',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView. builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notificationData = notifications[index]
                          . data() as Map<String, dynamic>;
                      final notificationId = notifications[index].id;
                      final title =
                          notificationData['title'] ?? 'Notification';
                      final message = notificationData['message'] ?? '';
                      final type = notificationData['type'] ?? 'general';
                      final isRead = notificationData['isRead'] ??  false;
                      final timestamp =
                      notificationData['timestamp'] as Timestamp? ;
                      final data = notificationData['data'] as Map<String, dynamic>? ?? {};

                      String timeAgo = '';
                      if (timestamp != null) {
                        timeAgo = timeago.format(timestamp.toDate());
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Dismissible(
                          key: Key(notificationId),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Icon(
                              Icons. delete,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          onDismissed: (direction) {
                            _deleteNotification(notificationId);
                          },
                          child: _buildNotificationItem(
                            notificationId,
                            title,
                            message,
                            type,
                            isRead,
                            timeAgo,
                            data,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
      String notificationId,
      String title,
      String message,
      String type,
      bool isRead,
      String timeAgo,
      Map<String, dynamic> data,
      ) {
    return InkWell(
        onTap: () {
          if (!isRead) {
            _markAsRead(notificationId);
          }
          // Navigate based on notification type
          _handleNotificationTap(type, data);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isRead
                ? const Color(0xFF1E3A5F).withOpacity(0.7)
                : const Color(0xFF1E3A5F),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
              ),
            ],
          ),
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          // Icon
          Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _getNotificationColor(type),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getNotificationIcon(type),
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        // Content
        Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight. bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (! isRead)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            if (message.isNotEmpty) ...[
        const SizedBox(height: 6),
    Text(
    message,
    style: TextStyle(
    fontSize: 14,
    color: Colors.white.withOpacity(0.9),
    ),
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    ),
    ],
    if (timeAgo.isNotEmpty) ...[
    const SizedBox(height: 6),
    Text(
    timeAgo,
    style: TextStyle(
    fontSize: 12,
    color: Colors.white.withOpacity(0.6),
    ),
    ),
    ],
    ],
    ),
    ),
    ],
    ),
    ),
    );
  }
}