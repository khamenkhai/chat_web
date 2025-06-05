import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chat_web/chat_service/models/message_models.dart' as types;
import 'package:chat_web/chat_service/service/chat_service.dart';

// Stream provider for messages
// final messagesStreamProvider = StreamProvider.autoDispose
//     .family<List<types.Message>, types.Room>((ref, room) {
//   return FyreChat.instance.messages(room,limit: 20);
// });

final messagesStreamProvider = StreamProvider.autoDispose
    .family<List<types.Message>, types.Room>((ref, room) {
  final limit = ref.watch(messageLimitProvider);
  return FyreChat.instance.messages(room, limit: limit);
});

// Change this from StateProvider to StateNotifierProvider
final messageLimitProvider = StateNotifierProvider<MessageLimitNotifier, int>(
  (ref) => MessageLimitNotifier(),
);
class MessageLimitNotifier extends StateNotifier<int> {
  MessageLimitNotifier() : super(20);

  void increaseLimit(int increment) {
    state += increment;
  }
}

// Provider for attachment uploading state
final attachmentUploadingProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});
// Provider for attachment uploading state
final imageUploadingProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});
