// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:chat_web/core/const/theme_const.dart';
import 'package:chat_web/core/utils/context_extension.dart';
import 'package:chat_web/view/chat/widgets/bubble_components/deleted_message_tile.dart';
import 'package:chat_web/view/chat/widgets/bubble_components/image_message_tile.dart';
import 'package:chat_web/view/common/user_avatar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_reaction_button/flutter_reaction_button.dart';
import 'package:chat_web/chat_service/models/message_models.dart' as types;
import 'package:chat_web/chat_service/service/chat_service.dart';
import 'package:chat_web/view/chat/widgets/bubble_components/file_message_tile.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

class MessageBubble extends StatelessWidget {
  final types.Message message;
  final bool isMe;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final String roomId;
  final types.Room room;
  final Map<String, dynamic>? metadata;
  final bool showTail;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.onTap,
    required this.onLongPress,
    required this.roomId,
    required this.room,
    required this.showTail,
    this.metadata,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isDeleted ?? false) {
      return DeletedMessageTile(
        isMe: isMe,
        createdAt: message.createdAt,
      );
    }
    return _buildMessageBubble(context);
  }

  Widget _buildMessageBubble(BuildContext context) {
    final theme = Theme.of(context);
    final messageColors = theme.extension<MessageColors>()!;

    return Padding(
      padding: messagePadding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          /// other user avatar
          (!isMe && showTail)
              ? SizedBox(
                  width: 40,
                  child: Row(
                    children: [
                      UserAvatar(
                        room: room,
                        size: 30,
                      ),
                    ],
                  ),
                )
              : Container(width: 40),
          GestureDetector(
            onTap: () => _handleMessageTap(context),
            onLongPress: onLongPress,
            child: Row(
              children: [
                if (isMe) _buildLikeButton(context: context, isMe: isMe),
                _buildMessageContentContainer(messageColors, theme, context),
                if (!isMe) _buildLikeButton(context: context, isMe: false),
              ],
            ),
          ),

          /// other user avatar
          (isMe && showTail)
              ? SizedBox(
                  width: 40,
                  child: Row(
                    children: [
                      const SizedBox(width: 10),
                      UserAvatar(
                        room: room,
                        image: room.users
                            .where((e) =>
                                e.id == FirebaseAuth.instance.currentUser!.uid)
                            .first
                            .imageUrl,
                        size: 30,
                      ),
                    ],
                  ),
                )
              : Container(width: 40),
        ],
      ),
    );
  }

  Widget _buildMessageContentContainer(
    MessageColors messageColors,
    ThemeData theme,
    BuildContext context,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 1000),
      decoration: BoxDecoration(
        color: isMe
            ? messageColors.current.withValues(alpha: 0.2)
            : messageColors.otherColor,
        borderRadius: showTail
            ? BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
                topLeft: isMe ? Radius.circular(12) : Radius.circular(0),
                topRight: !isMe ? Radius.circular(12) : Radius.circular(0),
              )
            : _bubbleBorderRadius(),
      ),
      constraints: BoxConstraints(maxWidth: 300),
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // if (!isMe) _buildSenderName(theme),
            if (message.repliedMessage != null)
              _buildReplyWidget(theme, message.repliedMessage!),
            if (message is! types.FileMessage) const SizedBox(height: 5),
            _buildMessageContent(theme, context),
            _buildMessageStatus(theme, context),
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  void _handleMessageTap(BuildContext context) {
    if (message is types.FileMessage) {
      _downloadFile(message as types.FileMessage, context);
    }
    onTap();
  }

  void _downloadFile(
      types.FileMessage fileMessage, BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloading ${fileMessage.name}...'),
          duration: const Duration(seconds: 2),
        ),
      );

      final anchor = html.AnchorElement(href: fileMessage.uri)
        ..target = '_blank'
        ..download = fileMessage.name
        ..rel = 'noopener noreferrer';

      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download file: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  String? getMyReaction(Map<String, String>? reactions, String myUserId) {
    return reactions?[myUserId];
  }

  Widget _buildLikeButton({
    required BuildContext context,
    required bool isMe,
  }) {
    final String? myReaction = getMyReaction(
        message.reactions, FirebaseAuth.instance.currentUser?.uid ?? "");
    return Container(
      margin: EdgeInsets.only(
        left: isMe ? 0 : 10,
        right: !isMe ? 0 : 10,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(1),
            decoration: BoxDecoration(),
            child: _reactionButtons(myReaction, isMe),
          ),
          if (isMe)
            FutureBuilder(
              future: FyreChat.instance.getOtherReaction(
                roomId: roomId,
                messageId: message.id,
                otherUserId: room.users
                    .firstWhere(
                        (e) => e.id != FirebaseAuth.instance.currentUser?.uid)
                    .id,
              ),
              builder: (context, snapshot) {
                return Text(
                  snapshot.data ?? "",
                  style: TextStyle(
                    fontSize: 12,
                  ),
                );
              },
            )
        ],
      ),
    );
  }

  ReactionButton<String> _reactionButtons(String? myReaction, bool isMe) {
    return ReactionButton<String>(
      toggle: false,
      direction: ReactionsBoxAlignment.rtl,
      onReactionChanged: (Reaction<String>? reaction) {
        // Handle selected reaction
        FyreChat.instance.reactToMessage(
          roomId: roomId,
          messageId: message.id,
          emoji: reaction?.value ?? "",
        );
      },
      reactions: <Reaction<String>>[
        Reaction<String>(
          value: '👍',
          icon: Text(
            '👍',
            style: TextStyle(fontSize: 16),
          ),
        ),
        Reaction<String>(
          value: '💙',
          icon: Text(
            '💙',
            style: TextStyle(fontSize: 16),
          ),
        ),
        Reaction<String>(
          value: '😂',
          icon: Text(
            '😂',
            style: TextStyle(fontSize: 16),
          ),
        ),
        Reaction<String>(
          value: '😮',
          icon: Text(
            '😮',
            style: TextStyle(fontSize: 16),
          ),
        ),
        Reaction<String>(
          value: '😢',
          icon: Text(
            '😢',
            style: TextStyle(fontSize: 16),
          ),
        ),
        Reaction<String>(
          value: '😡',
          icon: Text(
            '😡',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
      boxElevation: 1,
      boxColor: Colors.white,
      boxRadius: 30,
      itemsSpacing: 12,
      itemSize: const Size(25, 25),
      child: myReaction == null
          ? isMe
              ? Container()
              : Icon(
                  CupertinoIcons.smiley,
                  size: 16,
                )
          : Text(myReaction),
    );
  }

  Widget _buildReplyWidget(ThemeData theme, types.Message repliedMessage) {
    final messageColors = theme.extension<MessageColors>()!;
    final isReplyFromMe = repliedMessage.author.id == message.author.id;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color:
            isMe ? messageColors.myReplyColor : messageColors.otherReplyColor,
        borderRadius: BorderRadius.only(
          topRight: showTail && isMe ? Radius.circular(0) : Radius.circular(12),
          topLeft: showTail && !isMe ? Radius.circular(0) : Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.subdirectory_arrow_right, size: 12),
              const SizedBox(width: 10),
              Text(
                isReplyFromMe
                    ? 'yourself'
                    : repliedMessage.author.firstName ?? 'User',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _buildReplyContent(repliedMessage, theme),
        ],
      ),
    );
  }

  Widget _buildReplyContent(types.Message message, ThemeData theme) {
    if (message is types.TextMessage) {
      return Text(
        message.text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          fontStyle: FontStyle.italic,
        ),
      );
    } else if (message is types.ImageMessage) {
      return const Row(
        children: [
          Icon(IconlyLight.image, size: 16),
          SizedBox(width: 4),
          Text('Photo'),
        ],
      );
    } else if (message is types.FileMessage) {
      return Container(
        constraints: BoxConstraints(maxWidth: 175),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(IconlyLight.document, size: 16),
            const SizedBox(width: 4),
            Container(
              constraints: BoxConstraints(maxWidth: 150),
              child: Text(
                message.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // ignore: unused_element
  Widget _buildSenderName(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        message.author.firstName ?? 'Unknown',
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildMessageContent(ThemeData theme, BuildContext context) {
    if (message is types.TextMessage) {
      return _buildTextMessage(theme);
    } else if (message is types.ImageMessage) {
      return ImageMessageTile(message: message);
    } else if (message is types.FileMessage) {
      return FileMessageTile(message: message as types.FileMessage);
    }
    return const Text('Unsupported message type');
  }

  Widget _buildTextMessage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Text(
        (message as types.TextMessage).text,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildMessageStatus(ThemeData theme, BuildContext context) {
    final isEdited = message.isEdited ?? false;
    final isSeen = message.metadata?['seen'] == true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isEdited) _buildEditedLabel(theme),
          Text(
            _formatTime(message.createdAt ?? 0),
            style: theme.textTheme.labelSmall?.copyWith(
              color: context.secondaryTextColor,
              fontWeight: FontWeight.normal
            ),
          ),
          const SizedBox(width: 10),
          if (isMe) _buildMessageStatusIcon(context, isSeen),
        ],
      ),
    );
  }

  Widget _buildEditedLabel(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(
        "Edited",
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildMessageStatusIcon(BuildContext context, bool isSeen) {
    return Icon(
      isSeen ? Icons.done_all : Icons.done,
      size: 12,
      color: isSeen
          ? context.isLightTheme
              ? context.primaryColor
              : Colors.white
          : context.secondaryTextColor,
    );
  }

  BorderRadius _bubbleBorderRadius() {
    return BorderRadius.only(
      bottomLeft: const Radius.circular(12),
      bottomRight: const Radius.circular(12),
      topLeft: Radius.circular(12),
      topRight: Radius.circular(12),
    );
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('hh:mm a').format(date);
  }

  static const EdgeInsets messagePadding =
      EdgeInsets.symmetric(horizontal: 8, vertical: 2);
}
