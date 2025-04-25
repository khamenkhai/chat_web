import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class MessageBubble extends StatelessWidget {
  final types.Message message;
  final bool isMe;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Map<String, dynamic>? metadata;
  final String roomId;

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // metadata?['isRepliedMessage'] != null
        //     ? Container():

        _messageBox(colorScheme, theme),

        // metadata?['isRepliedMessage'] != null
        //     ? FutureBuilder(
        //         future: ChatlyChatCore.instance.getMessageById(
        //           roomId: roomId,
        //           messageId: metadata?["originalMessageId"],
        //         ),
        //         builder: (context, snapshot) {
        //           return Text(
        //             (message as types.TextMessage).text,
        //           );
        //         },
        //       )
        //     : Container()
      ],
    );
  }

  GestureDetector _messageBox(ColorScheme colorScheme, ThemeData theme) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isMe ? colorScheme.primary : colorScheme.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
                isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight:
                isMe ? const Radius.circular(4) : const Radius.circular(16),
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
            if (!isMe)
              Text(
                message.author.firstName ?? 'Unknown',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 4),
            _buildMessageContent(theme, colorScheme),
            const SizedBox(height: 4),
            _buildMessageStatus(theme),
          ],
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
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          "https://upload.wikimedia.org/wikipedia/commons/9/99/Sample_User_Icon.png",
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 200,
              height: 200,
              color: colorScheme.surfaceVariant,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
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
                : theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          isSeen ? Icons.done_all : Icons.done,
          size: 14,
          color: isSeen ? Colors.white : Colors.white,
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
