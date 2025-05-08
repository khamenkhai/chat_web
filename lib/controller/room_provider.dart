// Stream provider for room updates
import 'package:chat_web/fire_chat/service/chat_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chat_web/fire_chat/models/message_models.dart' as types;

final roomStreamProvider =
    StreamProvider.autoDispose.family<types.Room, String>((ref, roomId) {
  return FireChat.instance.room(roomId);
});

// First, create a stream provider for the rooms
final roomsStreamProvider = StreamProvider.autoDispose<List<types.Room>>((ref) {
  return FireChat.instance.rooms();
});
// First, create a stream provider for the rooms
final roomsFutureProvider = FutureProvider.autoDispose<List<types.Room>>((ref) {
  return FireChat.instance.roomList();
});
