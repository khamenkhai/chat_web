// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:chat_web/chat_service/models/message_models.dart' as types;
import 'package:chat_web/chat_service/service/chat_service.dart';
import 'package:chat_web/core/component/custom_network_image.dart';
import 'package:chat_web/core/const/size_const.dart';
import 'package:chat_web/core/utils/context_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class ChatRoomTile extends StatefulWidget {
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
  State<ChatRoomTile> createState() => _ChatRoomTileState();
}

class _ChatRoomTileState extends State<ChatRoomTile> {
  types.Message? _lastMessage;
  StreamSubscription<types.Message?>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription =
        FyreChat.instance.lastMessageStream(widget.room.id).listen((message) {
      if (mounted) {
        setState(() {
          _lastMessage = message;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: widget.isSelected && widget.isDesktop
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(SizeConst.radius),
        border: widget.isSelected && widget.isDesktop
            ? Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                width: 1,
              )
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => widget.onTap(widget.room),
          borderRadius: BorderRadius.circular(SizeConst.radius),
          splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          highlightColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final lastMsg = _lastMessage;
    final isSeen = lastMsg?.metadata?['seen'] == true;
    final isDeleted = lastMsg?.isDeleted ?? false;
    final hasUnreadMessages = !isSeen && lastMsg != null;

    String displayText;
    IconData? messageIcon;

    if (lastMsg is types.TextMessage) {
      displayText = lastMsg.text;
    } else if (lastMsg is types.ImageMessage) {
      displayText = 'Photo';
      messageIcon = Icons.image_rounded;
    } else if (lastMsg is types.FileMessage) {
      displayText = 'File';
      messageIcon = Icons.attach_file_rounded;
    } else if (lastMsg == null) {
      displayText = 'No messages yet';
    } else {
      displayText = 'Message';
    }

    return Row(
      children: [
        // Enhanced Avatar
        Stack(
          children: [
            _buildAvatar(widget.room),
            // Unread indicator
            if (hasUnreadMessages)
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

        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name and Time Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.room.name ?? 'Unknown',
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

              // Message Preview Row
              Row(
                children: [
                  // Message status icon
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

                  // Message type icon
                  if (messageIcon != null) ...[
                    Icon(
                      messageIcon,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                  ],

                  // Message text
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

                  // Unread count badge
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
        ),
      ],
    );
  }

  Widget _buildAvatar(types.Room room) {
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
