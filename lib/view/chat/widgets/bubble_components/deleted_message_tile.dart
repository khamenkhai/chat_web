import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

class DeletedMessageTile extends StatelessWidget {
  final bool isMe;
  final int? createdAt;

  const DeletedMessageTile({
    super.key,
    required this.isMe,
    required this.createdAt,
  });

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(
        right: isMe ? 50 : 0,
        left: isMe ? 50 : 50,
        top: 2,
        bottom: 2,
      ),
      child: _buildDeletedBox(theme),
    );
  }

  Widget _buildDeletedBox(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                IconlyLight.delete,
                size: 18,
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Text(
                "This message was deleted".tr(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(150),
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Text(
            _formatTime(createdAt ?? 0),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(150),
            ),
          ),
        ],
      ),
    );
  }
}
