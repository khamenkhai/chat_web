// Stream provider for room updates
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chat_web/chat_service/models/message_models.dart' as types;
import 'package:chat_web/chat_service/service/chat_service.dart';

final roomStreamProvider =
    StreamProvider.autoDispose.family<types.Room, String>((ref, roomId) {
  return FyreChat.instance.room(roomId);
});

// First, create a stream provider for the rooms
final roomsStreamProvider = StreamProvider.autoDispose<List<types.Room>>((ref) {
  return FyreChat.instance.rooms();
});
// First, create a stream provider for the rooms
final roomsFutureProvider = StreamProvider.autoDispose<List<types.Room>>((ref) {
  return FyreChat.instance.rooms();
});
