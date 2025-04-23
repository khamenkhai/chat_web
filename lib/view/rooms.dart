import 'package:chatly_plus_example/chatly_plus/src/chatly_chat_core.dart';
import 'package:chatly_plus_example/controller/selected_room_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'chat/chat.dart';

class RoomsPage extends ConsumerStatefulWidget {
  const RoomsPage({super.key});

  @override
  ConsumerState<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends ConsumerState<RoomsPage> {
  @override
  void initState() {
    super.initState();
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
  }

  Widget _buildRoomItem(types.Room room) {
    final isSelected = ref.watch(selectedRoomProvider) == room;
    final isLargeScreen = MediaQuery.of(context).size.width >= 800;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isSelected && isLargeScreen
            ? Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Text(
          room.name ?? 'Unknown',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: FutureBuilder(
          future: ChatlyChatCore.instance.getLastMessage(room.id),
          builder: (context, lastMsgSnap) {
            return Text(
              lastMsgSnap.data ?? "No messages yet",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            );
          },
        ),
        trailing: Text(
          formatTimeAgo(room.updatedAt ?? 0),
          style: const TextStyle(fontSize: 11),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No room selected',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a room from the sidebar to start chatting',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
                color: Theme.of(context).colorScheme.inversePrimary,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              const Text(
                'Chats',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'logout') {
                    logout();
                  }
                  if (value == 'users') {
                    context.go("/users");
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Text('Logout'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'Setting',
                    child: Text('Setting'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'users',
                    child: Text('Users'),
                  ),
                ],
              ),
              IconButton(
                  onPressed: () {
                    Text("Hello world!");
                  },
                  icon: Icon(Icons.logout))
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondary,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLargeScreen = constraints.maxWidth >= 800;
            if (!isLargeScreen) {
              return _buildRoomsList();
            } else {
              return Row(
                children: [
                  Container(
                    width: 320,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: Theme.of(context).colorScheme.onTertiary,
                          width: 1,
                        ),
                      ),
                    ),
                    child: _buildRoomsList(),
                  ),
                  Expanded(
                    child: ref.read(selectedRoomProvider.notifier).state == null
                        ? _buildEmptyState()
                        : ChatPage(
                            room:
                                ref.read(selectedRoomProvider.notifier).state!,
                          ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  String formatTimeAgo(int timestamp) {
    return timeago.format(DateTime.fromMillisecondsSinceEpoch(timestamp));
  }
}
