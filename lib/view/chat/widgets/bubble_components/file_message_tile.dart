// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:chat_application/fyrechat/fyrechat.dart' as fc;

import 'package:iconly/iconly.dart';

class FileMessageTile extends StatelessWidget {
  final fc.FileMessage message;

  const FileMessageTile({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = _getFileIcon(message.mimeType);
    final fileSize = _formatFileSize(message.size);

    return Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  fileSize,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String? mimeType) {
    if (mimeType == null) return IconlyLight.document;

    if (mimeType.contains('pdf')) return IconlyLight.paper;
    if (mimeType.contains('word')) return IconlyLight.document;
    if (mimeType.contains('excel')) return IconlyLight.chart;
    if (mimeType.contains('powerpoint')) return IconlyLight.document;
    if (mimeType.contains('zip')) return IconlyLight.folder;
    if (mimeType.contains('image')) return IconlyLight.image;
    if (mimeType.contains('audio')) return IconlyLight.voice;
    if (mimeType.contains('video')) return IconlyLight.video;

    return IconlyLight.document;
  }

  String _formatFileSize(num size) {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}




// class FileMessageTile extends StatelessWidget {
  
//   final types.FileMessage message;
//   const FileMessageTile({super.key, required this.message});

//   @override
//   Widget build(BuildContext context) {

//     final theme = Theme.of(context);
//     final icon = _getFileIcon(message.mimeType);

//     return Container(
//       padding: const EdgeInsets.all(8),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 32),
//           const SizedBox(width: 8),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 // width: (message.name.length.toDouble() * 3),
//                 constraints: const BoxConstraints(
//                   maxWidth: 175
//                 ),
//                 child: Text(
//                   message.name,
//                   style: theme.textTheme.bodyMedium,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//               Text(
//                 _formatFileSize(message.size),
//                 style: theme.textTheme.labelSmall?.copyWith(
//                   color: theme.colorScheme.onSurfaceVariant,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

// IconData _getFileIcon(String? mimeType) {
//   if (mimeType == null) return IconlyLight.document;

//   if (mimeType.contains('pdf')) return IconlyLight.paper;
//   if (mimeType.contains('word')) return IconlyLight.document;
//   if (mimeType.contains('excel')) return IconlyLight.chart;
//   if (mimeType.contains('powerpoint')) return IconlyLight.document;
//   if (mimeType.contains('zip')) return IconlyLight.folder;
//   if (mimeType.contains('image')) return IconlyLight.image;
//   if (mimeType.contains('audio')) return IconlyLight.voice;
//   if (mimeType.contains('video')) return IconlyLight.video;

//   return IconlyLight.document;
// }

//   String _formatFileSize(num size) {
//     if (size < 1024) return '$size B';
//     if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
//     return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
//   }
// }
