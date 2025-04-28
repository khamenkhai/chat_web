import 'package:chat_web/core/const/theme_const.dart';
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final messageColors = Theme.of(context).extension<MessageColors>()!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasReply = message.metadata?["replyTo"] != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMe ? messageColors.current: messageColors.otherColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasReply) _buildReplyWidget(theme),
                if (!isMe) _buildSenderName(theme),
                const SizedBox(height: 4),
                _buildMessageContent(theme, colorScheme),
                const SizedBox(height: 6),
                _buildMessageStatus(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReplyWidget(ThemeData theme) {
    final replyTo = message.metadata?['replyTo'];
    if (replyTo == null) return SizedBox.shrink();

    final isReplyToCurrentUser = replyTo.author?.id ==
        message.author.id; // Check if the reply is to the current user

    // Cast replyTo to a TextMessage if possible (you can handle other types of messages similarly)
    final replyText =
        replyTo is types.TextMessage ? replyTo.text : 'Unsupported reply type';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color:
            isReplyToCurrentUser ? Colors.blue.shade100 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isReplyToCurrentUser)
            // Text(
            //   "Replied to: ${replyTo.author?.firstName ?? 'Unknown'}",
            //   style: theme.textTheme.labelSmall?.copyWith(
            //     fontStyle: FontStyle.italic,
            //     color: Colors.black87,
            //   ),
            // ),
            Text(
              replyText,
              style: theme.textTheme.labelSmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: Colors.black87,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSenderName(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
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
      return Text(
        (message as types.TextMessage).text,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: isMe ? colorScheme.onPrimary : colorScheme.onSurface,
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
              child: Center(child: CircularProgressIndicator()),
            );
          },
        ),
      );
    } else if (message is types.FileMessage) {
      return _FileMessageTile(message: message as types.FileMessage);
    }
    return const Text('Unsupported message type');
  }

  Widget _buildMessageStatus(ThemeData theme) {
    final isSeen = message.metadata?['seen'] == true;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(message.createdAt ?? 0),
          style: theme.textTheme.labelSmall?.copyWith(
            color: isMe
                ? theme.colorScheme.onPrimary.withValues(alpha: 0.7)
                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(width: 4),
        if (isMe)
          Icon(
            isSeen ? Icons.done_all : Icons.done,
            size: 16,
            color: isSeen
                ? Colors.white
                : theme.colorScheme.onPrimary.withValues(alpha: 0.7),
          ),
      ],
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
      ),
      child: Row(
        children: [
          Icon(icon, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.name,
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatFileSize(message.size),
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
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

class MessageInput extends StatefulWidget {
  final Function(String) onSend;
  final VoidCallback onAttachmentPressed;

  const MessageInput({
    super.key,
    required this.onSend,
    required this.onAttachmentPressed,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: widget.onAttachmentPressed,
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (text) {
                setState(() {});
              },
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.send,
              color: _textController.text.trim().isEmpty
                  ? Theme.of(context).disabledColor
                  : Theme.of(context).colorScheme.primary,
            ),
            onPressed: _textController.text.trim().isEmpty
                ? null
                : () {
                    widget.onSend(_textController.text);
                    _textController.clear();
                    setState(() {});
                  },
          ),
        ],
      ),
    );
  }
}
