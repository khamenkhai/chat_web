// ignore_for_file: deprecated_member_use

import 'package:chat_web/chatly_plus/src/chatly_chat_core.dart';
import 'package:chat_web/controller/selected_room_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import '../chat/chat.dart';

// same imports...

class RoomsPage extends ConsumerStatefulWidget {
  const RoomsPage({super.key});

  @override
  ConsumerState<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends ConsumerState<RoomsPage> {
  void logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLargeScreen = constraints.maxWidth >= 800;
            return isLargeScreen
                ? Row(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width / 3,
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Colors.grey,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: _buildRoomsList(),
                      ),
                      Expanded(
                        child: ref.watch(selectedRoomProvider) == null
                            ? _buildEmptyState()
                            : ChatPage(room: ref.watch(selectedRoomProvider)!),
                      ),
                    ],
                  )
                : _buildRoomsList();
          },
        ),
      ),
    );
  }

  String formatTimeAgo(int timestamp) {
    return timeago.format(DateTime.fromMillisecondsSinceEpoch(timestamp));
  }

  Widget _buildRoomItem(types.Room room) {
    final isSelected = ref.watch(selectedRoomProvider) == room;
    final isLargeScreen = MediaQuery.of(context).size.width >= 800;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected && isLargeScreen
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.15)
            : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          room.name ?? 'Unknown',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: FutureBuilder(
          future: ChatlyChatCore.instance.getLastMessage(room.id),
          builder: (context, lastMsgSnap) {
            return Text(
              lastMsgSnap.data ?? "No messages yet",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            );
          },
        ),
        trailing: Text(
          formatTimeAgo(room.updatedAt ?? 0),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        onTap: () {
          if (isLargeScreen) {
            ref.read(selectedRoomProvider.notifier).state = room;
          } else {
            context.go("/chat", extra: room);
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined,
                size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 20),
            Text(
              'No room selected',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a room from the sidebar to start chatting',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomsList() {
    return Column(
      children: [
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Text(
                'Chats',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {},
                tooltip: "More options",
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'logout') logout();
                  if (value == 'users') context.go("/users");
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'logout', child: Text('Logout')),
                  const PopupMenuItem(value: 'Setting', child: Text('Setting')),
                  const PopupMenuItem(value: 'users', child: Text('Users')),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<types.Room>>(
            stream: ChatlyChatCore.instance.rooms(),
            initialData: const [],
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    'No rooms available',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final room = snapshot.data![index];
                  return _buildRoomItem(room);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
