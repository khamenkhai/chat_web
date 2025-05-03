// Stream provider for room updates
import 'package:chat_web/service/chat_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

final roomStreamProvider =
    StreamProvider.autoDispose.family<types.Room, String>((ref, roomId) {
  return ChatlyChatCore.instance.room(roomId);
});

// First, create a stream provider for the rooms
final roomsStreamProvider = StreamProvider.autoDispose<List<types.Room>>((ref) {
  return ChatlyChatCore.instance.rooms();
});
