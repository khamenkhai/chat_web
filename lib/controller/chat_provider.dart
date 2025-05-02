import 'package:chat_web/controller/room_provider.dart';
import 'package:chat_web/service/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:logger/logger.dart';

// Stream provider for messages
final messagesStreamProvider = StreamProvider.autoDispose
    .family<List<types.Message>, types.Room>((ref, room) {
  return ChatlyChatCore.instance.messages(room);
});


// Combined state provider
final chatStateProvider =
    Provider.autoDispose.family<AsyncValue<ChatState>, types.Room>((ref, room) {
  final messagesAsync = ref.watch(messagesStreamProvider(room));
  final roomAsync = ref.watch(roomStreamProvider(room.id));

  return messagesAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
    data: (messages) {
      return roomAsync.when(
        loading: () => const AsyncValue.loading(),
        error: (error, stack) => AsyncValue.error(error, stack),
        data: (updatedRoom) {
          // Mark messages as seen
          final Logger logger = Logger();
          logger.f("=> Marking message", stackTrace: StackTrace.fromString(""));

          _markMessagesAsSeen(ref, room.id, messages);
          return AsyncValue.data(
            ChatState(
              messages: messages,
              room: updatedRoom,
            ),
          );
        },
      );
    },
  );
});

Future<void> _markMessagesAsSeen(
  Ref ref,
  String roomId,
  List<types.Message> messages,
) async {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  if (currentUserId == null) return;

  for (final message in messages) {
    if (message.author.id != currentUserId) {
      await ChatlyChatCore.instance.markMessageAsSeen(roomId, message.id);
    }
  }
}

class ChatState {
  final bool isAttachmentUploading;
  final List<types.Message> messages;
  final types.Room? room;

  ChatState({
    this.isAttachmentUploading = false,
    this.messages = const [],
    this.room,
  });

  ChatState copyWith({
    bool? isAttachmentUploading,
    List<types.Message>? messages,
    types.Room? room,
  }) {
    return ChatState(
      isAttachmentUploading:
          isAttachmentUploading ?? this.isAttachmentUploading,
      messages: messages ?? this.messages,
      room: room ?? this.room,
    );
  }
}

// Provider for attachment uploading state
final attachmentUploadingProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});

