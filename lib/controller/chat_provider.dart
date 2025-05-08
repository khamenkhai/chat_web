import 'package:chat_web/fire_chat/service/chat_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chat_web/fire_chat/models/message_models.dart' as types;

// Stream provider for messages
final messagesStreamProvider = StreamProvider.autoDispose
    .family<List<types.Message>, types.Room>((ref, room) {
  return FireChat.instance.messages(room);
});

// Provider for attachment uploading state
final attachmentUploadingProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});
// Provider for attachment uploading state
final imageUploadingProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});
