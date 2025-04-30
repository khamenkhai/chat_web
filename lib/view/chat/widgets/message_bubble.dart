import 'package:chat_web/core/const/theme_const.dart';
import 'package:chat_web/core/utils/context_extension.dart';
import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

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

  void _downloadFile(
      types.FileMessage fileMessage, BuildContext context) async {
    try {
      // Show a loading indicator or snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloading ${fileMessage.name}...'),
          duration: const Duration(seconds: 2),
        ),
      );

      // Create a hidden anchor element
      final anchor = html.AnchorElement(href: fileMessage.uri)
        ..target = '_blank'
        ..download = fileMessage.name
        ..rel = 'noopener noreferrer';

      // Add to DOM, trigger click, then remove
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();

      // Optional: Track successful download initiation
      debugPrint('Download initiated for: ${fileMessage.name}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download file: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      debugPrint('File download error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final messageColors = Theme.of(context).extension<MessageColors>()!;
    final theme = Theme.of(context);
    final colorScheme = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) // Show avatar only for other users
            _userAvatar(colorScheme, theme),

          /// Message box
          GestureDetector(
            onTap: () {
              // Web-specific download/open logic
              if (message is types.FileMessage) {
                _downloadFile(message as types.FileMessage, context);
              }
            },
            onLongPress: onLongPress,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isMe
                    ? messageColors.current.withValues(alpha: 0.1)
                    : messageColors.otherColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                  topLeft: Radius.circular(isMe ? 16 : 4),
                  topRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: IntrinsicWidth(
                child: Column(
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isMe) SizedBox(height: 5),
                    if (!isMe) _buildSenderName(theme),
                    if (message.repliedMessage != null)
                      _buildReplyWidget(
                        theme,
                        message.repliedMessage!,
                        isMe,
                        messageColors,
                      ),
                    const SizedBox(height: 5),
                    _buildMessageContent(theme, colorScheme),
                    _buildMessageStatus(theme, context),
                    const SizedBox(height: 5),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Padding _userAvatar(ColorScheme colorScheme, ThemeData theme) {
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

  Widget _buildReplyWidget(
    ThemeData theme,
    types.Message repliedMessage,
    bool isCurrentUser,
    MessageColors messageColors,
  ) {
    final isReplyFromMe = repliedMessage.author.id == message.author.id;

    return Container(
      margin: EdgeInsets.all(0),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: messageColors.replyColor,
        borderRadius: BorderRadius.only(
          topRight: isMe ? Radius.circular(8) : Radius.zero,
          topLeft: isMe ? Radius.circular(8) : Radius.zero,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.subdirectory_arrow_right,
                size: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
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
      return Row(
        children: [
          const Icon(Icons.image, size: 16),
          const SizedBox(width: 4),
          Text(
            'Photo',
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    } else if (message is types.FileMessage) {
      return SizedBox(
        width: 100,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file, size: 16),
            const SizedBox(width: 4),
            Text(
              message.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSenderName(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        message.author.firstName ?? 'Unknown',
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildMessageContent(ThemeData theme, ColorScheme colorScheme) {
    if (message is types.TextMessage) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Text(
          (message as types.TextMessage).text,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
            // color: isMe ? colorScheme.onPrimary : colorScheme.onSurface,
            fontSize: 14,
          ),
        ),
      );
    } else if (message is types.ImageMessage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          (message as types.ImageMessage).uri,
          width: 220,
          height: 220,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return SizedBox(
              width: 220,
              height: 220,
              child: Center(
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 220,
              height: 220,
              color: colorScheme.surfaceContainerHighest,
              child: Center(
                child: Icon(
                  Icons.broken_image,
                  size: 48,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            );
          },
        ),
      );
    } else if (message is types.FileMessage) {
      return _FileMessageTile(message: message as types.FileMessage);
    }
    return const Text('Unsupported message type');
  }

  Widget _buildMessageStatus(ThemeData theme, BuildContext context) {
    final isSeen = message.metadata?['seen'] == true;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            _formatTime(message.createdAt ?? 0),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              // color: isMe
              //     ? theme.colorScheme.onPrimary.withValues(alpha: 0.7)
              //     : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 10),
          if (isMe)
            Icon(
              isSeen ? Icons.done_all : Icons.done,
              size: 16,
              color: isSeen
                  ? context.primaryColor
                  : theme.colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    );
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _FileMessageTile extends StatelessWidget {
  final types.FileMessage message;

  const _FileMessageTile({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = _getFileIcon(message.mimeType);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.name,
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _formatFileSize(message.size),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String? mimeType) {
    if (mimeType == null) return Icons.insert_drive_file;

    if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
    if (mimeType.contains('word')) return Icons.description;
    if (mimeType.contains('excel')) return Icons.table_chart;
    if (mimeType.contains('powerpoint')) return Icons.slideshow;
    if (mimeType.contains('zip')) return Icons.archive;
    if (mimeType.contains('image')) return Icons.image;
    if (mimeType.contains('audio')) return Icons.audiotrack;
    if (mimeType.contains('video')) return Icons.videocam;

    return Icons.insert_drive_file;
  }

  String _formatFileSize(num size) {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
