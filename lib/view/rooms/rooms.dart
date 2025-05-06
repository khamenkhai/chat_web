import 'package:chat_web/controller/room_provider.dart';
import 'package:chat_web/controller/selected_room_provider.dart';
import 'package:chat_web/core/component/loading_widget.dart';
import 'package:chat_web/service/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconly/iconly.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:chat_web/models/flutter_chat_types.dart' as types;
import '../chat/chat.dart';

class RoomsPage extends ConsumerStatefulWidget {
  const RoomsPage({super.key});

  @override
  ConsumerState<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends ConsumerState<RoomsPage> {
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("=> room page rebuild!");
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLargeScreen = constraints.maxWidth >= 800;
            return isLargeScreen
                ? Row(
                    children: [
                      _buildRoomsSidebar(),
                      _buildChatArea(),
                    ],
                  )
                : _buildRoomsSidebar();
          },
        ),
      ),
    );
  }

  Widget _buildRoomsSidebar() {
    return Container(
      width: 350,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Colors.grey,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildAppBar(),
          _buildSearchField(),
          const SizedBox(height: 10),
          _buildRoomsList(),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    return Expanded(
      child: ref.watch(selectedRoomProvider) == null
          ? _buildEmptyState()
          : ChatPage(roomId: ref.read(selectedRoomProvider)?.id ?? ""),
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            onSelected: (value) {
              if (value == 'logout') _logout();
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
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      height: 35,
      child: TextField(
        onTap: () => context.go("/search_users"),
        decoration: InputDecoration(
          enabled: false,
          hintText: 'Search...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          filled: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildRoomsList() {
    final roomsAsync = ref.watch(roomsFutureProvider);

    return Expanded(
      child: roomsAsync.when(
        loading: () => LoadingWidget(),
        error: (error, stack) => _buildErrorState(),
        data: (rooms) =>
            rooms.isEmpty ? _buildEmptyListState() : _buildRoomList(rooms),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Text(
        'Error loading rooms',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
      ),
    );
  }

  Widget _buildEmptyListState() {
    return Center(
      child: Text(
        'No rooms available',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }

  Widget _buildRoomList(List<types.Room> rooms) {
    final sortedRooms = List<types.Room>.from(rooms)
      ..sort((a, b) => (b.updatedAt ?? 0).compareTo(a.updatedAt ?? 0));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 1),
      itemCount: sortedRooms.length,
      itemBuilder: (context, index) {
        final room = sortedRooms[index];
        return _buildRoomItem(room);
      },
    );
  }

  Widget _buildRoomItem(types.Room room) {
    final isSelected = ref.watch(selectedRoomProvider) == room;
    final isLargeScreen = MediaQuery.of(context).size.width >= 800;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      // padding: const EdgeInsets.symmetric(horizontal: 8),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isSelected && isLargeScreen
            ? Theme.of(context).colorScheme.primaryContainer.withAlpha(38)
            : Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withAlpha(13),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 5),
        leading: const CircleAvatar(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          _formatTimeAgo(room.updatedAt ?? 0),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        onTap: () => _onRoomTap(room),
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
            Icon(
              IconlyBold.chat,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
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

  String _formatTimeAgo(int timestamp) {
    return timeago.format(DateTime.fromMillisecondsSinceEpoch(timestamp));
  }

  void _onRoomTap(types.Room room) {
    final isLargeScreen = MediaQuery.of(context).size.width >= 800;
    if (isLargeScreen) {
      ref.read(selectedRoomProvider.notifier).state = room;
    } else {
      context.go("/chat/${room.id}", extra: room.id);
    }
  }
}
