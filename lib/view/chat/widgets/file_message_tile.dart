import 'package:flutter/material.dart';

import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class FileMessageTile extends StatelessWidget {
  final types.FileMessage message;

  const FileMessageTile({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          Icon(_getFileIcon(message.mimeType), size: 32),
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
    const defaultIcon = Icons.insert_drive_file;
    if (mimeType == null) return defaultIcon;

    final iconMap = {
      'pdf': Icons.picture_as_pdf,
      'word': Icons.description,
      'excel': Icons.table_chart,
      'powerpoint': Icons.slideshow,
      'zip': Icons.archive,
      'image': Icons.image,
      'audio': Icons.audiotrack,
      'video': Icons.videocam,
    };

    for (final entry in iconMap.entries) {
      if (mimeType.contains(entry.key)) return entry.value;
    }

    return defaultIcon;
  }

  String _formatFileSize(num size) {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}