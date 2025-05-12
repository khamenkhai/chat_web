import 'dart:io';
import 'package:chat_web/controller/chat_provider.dart';
import 'package:chat_web/controller/selected_room_provider.dart';
import 'package:chat_web/fire_chat/models/message_models.dart' as types;
import 'package:chat_web/fire_chat/service/chat_service.dart';
import 'package:chat_web/view/chat/widgets/edit_message_dialog.dart';
import 'package:chat_web/view/chat/widgets/message_bubble.dart';
import 'package:chat_web/view/chat/widgets/message_input.dart';
import 'package:chat_web/view/chat/widgets/message_options_dialog.dart';
import 'package:chat_web/view/theme/theme_switch.dart';
import 'package:chat_web/view/utils/util.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:timeago/timeago.dart' as timeago;
import 'package:path_provider/path_provider.dart';

// Provider for tracking attachment upload state
final attachmentUploadingProvider =
    StateProvider.autoDispose<bool>((ref) => false);

// Provider for managing reply message state
final replyMessageProvider = StateProvider<types.Message?>((ref) => null);

final editMessageProvider = StateProvider<String>((ref) => "");

/// Main chat page widget that displays a chat room
class ChatPage extends StatelessWidget {
  const ChatPage({super.key, required this.roomId});
  final String roomId;

  Future<String> getImageUrl(String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    return await ref.getDownloadURL();
  }

  Widget _buildAvatar(types.Room room) {
    var color = Colors.transparent;

    if (room.type == types.RoomType.direct) {
      try {
        final otherUser = room.users
            .firstWhere((u) => u.id != FirebaseAuth.instance.currentUser?.uid);

        color = getUserAvatarNameColor(otherUser);
      } catch (e) {
        // Do nothing if other user is not found.
      }
    }

    final hasImage = room.imageUrl != null;
    final name = room.name ?? '';

    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: CircleAvatar(
        backgroundColor: hasImage ? Colors.transparent : color,
        backgroundImage: hasImage ? NetworkImage(room.imageUrl!) : null,
        radius: 20,
        child: !hasImage
            ? Text(
                name.isEmpty ? '' : name[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("=> chat page rebuilds!");
    // Watch for room data changes
    return Consumer(
      builder: (context, ref, _) {
        final room = ref.read(selectedRoomProvider.notifier).state;

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 60,
            title: ListTile(
              contentPadding: EdgeInsets.all(0),
              minVerticalPadding: 1,
              leading: _buildAvatar(room!),
              title: Text(room.name ?? ""),
              subtitle: FutureBuilder(
                future: FireChat.instance.getUserById(room.users
                    .firstWhere(
                        (e) => e.id != FirebaseAuth.instance.currentUser?.uid)
                    .id),
                builder: (context, snapshot) {
                  return Text(
                    formatLastSeen(snapshot.data?.lastSeen),
                    style: TextStyle(fontSize: 12, height: 0),
                  );
                },
              ),
            ),
            leadingWidth: 0,
            actions: const [
              ThemeSwitch(),
            ],
            surfaceTintColor: Colors.transparent,
          ),
          body: _ChatContent(room: room),
        );
      },
    );
  }

  String formatLastSeen(int? lastSeen) {
  if (lastSeen == null) return "Last seen: unknown";

  try {
    final lastSeenDate = DateTime.fromMillisecondsSinceEpoch(lastSeen);
    final formattedTime = DateFormat.jm().format(lastSeenDate); // e.g., 5:20 PM
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

class _ChatContent extends StatelessWidget {
  const _ChatContent({required this.room});
  final types.Room room;

  Future<void> _handleMessageTap(
      BuildContext context, types.Message message) async {
    if (message is types.FileMessage && message.uri.startsWith('http')) {
      try {
        final updated = message.copyWith(isLoading: true);
        FireChat.instance.updateMessage(updated, room.id);

        final res = await http.get(Uri.parse(message.uri));
        final dir = (await getApplicationDocumentsDirectory()).path;
        final localPath = '$dir/${message.name}';

        if (!File(localPath).existsSync()) {
          await File(localPath).writeAsBytes(res.bodyBytes);
        }
      } finally {
        final updated = message.copyWith(isLoading: false);
        FireChat.instance.updateMessage(updated, room.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("=> chat content rebuilds!");

    return Consumer(
      builder: (context, ref, child) {
        final messagesAsync = ref.watch(messagesStreamProvider(room));
        final isAttachmentUploading = ref.watch(attachmentUploadingProvider);

        final replyTo = ref.watch(replyMessageProvider);

        return messagesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
          data: (messages) {
            debugPrint("=> message rebuilds!");
            return Column(
              children: [
                Divider(
                  height: 1,
                  thickness: 0.5,
                ),
                Expanded(
                  child: CustomScrollView(
                    reverse: true,
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 20,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final message = messages[index];
                              final isMe = message.author.id ==
                                  FirebaseAuth.instance.currentUser?.uid;

                              // _onRoomOpened(room.id, messages);
                              if (message.author.id !=
                                  FirebaseAuth.instance.currentUser?.uid) {
                                FireChat.instance
                                    .markMessageAsSeen(room.id, message.id);
                              }

                              return _messageBubble(
                                isMe,
                                context,
                                message,
                                ref,
                              );
                            },
                            childCount: messages.length,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (replyTo != null) _replyToWidget(replyTo, ref),
                if (isAttachmentUploading)
                  const LinearProgressIndicator(minHeight: 2),
                MessageInput(
                  onSend: (text) {
                    
                    final reply = ref.read(replyMessageProvider);

                    if (reply != null) {
                      ///to send reply message
                      FireChat.instance.sendReply(
                        originalMessage: reply,
                        partialReply: types.PartialText(text: text),
                        roomId: room.id,
                      );
                    } else {
                      FireChat.instance.sendMessage(
                        types.PartialText(text: text),
                        room.id,
                      );
                    }

                    ref.read(replyMessageProvider.notifier).state = null;
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Message bubble
  Align _messageBubble(
    bool isMe,
    BuildContext context,
    types.Message message,
    WidgetRef ref,
  ) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: MessageBubble(
          message: message,
          isMe: isMe,
          roomId: room.id,
          metadata: message.metadata,
          onTap: () => _handleMessageTap(context, message),
          onLongPress: () {
            if (isMe) {
              showMessageOptionsDialog(
                context: context,
                onEdit: () {
                  if (message is types.TextMessage) {
                    showEditMessageDialog(
                      context: context,
                      initialMessage: message.text,
                      onSave: (p0) {
                        FireChat.instance.editTextMessage(
                          roomId: room.id,
                          messageId: message.id,
                          newText: p0,
                        );
                      },
                    );
                  }
                },
                onDelete: () {
                  FireChat.instance.setDeleteMessage(
                    roomId: room.id,
                    messageId: message.id,
                  );
                },
                onReply: () {
                  ref.read(replyMessageProvider.notifier).state = message;
                },
                isTextMessage: message is types.TextMessage,
              );
            } else {
              ref.read(replyMessageProvider.notifier).state = message;
            }
          },
        ),
      ),
    );
  }

  /// Reply to widget
  Container _replyToWidget(types.Message replyTo, WidgetRef ref) {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
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
}
