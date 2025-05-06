import 'package:flutter/material.dart';
import 'package:chat_web/models/flutter_chat_types.dart' as types;
import 'package:iconly/iconly.dart';

class FileMessageTile extends StatelessWidget {
  final types.FileMessage message;

  const FileMessageTile({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = _getFileIcon(message.mimeType);

    return Container(
      padding: const EdgeInsets.all(8),
      margin: EdgeInsets.symmetric(horizontal: 10),
    
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
    if (mimeType == null) return IconlyLight.document;

    if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
    if (mimeType.contains('word')) return Icons.description;
    if (mimeType.contains('excel')) return Icons.table_chart;
    if (mimeType.contains('powerpoint')) return Icons.slideshow;
    if (mimeType.contains('zip')) return Icons.archive;
    if (mimeType.contains('image')) return Icons.image;
    if (mimeType.contains('audio')) return Icons.audiotrack;
    if (mimeType.contains('video')) return Icons.videocam;

    return IconlyLight.document;
  }

  String _formatFileSize(num size) {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
