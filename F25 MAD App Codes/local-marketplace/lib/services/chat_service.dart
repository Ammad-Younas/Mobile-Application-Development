import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import 'notification_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Get or create chat room between two users
  Future<String> getOrCreateChatRoom(
      String currentUserId,
      String otherUserId,
      String currentUserName,
      String otherUserName,
      ) async {
    try {
      // Create a consistent chat ID (alphabetically sorted)
      final participants = [currentUserId, otherUserId]..sort();
      final chatId = participants.join('_');

      final chatDoc = await _firestore.collection('chats').doc(chatId).get();

      if (!chatDoc.exists) {
        // Create new chat room
        await _firestore.collection('chats').doc(chatId).set({
          'participants': participants,
          'participantDetails': {
            currentUserId: {'name': currentUserName},
            otherUserId: {'name': otherUserName},
          },
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unreadCount': {currentUserId: 0, otherUserId: 0},
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return chatId;
    } catch (e) {
      print('Error creating chat room: $e');
      rethrow;
    }
  }

  // Send a message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String text,
    String? imageUrl,
  }) async {
    try {
      // Add message to messages subcollection
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'chatId': chatId,
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'imageUrl': imageUrl,
      });

      // Update chat room's last message
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      final participants = List<String>.from(chatDoc.data()?['participants'] ?? []);

      // Increment unread count for the other user
      final otherUserId = participants.firstWhere((id) => id != senderId, orElse: () => '');
      if (otherUserId.isNotEmpty) {
        final currentUnreadCount = Map<String, dynamic>.from(chatDoc.data()?['unreadCount'] ?? {});
        currentUnreadCount[otherUserId] = (currentUnreadCount[otherUserId] ?? 0) + 1;

        await _firestore.collection('chats').doc(chatId).update({
          'lastMessage': text,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unreadCount': currentUnreadCount,
        });

        // Send notification to the receiver
        await _notificationService.notifyNewMessage(
          receiverUid: otherUserId,
          senderName: senderName,
          message: text,
          chatId: chatId,
        );
      }
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Get messages stream for a chat
  Stream<List<ChatMessage>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList();
    });
  }

  // ✅ Get user's chat rooms (client-side sorting to avoid composite index)
  // Note: We use client-side sorting instead of .orderBy() to avoid requiring
  // a composite index on [participants, lastMessageTime]. This is acceptable
  // for chat lists since they're typically not very large.
  Stream<List<ChatRoom>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      // Convert to ChatRoom objects
      final chatRooms = snapshot.docs
          .map((doc) => ChatRoom.fromFirestore(doc))
          .toList();

      // Sort client-side by lastMessageTime (descending)
      chatRooms.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

      return chatRooms;
    });
  }

  // Mark messages as read
  // Note: This query requires a composite index on [senderId, isRead]
  // Firebase will prompt you to create it when first used
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      final unreadCount = Map<String, dynamic>.from(chatDoc.data()?['unreadCount'] ?? {});
      unreadCount[userId] = 0;

      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount': unreadCount,
      });

      // Mark individual messages as read
      // REQUIRES INDEX: [senderId, isRead]
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Delete a chat
  Future<void> deleteChat(String chatId, String userId) async {
    try {
      // Delete all messages
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Delete chat room
      await _firestore.collection('chats').doc(chatId).delete();
    } catch (e) {
      print('Error deleting chat: $e');
      rethrow;
    }
  }
}