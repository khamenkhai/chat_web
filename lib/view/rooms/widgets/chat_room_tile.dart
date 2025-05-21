import 'package:chat_web/chat_service/models/message_models.dart' as types;
import 'package:chat_web/chat_service/service/chat_service.dart';
import 'package:chat_web/view/utils/util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatRoomTile extends StatelessWidget {
  final types.Room room;
  final void Function(types.Room) onTap;

  const ChatRoomTile({
    super.key,
    required this.room,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<types.Message?>(
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
          displayText = '...';
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
                          Icon(
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
    );
  }

  Widget _buildAvatar(types.Room room) {
    var color = Colors.transparent;

    if (room.type == types.RoomType.direct) {
      try {
        final otherUser = room.users
            .firstWhere((u) => u.id != FirebaseAuth.instance.currentUser?.uid);

        color = getUserAvatarNameColor(otherUser);
      } catch (e) {
        // Do nothing if other user is not found.
      }
    }

    final hasImage = room.imageUrl != null;
    final name = room.name ?? '';

    return CircleAvatar(
      backgroundColor: hasImage ? Colors.transparent : color,
      backgroundImage: hasImage ? NetworkImage(room.imageUrl!) : null,
      radius: 20,
      child: !hasImage
          ? Text(
              name.isEmpty ? '' : name[0].toUpperCase(),
              style: const TextStyle(color: Colors.white),
            )
          : null,
    );
  }

  String _formatTimeAgo(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
