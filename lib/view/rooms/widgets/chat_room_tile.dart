// ignore_for_file: deprecated_member_use
import 'package:chat_application/fyrechat/fyrechat.dart' as fc;
import 'package:chat_application/core/component/custom_network_image.dart';
import 'package:chat_application/core/const/size_const.dart';
import 'package:chat_application/core/utils/context_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class ChatRoomTile extends StatelessWidget {
  final fc.Room room;
  final void Function(fc.Room) onTap;
  final bool isSelected;
  final bool isDesktop;

  const ChatRoomTile({
    super.key,
    required this.room,
    required this.onTap,
    required this.isSelected,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected && isDesktop
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(SizeConst.radius),
        border: isSelected && isDesktop
            ? Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                width: 1,
              )
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => onTap(room),
          borderRadius: BorderRadius.circular(SizeConst.radius),
          splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          highlightColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    _buildAvatar(room, context),
                    // if (hasUnreadMessages)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 16),

                _buildContentWithStream(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentWithStream() {
    return StreamBuilder<fc.Message?>(
      stream: fc.FyreChat.instance.lastMessageStream(room.id),
      builder: (context, snapshot) {
        final lastMsg = snapshot.data;
        final isSeen = lastMsg?.metadata?['seen'] == true;
        final isDeleted = lastMsg?.isDeleted ?? false;
        final hasUnreadMessages = !isSeen && lastMsg != null;

        String displayText;
        IconData? messageIcon;

        if (lastMsg is fc.TextMessage) {
          displayText = lastMsg.text;
        } else if (lastMsg is fc.ImageMessage) {
          displayText = 'Photo';
          messageIcon = Icons.image_rounded;
        } else if (lastMsg is fc.FileMessage) {
          displayText = 'File';
          messageIcon = Icons.attach_file_rounded;
        } else if (lastMsg == null) {
          displayText = 'No messages yet';
        } else {
          displayText = 'Message';
        }

        return Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name + time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      room.name ?? 'Unknown',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: hasUnreadMessages
                                ? FontWeight.w700
                                : FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (displayText != "No messages yet")
                    Text(
                      _formatTimeAgo(lastMsg?.updatedAt ?? 0),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: hasUnreadMessages
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                            fontWeight: hasUnreadMessages
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                    ),
                ],
              ),

              const SizedBox(height: 6),

              // Message preview
              Row(
                children: [
                  if (displayText != "No messages yet") ...[
                    Icon(
                      isSeen ? Icons.done_all_rounded : Icons.done_rounded,
                      size: 14,
                      color: isSeen
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withOpacity(0.7),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (messageIcon != null) ...[
                    Icon(
                      messageIcon,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      isDeleted ? "This message was deleted" : displayText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (hasUnreadMessages)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(SizeConst.radius),
                      ),
                      child: Text(
                        '1',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar(fc.Room room, BuildContext context) {
    final name = room.name ?? '';

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 24,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: CachedImage(
            imageUrl: room.imageUrl ?? "",
            width: 48,
            height: 48,
            errorWidget: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name.isEmpty ? '?' : name[0].toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 6) {
      return DateFormat('MMM d').format(date);
    } else if (diff.inDays > 0) {
      return DateFormat('EEE').format(date);
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
