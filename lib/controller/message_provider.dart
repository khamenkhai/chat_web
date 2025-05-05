// Stream provider for messages
import 'package:chat_web/service/chat_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chat_web/flutter_chat_types/flutter_chat_types.dart' as types;

final messagesStreamProvider = StreamProvider.autoDispose
    .family<List<types.Message>, types.Room>((ref, room) {
  return ChatlyChatCore.instance.messages(room);
});