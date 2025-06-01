import 'dart:io';
import 'package:chat_web/controller/chat_provider.dart';
import 'package:chat_web/controller/chat_sound_player.dart';
import 'package:chat_web/controller/message_handler.dart';
import 'package:chat_web/controller/selected_room_provider.dart';
import 'package:chat_web/core/component/custom_error_widget.dart';
import 'package:chat_web/core/component/loading_widget.dart';
import 'package:chat_web/core/const/theme_const.dart';
import 'package:chat_web/chat_service/models/message_models.dart' as types;
import 'package:chat_web/chat_service/models/message_models.dart';
import 'package:chat_web/chat_service/service/chat_service.dart';
import 'package:chat_web/view/chat/widgets/edit_message_dialog.dart';
import 'package:chat_web/view/chat/widgets/message_bubble.dart';
import 'package:chat_web/view/chat/widgets/message_input.dart';
import 'package:chat_web/view/chat/widgets/message_options_dialog.dart';
import 'package:chat_web/view/common/user_avatar.dart';
import 'package:chat_web/view/theme/theme_switch.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:timeago/timeago.dart' as timeago;
import 'package:path_provider/path_provider.dart';

// Provider for tracking attachment upload state
final attachmentUploadingProvider =
    StateProvider.autoDispose<bool>((ref) => false);

// Provider for managing reply message state
final replyMessageProvider = StateProvider<types.Message?>((ref) => null);

/// Main chat page widget that displays a chat room
class ChatPage extends StatelessWidget {
  const ChatPage({super.key, required this.roomId});
  final String roomId;

  bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width > 1200;
  }

  @override
  Widget build(BuildContext context) {
    // Add this listener for screen size changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isDesktop(context)) {
        // Delay slightly to allow the page to build before popping
        Future.delayed(Duration.zero, () {
          if (context.mounted) context.pop();
        });
      }
    });

    debugPrint("=> chat page rebuilds!");
    // Watch for room data changes
    return Consumer(
      builder: (context, ref, _) {
        // Use `watch` to react to changes (if needed)
        final Room? room = ref.watch(selectedRoomProvider);

        if (kDebugMode) {
          print("=>=> room data: $room");
        }

        if (room == null) {
          return FutureBuilder(
            future: FyreChat.instance.getRoomById(roomId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingWidget();
              }
              if (snapshot.hasError) {
                return  CustomErrorWidget(errorText: "${snapshot.error}",); // Handle errors properly
              }
              // Update state safely (avoid side effects in `builder`)
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(selectedRoomProvider.notifier).setRoom(snapshot.data!);
              });
              return _chatScaffold(snapshot.data!);
            },
          );
        }
        return _chatScaffold(room);
      },
    );
  }

  Scaffold _chatScaffold(types.Room room) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        title: ListTile(
          contentPadding: EdgeInsets.all(0),
          minVerticalPadding: 1,
          leading: UserAvatar(room: room),
          title: Text(room.name ?? ""),
          subtitle: FutureBuilder(
            future: FyreChat.instance.getUserById(room.users
                .firstWhere(
                    (e) => e.id != FirebaseAuth.instance.currentUser?.uid)
                .id),
            builder: (context, snapshot) {
              final bool isOnline = snapshot.data?.isOnline ?? false;
              return Text(
                isOnline
                    ? "Active Now"
                    : formatLastSeen(snapshot.data?.lastSeen),
                style: TextStyle(fontSize: 12, height: 0),
              );
            },
          ),
        ),
        leadingWidth: 0,
        actions: [
          ThemeSwitch(),
          const SizedBox(width: 10),
        ],
        surfaceTintColor: Colors.transparent,
      ),
      body: _ChatContent(room: room),
    );
  }

  /// get image url
  Future<String> getImageUrl(String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    return await ref.getDownloadURL();
  }

  String formatLastSeen(int? lastSeen) {
    if (lastSeen == null) return "Last seen: unknown";

    try {
      final lastSeenDate = DateTime.fromMillisecondsSinceEpoch(lastSeen);
      final formattedTime =
          DateFormat.jm().format(lastSeenDate); // e.g., 5:20 PM
      final timeAgo = timeago.format(lastSeenDate); // e.g., 5 minutes ago
      return "Last seen $timeAgo at $formattedTime";
    } catch (e) {
      return "Last seen: invalid date";
    }
  }

  String formatTime(int? dateTime) {
    try {
      final formattedTime = DateFormat.jm().format(
        DateTime.fromMillisecondsSinceEpoch(dateTime ?? 0),
      );

      return formattedTime;
    } catch (e) {
      return "Invalid time!";
    }
  }
}

class _ChatContent extends StatefulWidget {
  const _ChatContent({required this.room});
  final types.Room room;

  @override
  State<_ChatContent> createState() => _ChatContentState();
}

