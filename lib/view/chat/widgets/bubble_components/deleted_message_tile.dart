import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeWidget = Text(
      _formatTime(createdAt ?? 0),
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurface.withAlpha(150),
      ),
    );

    return Container(
      margin: EdgeInsets.only(
        right: isMe ? 50 : 0,
        left: isMe ? 50 : 0,
        top: 2,
        bottom: 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (isMe)
            Container(
              margin: const EdgeInsets.only(right: 10),
              child: timeWidget,
            ),
          _buildDeletedBox(theme),
          if (!isMe)
            Container(
              margin: const EdgeInsets.only(left: 10),
              child: timeWidget,
            ),
        ],
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
}
