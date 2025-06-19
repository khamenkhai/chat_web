// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:chat_web/core/const/size_const.dart';
import 'package:chat_web/core/const/theme_const.dart';
import 'package:chat_web/core/utils/context_extension.dart';
import 'package:chat_web/view/chat/widgets/bubble_components/deleted_message_tile.dart';
import 'package:chat_web/view/chat/widgets/bubble_components/file_message_tile.dart';
import 'package:chat_web/view/chat/widgets/bubble_components/image_message_tile.dart';
import 'package:chat_web/view/common/user_avatar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_reaction_button/flutter_reaction_button.dart';
import 'package:chat_web/chat_service/models/message_models.dart' as types;
import 'package:chat_web/chat_service/service/chat_service.dart';
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

    return Container(
      margin: _messagePadding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // Other user avatar - smaller and cleaner
          if (!isMe) _buildOtherUserAvatar(),

          // Message content with reactions
          Flexible(
            child: _buildMessageWithReactions(context, messageColors, theme),
          ),

          // Spacing for alignment
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildOtherUserAvatar() {
    return Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.only(right: 6, bottom: 2),
      child: showTail
          ? UserAvatar(
              room: room,
              size: 24,
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildMessageWithReactions(
    BuildContext context,
    MessageColors messageColors,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Reaction button for received messages - smaller
            if (isMe) _buildReactionButton(context, isLeft: true, messageColors: messageColors),

            // Message bubble
            Flexible(
              child: GestureDetector(
                onTap: () => _handleMessageTap(context),
                onLongPress: onLongPress,
                child: _buildMessageContentContainer(
                  messageColors,
                  theme,
                  context,
                ),
              ),
            ),

            // Reaction button for sent messages - smaller
            if (!isMe) _buildReactionButton(context, isLeft: false,messageColors: messageColors),
          ],
        ),

        // Other user's reaction display - more compact
        if (isMe) _buildOtherUserReaction(),
      ],
    );
  }

  Widget _buildMessageContentContainer(
    MessageColors messageColors,
    ThemeData theme,
    BuildContext context,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isMe
            ? messageColors.current.withValues(alpha: 0.12)
            : messageColors.otherColor,
        borderRadius: _getBubbleBorderRadius(),
      ),
      constraints: const BoxConstraints(maxWidth: 280),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply widget
          if (message.repliedMessage != null)
            _buildReplyWidget(theme, message.repliedMessage!),

          // Message content
          _buildMessageContent(theme, context),

          // Message status and time
          _buildMessageFooter(theme, context),
        ],
      ),
    );
  }

  BorderRadius _getBubbleBorderRadius() {
    const radius = Radius.circular(14);
    const smallRadius = Radius.circular(3);

    if (showTail) {
      return BorderRadius.only(
        bottomLeft: radius,
        bottomRight: radius,
        topLeft: isMe ? radius : smallRadius,
        topRight: isMe ? smallRadius : radius,
      );
    }
    return BorderRadius.circular(14);
  }

  Widget _buildReactionButton(BuildContext context, {required bool isLeft,required MessageColors messageColors}) {
    final String? myReaction = _getMyReaction(
        message.reactions, FirebaseAuth.instance.currentUser?.uid ?? "");

    return Container(
      margin: EdgeInsets.only(
        left: isLeft ? 0 : 4,
        right: isLeft ? 4 : 0,
        bottom: 2,
      ),
      child: ReactionButton<String>(
        toggle: false,
        direction: isMe ? ReactionsBoxAlignment.rtl : ReactionsBoxAlignment.ltr,
        onReactionChanged: (Reaction<String>? reaction) {
          FyreChat.instance.reactToMessage(
            roomId: roomId,
            messageId: message.id,
            emoji: reaction?.value ?? "",
          );
        },
        reactions: const <Reaction<String>>[
          Reaction<String>(
            value: '👍',
            icon: Text('👍', style: TextStyle(fontSize: 16)),
          ),
          Reaction<String>(
            value: '💙',
            icon: Text('💙', style: TextStyle(fontSize: 16)),
          ),
          Reaction<String>(
            value: '😂',
            icon: Text('😂', style: TextStyle(fontSize: 16)),
          ),
          Reaction<String>(
            value: '😮',
            icon: Text('😮', style: TextStyle(fontSize: 16)),
          ),
          Reaction<String>(
            value: '😢',
            icon: Text('😢', style: TextStyle(fontSize: 16)),
          ),
          Reaction<String>(
            value: '😡',
            icon: Text('😡', style: TextStyle(fontSize: 16)),
          ),
        ],
        boxElevation: 4,
        boxColor: Theme.of(context).colorScheme.surface,
        boxRadius: 20,
        itemsSpacing: 6,
        itemSize: const Size(28, 28),
        child: myReaction == null
            ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  // color:  messageColors.otherColor,
                  borderRadius: BorderRadius.circular(SizeConst.radius /1.5)
                ),
                child: Icon(
                  CupertinoIcons.hand_thumbsup,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: messageColors.otherColor,
                 borderRadius: BorderRadius.circular(SizeConst.radius)
                ),
                child: Text(
                  myReaction,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
      ),
    );
  }

  Widget _buildOtherUserReaction() {
    return FutureBuilder<String?>(
      future: FyreChat.instance.getOtherReaction(
        roomId: roomId,
        messageId: message.id,
        otherUserId: room.users
            .firstWhere((e) => e.id != FirebaseAuth.instance.currentUser?.uid)
            .id,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return Container(
            margin: const EdgeInsets.only(top: 2, right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              snapshot.data!,
              style: const TextStyle(fontSize: 12),
            ),
          );
        }
        return const SizedBox.shrink();
      },
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
          content: Row(
            children: [
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
              const SizedBox(width: 8),
              Text(
                'Downloading ${fileMessage.name}...',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
          content: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.onError,
                size: 16,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Download failed',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  String? _getMyReaction(Map<String, String>? reactions, String myUserId) {
    return reactions?[myUserId];
  }

  Widget _buildReplyWidget(ThemeData theme, types.Message repliedMessage) {
    final messageColors = theme.extension<MessageColors>()!;
    final isReplyFromMe = repliedMessage.author.id == message.author.id;

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe
            ? messageColors.myReplyColor.withOpacity(0.6)
            : messageColors.otherReplyColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.reply_rounded,
                size: 12,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                isReplyFromMe
                    ? 'You'
                    : repliedMessage.author.firstName ?? 'User',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
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
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 11,
          height: 1.2,
        ),
      );
    } else if (message is types.ImageMessage) {
      return Row(
        children: [
          Icon(
            IconlyLight.image,
            size: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            'Photo',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      );
    } else if (message is types.FileMessage) {
      return Row(
        children: [
          Icon(
            IconlyLight.document,
            size: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              message.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildMessageContent(ThemeData theme, BuildContext context) {
    if (message is types.TextMessage) {
      return _buildTextMessage(theme);
    } else if (message is types.ImageMessage) {
      return ImageMessageTile(message: message);
    } else if (message is types.FileMessage) {
      return FileMessageTile(message: message as types.FileMessage);
    }
    return Container(
      padding: const EdgeInsets.all(12),
      child: Text(
        'Unsupported message type',
        style: theme.textTheme.bodySmall?.copyWith(
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTextMessage(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        (message as types.TextMessage).text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
          fontSize: 14,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildMessageFooter(ThemeData theme, BuildContext context) {
    final isEdited = message.isEdited ?? false;
    final isSeen = message.metadata?['seen'] == true;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isEdited) _buildEditedLabel(theme),
          Text(
            _formatTime(message.createdAt ?? 0),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 4),
            _buildMessageStatusIcon(context, isSeen),
          ],
        ],
      ),
    );
  }

  Widget _buildEditedLabel(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      child: Text(
        "edited",
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
          fontSize: 9,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildMessageStatusIcon(BuildContext context, bool isSeen) {
    return Icon(
      isSeen ? Icons.done_all_rounded : Icons.done_rounded,
      size: 12,
      color: isSeen
          ? context.isLightTheme
              ? context.primaryColor
              : Colors.white
          : context.secondaryTextColor,
    );
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('h:mm a').format(date);
  }

  static const EdgeInsets _messagePadding =
      EdgeInsets.symmetric(horizontal: 8, vertical: 1.5);
}

