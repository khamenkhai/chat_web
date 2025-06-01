import 'package:chat_web/chat_service/models/message_models.dart' as types;
import 'package:chat_web/chat_service/service/chat_service.dart';
import 'package:chat_web/core/component/custom_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatRoomTile extends StatelessWidget {
  final types.Room room;
  final void Function(types.Room) onTap;
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
      margin: const EdgeInsets.symmetric(
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: isSelected && isDesktop
            ? Theme.of(context).colorScheme.primaryContainer.withAlpha(38)
            : Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withAlpha(13),
        borderRadius: BorderRadius.circular(12),
      ),
      child: StreamBuilder<types.Message?>(
        stream: FyreChat.instance.lastMessageStream(room.id),
        builder: (context, snapshot) {
          final lastMsg = snapshot.data;
          final isSeen = lastMsg?.metadata?['seen'] == true;

          final isDeleted = lastMsg?.isDeleted ?? false;

          String displayText;
          if (lastMsg is types.TextMessage) {
            displayText = lastMsg.text;
          } else if (lastMsg is types.ImageMessage) {
            displayText = '🖼️ Image';
          } else if (lastMsg is types.FileMessage) {
            displayText = '📄 File';
          } else if (lastMsg == null) {
            displayText = 'No messages';
          } else {
            displayText = 'Unsupported message';
          }

          return InkWell(
            onTap: () => onTap(room),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                // Add background color or elevation if needed
              ),
              child: Row(
                children: [
                  _buildAvatar(room),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              room.name ?? 'Unknown',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              _formatTimeAgo(snapshot.data?.updatedAt ?? 0),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            displayText == "No messages"
                                ? Container()
                                : Icon(
                                    isSeen ? Icons.done_all : Icons.done,
                                    size: 12,
                                    color: isSeen
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                  ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                isDeleted ? "Deleted" : displayText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar(types.Room room) {
    final name = room.name ?? '';

    return CircleAvatar(
      radius: 20,
      child: SizedBox(
        width: 40,
        height: 40,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: CustomNetworkImage(
            imageUrl: room.imageUrl ?? "",
            errorWidget: Center(
              child: Text(
                name.isEmpty ? '' : name[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
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

    if (diff.inDays > 5) {
      // Show formatted date like 31/1/2024
      return DateFormat('d/M/yyyy').format(date);
    }

    // Show time ago string like "4 days ago", "2h ago", etc.
    return timeago.format(date);
  }
}
