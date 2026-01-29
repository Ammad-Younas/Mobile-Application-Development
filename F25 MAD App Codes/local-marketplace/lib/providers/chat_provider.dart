import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../services/chat_service.dart';
import 'auth_provider.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

// Stream of user's chat rooms
final userChatsProvider = StreamProvider<List<ChatRoom>>((ref) {
  final currentUser = ref.watch(authStateProvider).value;
  if (currentUser == null) {
    return Stream.value([]);
  }

  final chatService = ref.watch(chatServiceProvider);
  return chatService.getUserChats(currentUser.uid);
});

// Stream of messages for a specific chat
final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((ref, chatId) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.getMessages(chatId);
});