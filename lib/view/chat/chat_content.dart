import 'package:chat_web/view/chat/chat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_pagination/firebase_pagination.dart';
import 'package:flutter/material.dart';
import 'package:chat_web/controller/chat_provider.dart';
import 'package:chat_web/controller/chat_sound_player.dart';
import 'package:chat_web/core/component/loading_widget.dart';
import 'package:chat_web/core/const/theme_const.dart';
import 'package:chat_web/view/chat/widgets/chat_components/edit_message_dialog.dart';
import 'package:chat_web/view/chat/widgets/message_bubble.dart';
import 'package:chat_web/view/chat/widgets/message_input.dart';
import 'package:chat_web/view/chat/widgets/chat_components/message_options_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fyrechat/const/fire_chat_const.dart';
import 'package:fyrechat/service/chat_service.dart';
import 'package:fyrechat/fyrechat.dart' as fc;

class ChatContent extends StatefulWidget {
  final fc.Room room;
  const ChatContent({required this.room, super.key});

  @override
  State<ChatContent> createState() => ChatContentState();
}

class ChatContentState extends State<ChatContent> {
  final ChatSoundPlayer _soundPlayer = ChatSoundPlayer();
  List<fc.Message> _previousMessages = [];
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

  void _checkForNewMessages(List<fc.Message> currentMessages) {
    if (_previousMessages.isEmpty) {
      _previousMessages = currentMessages;
      return;
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final newMessages = currentMessages.where((message) {
      return !_previousMessages.any((m) => m.id == message.id) &&
          ChatSoundPlayer.shouldPlaySound(message, currentUserId);
    }).toList();

    if (newMessages.isNotEmpty && _isMounted) {
      _soundPlayer.playNotificationSound();
    }

    _previousMessages = currentMessages;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        /// message async
        final messagesAsync = ref.watch(messagesStreamProvider(widget.room));

        /// to check if a file is uploading
        final isAttachmentUploading = ref.watch(attachmentUploadingProvider);

        /// a cached data to save a reply to
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
                Expanded(
                  child: FirestorePagination(
                    reverse: true,
                    isLive: true,
                    bottomLoader: const LoadingWidget(),
                    padding: EdgeInsets.symmetric(
                      horizontal: _getResponsivePadding(context),
                    ),
                    initialLoader: const LoadingWidget(),
                    limit: 10,
                    query: FirebaseFirestore.instance
                        .collection(
                            '${FireChatConst.roomsCollectionName}/${widget.room.id}/messages')
                        .orderBy('createdAt', descending: true),
                    itemBuilder: (context, docs, index) {
                      final fc.Room room = widget.room;
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      // Process the data similar to your messages function
                      final author = room.users.firstWhere(
                        (u) => u.id == data['authorId'],
                        orElse: () =>
                            fc.User(id: data['authorId'] as String),
                      );

                      data['author'] = author.toJson();
                      data['createdAt'] =
                          data['createdAt']?.millisecondsSinceEpoch;
                      data['id'] = doc.id;
                      data['updatedAt'] =
                          data['updatedAt']?.millisecondsSinceEpoch;

                      // Check if the message has been seen by all users
                      final seenBy =
                          data['seenBy'] as Map<String, dynamic>? ?? {};
                      final allUsersHaveSeen = room.users
                          .every((user) => seenBy.containsKey(user.id));

                      // Create the message
                      final message = fc.Message.fromJson(data).copyWith(
                        metadata: {
                          ...data['metadata'] ?? {},
                          'seen': allUsersHaveSeen,
                        },
                      );

                      // Process reply metadata if exists
                      _processReplyMetadata(message, room);

                      final isMe = FirebaseAuth.instance.currentUser?.uid ==
                          message.author.id;

                      // 💡 Calculate showTail:
                      bool showTail = true;
                      if (index < docs.length - 1) {
                        final nextDoc = docs[index + 1];
                        final nextData = nextDoc.data() as Map<String, dynamic>;
                        final nextAuthorId = nextData['authorId'] as String?;

                        if (nextAuthorId == message.author.id) {
                          showTail = false;
                        }
                      }

                      FyreChat.instance
                          .markMessageAsSeen(widget.room.id, message.id);

                      // *************************************************
                      DateTime? currentMessageDate;
                      if (message.createdAt != null) {
                        currentMessageDate =
                            DateTime.fromMillisecondsSinceEpoch(
                                message.createdAt!);
                      }

                      DateTime? previousMessageDate;
                      if (index < docs.length - 1) {
                        final prevDoc = docs[index + 1];
                        final prevData = prevDoc.data() as Map<String, dynamic>;
                        final prevCreatedAt = prevData['createdAt'];
                        if (prevCreatedAt != null) {
                          previousMessageDate =
                              DateTime.fromMillisecondsSinceEpoch(
                            prevCreatedAt.millisecondsSinceEpoch,
                          );
                        }
                      }

// Check if date separator is needed
                      bool showDateSeparator = false;
                      if (currentMessageDate != null &&
                          (previousMessageDate == null ||
                              currentMessageDate.day !=
                                  previousMessageDate.day ||
                              currentMessageDate.month !=
                                  previousMessageDate.month ||
                              currentMessageDate.year !=
                                  previousMessageDate.year)) {
                        showDateSeparator = true;
                      }

                      // *************************************************
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showDateSeparator)
                            Center(
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 10),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(_formatDate(currentMessageDate!),
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                              ),
                            ),
                          Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: EdgeInsets.only(
                                  top: index == (docs.length - 1) ? 20 : 0),
                              child: MessageBubble(
                                message: message,
                                isMe: isMe,
                                roomId: widget.room.id,
                                room: widget.room,
                                metadata: message.metadata,
                                showTail: showTail,
                                onTap: () {},
                                onLongPress: () => _handleLongPress(
                                    context, message, ref, isMe),
                              ),
                            ),
                          ),
                        ],
                      );

                      // Return a widget using the processed message
                      // return Align(
                      //   alignment:
                      //       isMe ? Alignment.centerRight : Alignment.centerLeft,
                      //   child: Container(
                      //     margin: EdgeInsets.only(
                      //         top: index == (docs.length - 1) ? 20 : 0),
                      //     child: MessageBubble(
                      //       message: message,
                      //       isMe: isMe,
                      //       roomId: widget.room.id,
                      //       room: widget.room,
                      //       metadata: message.metadata,
                      //       showTail: showTail, // Pass the parameter
                      //       onTap: () {},
                      //       onLongPress: () =>
                      //           _handleLongPress(context, message, ref, isMe),
                      //     ),
                      //   ),
                      // );
                    },
                  ),
                ),
                if (replyTo != null) _buildReplyWidget(replyTo, ref),
                if (isAttachmentUploading) const LoadingWidget(),

                /// message input box
                const MessageInput(),
              ],
            );
          },
        );
      },
    );
  }

  double _getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < 600) {
      // Mobile
      return 0;
    } else if (width < 1024) {
      // Tablet
      return 1;
    } else {
      // Desktop
      return 100;
    }
  }

  void _handleLongPress(
    BuildContext context,
    fc.Message message,
    WidgetRef ref,
    bool isMe,
  ) {
    if (isMe) {
      showMessageOptionsDialog(
        context: context,
        onEdit: () => _handleEditMessage(context, message),
        onDelete: () => _handleDeleteMessage(message),
        onReply: () => _handleReplyMessage(ref, message),
        isTextMessage: message is fc.TextMessage,
      );
    } else {
      ref.read(replyMessageProvider.notifier).state = message;
    }
  }

  void _handleEditMessage(BuildContext context, fc.Message message) {
    if (message is fc.TextMessage) {
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

  void _handleDeleteMessage(fc.Message message) {
    FyreChat.instance.setDeleteMessage(
      roomId: widget.room.id,
      messageId: message.id,
    );
  }

  void _handleReplyMessage(WidgetRef ref, fc.Message message) {
    ref.read(replyMessageProvider.notifier).state = message;
  }

  Widget _buildReplyWidget(fc.Message replyTo, WidgetRef ref) {
    final messageColors = Theme.of(context).extension<MessageColors>()!;
    return Container(
      color: messageColors.otherReplyColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              replyTo is fc.TextMessage ? replyTo.text : 'Replying...',
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

  fc.Message _processReplyMetadata(
    fc.Message message,
    fc.Room room,
  ) {
    // If message has a replied message, ensure its author is properly set from room users
    if (message.repliedMessage != null) {
      final repliedMessage = message.repliedMessage!;
      final originalAuthor = room.users.firstWhere(
        (u) => u.id == repliedMessage.author.id,
        orElse: () =>
            repliedMessage.author, // Fall back to original author if not found
      );
      // Return message with updated repliedMessage author
      return message.copyWith(
        repliedMessage: repliedMessage.copyWith(author: originalAuthor),
      );
    }
    // Return original message if no replied message
    return message;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
