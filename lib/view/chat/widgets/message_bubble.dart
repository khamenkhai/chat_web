import 'package:chat_web/core/const/theme_const.dart';
import 'package:chat_web/core/utils/context_extension.dart';
import 'package:chat_web/fire_chat/models/message_models.dart' as types;
import 'package:chat_web/fire_chat/service/chat_service.dart';
import 'package:chat_web/view/chat/widgets/file_message_tile.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:iconly/iconly.dart';
import 'package:photo_view/photo_view.dart';

class MessageBubble extends StatelessWidget {
  final types.Message message;
  final bool isMe;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final String roomId;
  final Map<String, dynamic>? metadata;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.onTap,
    required this.onLongPress,
    required this.roomId,
    this.metadata,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isDeleted ?? false) {
      return _buildDeletedMessage(context);
    }
    return _buildMessageBubble(context);
  }

  Widget _buildDeletedMessage(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: _messagePadding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // if (!isMe) _buildUserAvatar(context),
          _buildDeletedBox(theme),
          if (!isMe)
            Container(
              margin: EdgeInsets.only(left: 10),
              child: Text(
                _formatTime(message.createdAt ?? 0),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context) {
    final theme = Theme.of(context);
    final messageColors = theme.extension<MessageColors>()!;

    return Padding(
      padding: _messagePadding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // if (!isMe) _buildUserAvatar(context),
          GestureDetector(
            onTap: () => _handleMessageTap(context),
            onLongPress: onLongPress,
            child: Row(
              children: [
                if (isMe) _buildLikeButton(context: context,isMe: isMe),
                _buildMessageContentContainer(messageColors, theme, context),
                if (!isMe) _buildLikeButton(context: context,isMe: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContentContainer(
      MessageColors messageColors, ThemeData theme, BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isMe
            ? messageColors.current.withValues(alpha: 0.2)
            : messageColors.otherColor,
        borderRadius: _bubbleBorderRadius(),
      ),
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
            _buildMessageContent(theme,context),
            _buildMessageStatus(theme, context),
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  Widget _buildDeletedBox(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.do_not_disturb_on_rounded,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Text(
            "Message Deleted".tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
              fontSize: 12,
            ),
          ),
        ],
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

  // ignore: unused_element
  Widget _buildUserAvatar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: colorScheme.primaryContainer,
        backgroundImage: message.author.metadata?['avatarUrl'] != null
            ? NetworkImage(message.author.metadata!['avatarUrl'] as String)
            : null,
        child: message.author.metadata?['avatarUrl'] == null
            ? Text(
                message.author.firstName?.isNotEmpty == true
                    ? message.author.firstName![0].toUpperCase()
                    : 'U',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildLikeButton({
    required BuildContext context,
    required bool isMe
  }) {
    return Container(
      margin: EdgeInsets.only(
        left: isMe ? 0 : 10,
        right: !isMe ? 0 : 10,
      ),
      child: InkWell(
        onTap: () {
          FireChat.instance.reactToMessage(
            roomId: roomId,
            messageId: message.id,
            emoji: "❤️",
          );
        },
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: EdgeInsets.all(1),
          decoration: BoxDecoration(),
          child: FutureBuilder(
            future: FireChat.instance
                .getMyReaction(roomId: roomId, messageId: message.id),
            builder: (context, snapshot) {
              final String? myReaction = snapshot.data;
              return myReaction != null
                  ? Icon(
                      IconlyBold.heart,
                      color: context.primaryColor,
                      size: 15,
                    )
                  : Icon(
                      IconlyLight.heart,
                      size: 15,
                    );
            },
          ),
        ),
      ),
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
          topRight:  Radius.circular(12),
          topLeft:  Radius.circular(12) 
          // topRight: isMe ? const Radius.circular(8) : Radius.circular(16),
          // topLeft: isMe ? const Radius.circular(8) : Radius.zero,
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
      return SizedBox(
        width: 100,
        child: Row(
          children: [
            const Icon(Icons.insert_drive_file, size: 16),
            const SizedBox(width: 4),
            Text(
              message.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

  Widget _buildMessageContent(ThemeData theme,BuildContext context) {
    if (message is types.TextMessage) {
      return _buildTextMessage(theme);
    } else if (message is types.ImageMessage) {
      return _buildImageMessage(theme,context);
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

 Widget _buildImageMessage(ThemeData theme,BuildContext context) {
  final colorScheme = theme.colorScheme;
  final imageUrl = (message as types.ImageMessage).uri;

  return GestureDetector(
    onTap: () {
      Navigator.push(context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            // backgroundColor: Colors.black,
            appBar: AppBar(),
            body: Center(
              child: PhotoView(
                imageProvider: NetworkImage(imageUrl),
                backgroundDecoration: const BoxDecoration(color: Colors.black),
              ),
            ),
          ),
        ),
      );
    },
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      child: ClipRRect(
        borderRadius: _bubbleBorderRadius(),
        child: Image.network(
          imageUrl,
          width: 220,
          height: 220,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _buildImageLoadingIndicator(progress);
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildImageErrorPlaceholder(colorScheme);
          },
        ),
      ),
    ),
  );
}

  Widget _buildImageLoadingIndicator(ImageChunkEvent progress) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Center(
        child: CircularProgressIndicator(
          value: progress.expectedTotalBytes != null
              ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
              : null,
        ),
      ),
    );
  }

  Widget _buildImageErrorPlaceholder(ColorScheme colorScheme) {
    return Container(
      width: 220,
      height: 220,
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          IconlyLight.image,
          size: 48,
          color: colorScheme.onSurfaceVariant,
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
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
      size: 16,
      color: isSeen
          ? context.primaryColor
          : Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  BorderRadius _bubbleBorderRadius() {
    return BorderRadius.only(
      bottomLeft: const Radius.circular(12),
      bottomRight: const Radius.circular(12),
      topLeft: Radius.circular(12),
      topRight: Radius.circular(12),
      // topLeft: Radius.circular(isMe ? 16 : 4),
      // topRight: Radius.circular(isMe ? 4 : 16),
    );
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('hh:mm a').format(date);
  }

  static const EdgeInsets _messagePadding =
      EdgeInsets.symmetric(horizontal: 8, vertical: 2);
}