class _ChatContentState extends State<_ChatContent> {
  final ChatSoundPlayer _soundPlayer = ChatSoundPlayer();
  List<types.Message> _previousMessages = [];
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _initializeSoundPlayer();
  }

  @override
  void dispose() {
    _isMounted = false;
    _soundPlayer.dispose();
    super.dispose();
  }

  Future<void> _initializeSoundPlayer() async {
    await _soundPlayer.initialize();
  }

  void _checkForNewMessages(List<types.Message> currentMessages) {
    if (_previousMessages.isEmpty) {
      _previousMessages = currentMessages;
      return;
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final newMessages = currentMessages.where((message) {
      return !_previousMessages.any((m) => m.id == message.id) &&
          MessageHandler.shouldPlaySound(message, currentUserId);
    }).toList();

    if (newMessages.isNotEmpty && _isMounted) {
      _soundPlayer.playNotificationSound();
    }

    _previousMessages = currentMessages;
  }

  Future<void> _handleMessageTap(types.Message message) async {
    if (message is! types.FileMessage || !message.uri.startsWith('http')) {
      return;
    }

    try {
      final updated = message.copyWith(isLoading: true);
      FyreChat.instance.updateMessage(updated, widget.room.id);

      final res = await http.get(Uri.parse(message.uri));
      final dir = (await getApplicationDocumentsDirectory()).path;
      final localPath = '$dir/${message.name}';

      if (!File(localPath).existsSync()) {
        await File(localPath).writeAsBytes(res.bodyBytes);
      }
    } finally {
      final updated = message.copyWith(isLoading: false);
      FyreChat.instance.updateMessage(updated, widget.room.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final messagesAsync = ref.watch(messagesStreamProvider(widget.room));
        final isAttachmentUploading = ref.watch(attachmentUploadingProvider);
        final replyTo = ref.watch(replyMessageProvider);

        return messagesAsync.when(
          loading: () => const Center(child: LoadingWidget()),
          error: (error, stack) => Center(child: Text('Error: $error')),
          data: (messages) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              
              _checkForNewMessages(messages);
            });

            return Column(
              children: [
                const Divider(height: 1, thickness: 0.5),
                Expanded(child: _buildMessageList(context, messages, ref)),
                if (replyTo != null) _buildReplyWidget(replyTo, ref),
                if (isAttachmentUploading)
                  const LinearProgressIndicator(minHeight: 2),
                MessageInput(
                  onSend: (text) => _handleSendMessage(text, ref),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(
    bool isMe,
    BuildContext context,
    types.Message message,
    WidgetRef ref,
    bool showTail, // Add this parameter
  ) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: MessageBubble(
        message: message,
        isMe: isMe,
        roomId: widget.room.id,
        room: widget.room,
        metadata: message.metadata,
        showTail: showTail, // Pass the parameter
        onTap: () => _handleMessageTap(message),
        onLongPress: () => _handleLongPress(context, message, ref, isMe),
      ),
    );
  }

// Update your message list building logic
  Widget _buildMessageList(
    BuildContext context,
    List<types.Message> messages,
    WidgetRef ref,
  ) {
    // Group messages by user and determine which should show tails
    List<Widget> messageWidgets = [];

    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      final currentAuthorId = message.author.id;
      final showTail = i ==
              messages.length - 1 || // Last message always shows tail
          currentAuthorId != messages[i + 1].author.id; // Different author next

      messageWidgets.add(
        _buildMessageBubble(
          message.author.id == FirebaseAuth.instance.currentUser?.uid,
          context,
          message,
          ref,
          showTail,
        ),
      );
    }

    return CustomScrollView(
      reverse: true,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.symmetric(
            vertical: 8,
            horizontal: MediaQuery.of(context).size.width > 1200
                ? 32
                : MediaQuery.of(context).size.width > 800
                    ? 8
                    : 0,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate(messageWidgets),
          ),
        ),
      ],
    );
  }

  void _handleLongPress(
    BuildContext context,
    types.Message message,
    WidgetRef ref,
    bool isMe,
  ) {
    if (isMe) {
      showMessageOptionsDialog(
        context: context,
        onEdit: () => _handleEditMessage(context, message),
        onDelete: () => _handleDeleteMessage(message),
        onReply: () => _handleReplyMessage(ref, message),
        isTextMessage: message is types.TextMessage,
      );
    } else {
      ref.read(replyMessageProvider.notifier).state = message;
    }
  }

  void _handleEditMessage(BuildContext context, types.Message message) {
    if (message is types.TextMessage) {
      showEditMessageDialog(
        context: context,
        initialMessage: message.text,
        onSave: (newText) {
          FyreChat.instance.editTextMessage(
            roomId: widget.room.id,
            messageId: message.id,
            newText: newText,
          );
        },
      );
    }
  }

  void _handleDeleteMessage(types.Message message) {
    FyreChat.instance.setDeleteMessage(
      roomId: widget.room.id,
      messageId: message.id,
    );
  }

  void _handleReplyMessage(WidgetRef ref, types.Message message) {
    ref.read(replyMessageProvider.notifier).state = message;
  }

  Widget _buildReplyWidget(types.Message replyTo, WidgetRef ref) {
    final messageColors = Theme.of(context).extension<MessageColors>()!;
    return Container(
      color: messageColors.otherReplyColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              replyTo is types.TextMessage ? replyTo.text : 'Replying...',
              style: const TextStyle(fontStyle: FontStyle.italic),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () =>
                ref.read(replyMessageProvider.notifier).state = null,
          )
        ],
      ),
    );
  }

  void _handleSendMessage(String text, WidgetRef ref) {
    final reply = ref.read(replyMessageProvider);

    if (reply != null) {
      FyreChat.instance.sendReply(
        originalMessage: reply,
        partialReply: types.PartialText(text: text),
        roomId: widget.room.id,
      );
    } else {
      FyreChat.instance.sendMessage(
        types.PartialText(text: text),
        widget.room.id,
      );
    }

    ref.read(replyMessageProvider.notifier).state = null;
  }
}
