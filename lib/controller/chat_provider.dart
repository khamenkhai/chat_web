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

// Stream provider for room updates
final roomStreamProvider =
    StreamProvider.autoDispose.family<types.Room, String>((ref, roomId) {
  return ChatlyChatCore.instance.room(roomId);
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


// import 'dart:async';
// import 'package:chat_web/chatly_plus/src/chatly_chat_core.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

// final chatControllerProvider = StateNotifierProvider.autoDispose<ChatController, ChatState>((ref) {
//   return ChatController();
// });


// class ChatState {
//   final bool isAttachmentUploading;
//   final List<types.Message> messages;
//   final types.Room? room;
//   final StreamSubscription<List<types.Message>>? messagesSubscription;
//   final StreamSubscription<types.Room>? roomSubscription;

//   ChatState({
//     this.isAttachmentUploading = false,
//     this.messages = const [],
//     this.room,
//     this.messagesSubscription,
//     this.roomSubscription,
//   });

//   ChatState copyWith({
//     bool? isAttachmentUploading,
//     List<types.Message>? messages,
//     types.Room? room,
//     StreamSubscription<List<types.Message>>? messagesSubscription,
//     StreamSubscription<types.Room>? roomSubscription,
//   }) {
//     return ChatState(
//       isAttachmentUploading: isAttachmentUploading ?? this.isAttachmentUploading,
//       messages: messages ?? this.messages,
//       room: room ?? this.room,
//       messagesSubscription: messagesSubscription ?? this.messagesSubscription,
//       roomSubscription: roomSubscription ?? this.roomSubscription,
//     );
//   }
// }

// class ChatController extends StateNotifier<ChatState> {
//   ChatController() : super(ChatState());

//   void initialize(types.Room room) {
//     // Cancel any existing subscriptions
//     state.messagesSubscription?.cancel();
//     state.roomSubscription?.cancel();

//     // Set initial room
//     state = state.copyWith(room: room);

//     // Setup listeners
//     final messagesSubscription = ChatlyChatCore.instance
//         .messages(room)
//         .listen((messages) {
//       state = state.copyWith(messages: messages);
//       _markMessagesAsSeen(room.id, messages);
//     });

//     final roomSubscription = ChatlyChatCore.instance
//         .room(room.id)
//         .listen((updatedRoom) {
//       state = state.copyWith(room: updatedRoom);
//     });

//     state = state.copyWith(
//       messagesSubscription: messagesSubscription,
//       roomSubscription: roomSubscription,
//     );
//   }

//   Future<void> _markMessagesAsSeen(String roomId, List<types.Message> messages) async {
//     final currentUserId = FirebaseAuth.instance.currentUser?.uid;
//     if (currentUserId == null) return;

//     for (final message in messages) {
//       if (message.author.id != currentUserId) {
//         await ChatlyChatCore.instance.markMessageAsSeen(roomId, message.id);
//       }
//     }
//   }

//   void setAttachmentUploading(bool uploading) {
//     state = state.copyWith(isAttachmentUploading: uploading);
//   }

//   @override
//   void dispose() {
//     state.messagesSubscription?.cancel();
//     state.roomSubscription?.cancel();
//     super.dispose();
//   }
// }