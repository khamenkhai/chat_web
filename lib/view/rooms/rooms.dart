import 'package:chat_web/chat_service/service/chat_service.dart';
import 'package:chat_web/controller/room_provider.dart';
import 'package:chat_web/controller/selected_room_provider.dart';
import 'package:chat_web/core/component/loading_widget.dart';
import 'package:chat_web/core/utils/context_extension.dart';
import 'package:chat_web/view/rooms/widgets/chat_room_tile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconly/iconly.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:chat_web/chat_service/models/message_models.dart' as types;
import '../chat/chat.dart';

class RoomsPage extends ConsumerStatefulWidget {
  const RoomsPage({super.key});

  @override
  ConsumerState<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends ConsumerState<RoomsPage>
    with WidgetsBindingObserver {
  Future<void> _logout() async {
    setOnline(false);
    await FirebaseAuth.instance.signOut();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setOnline(true); // Don't update lastSeen here
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      setOnline(false); // lastSeen will be updated in here
    }
  }

  void setOnline(bool online) {
    FyreChat.instance.setOnline(online);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("=> room page rebuild!");
    return ScreenTypeLayout.builder(
      mobile: (context) => Scaffold(
        body: SafeArea(child: _buildRoomsSidebar(isMobile: true)),
      ),
      tablet: (context) => Scaffold(
        body: SafeArea(child: _buildRoomsSidebar(isMobile: true)),
      ),
      desktop: (context) => Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              _buildRoomsSidebar(),
              _buildChatArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomsSidebar({bool isMobile = false}) {
    return Container(
      width: isMobile ? double.infinity : 350,
      decoration: BoxDecoration(
        border: isMobile
            ? Border()
            : Border(
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
          : ChatPage(),
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
    return GestureDetector(
      onTap: () => context.go("/users"),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 7),
        padding: EdgeInsets.only(left: 15),
        height: 35,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: context.colorScheme.tertiary,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Search...",
              textAlign: TextAlign.start,
              style: TextStyle(color: context.colorScheme.onSurfaceVariant),
            ),
          ],
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
    final isDesktop =
        getDeviceType(MediaQuery.of(context).size) == DeviceScreenType.desktop;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(
        horizontal: 8,
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
      child: ChatRoomTile(
        room: room,
        onTap: (p0) {
          _onRoomTap(room);
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

  void _onRoomTap(types.Room room) {
    final deviceType = getDeviceType(MediaQuery.of(context).size);
    final isDesktop = deviceType == DeviceScreenType.desktop;
    // ||   deviceType == DeviceScreenType.tablet;

    if (isDesktop) {
      ref.read(selectedRoomProvider.notifier).state = room;
    } else {
      context.go("/chat/${room.id}", extra: room.id);
    }
  }
}

