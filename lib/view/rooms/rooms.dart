import 'package:chat_web/chat_service/service/chat_service.dart';
import 'package:chat_web/controller/room_provider.dart';
import 'package:chat_web/controller/selected_room_provider.dart';
import 'package:chat_web/core/component/loading_widget.dart';
import 'package:chat_web/core/const/size_const.dart';
import 'package:chat_web/core/utils/context_extension.dart';
import 'package:chat_web/view/rooms/widgets/chat_room_tile.dart';
import 'package:chat_web/view/rooms/widgets/rooms_empty.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:chat_web/chat_service/models/message_models.dart' as types;
import '../chat/chat.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class RoomsPage extends ConsumerStatefulWidget {
  const RoomsPage({super.key});

  @override
  ConsumerState<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends ConsumerState<RoomsPage>
    with WidgetsBindingObserver {
  bool switchValue = false;

  Future<void> _logout() async {
    setOnline(false);
    await FirebaseAuth.instance.signOut();
    ref.read(selectedRoomProvider.notifier).setRoom(null);
  }

  void showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Logout"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text("Are you sure you want to logout?")],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () => _logout(),
              child: Text("Log Out"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      html.document.addEventListener(
        'visibilitychange',
        (event) {
          if (html.document.visibilityState == 'visible') {
            setOnline(true);
          } else {
            setOnline(false);
          }
        },
      );

      // Handle window closing
      html.window.addEventListener('beforeunload', (event) {
        setOnline(false);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!kIsWeb) {
      // Mobile behavior
      if (state == AppLifecycleState.resumed) {
        setOnline(true);
      } else if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.detached) {
        setOnline(false);
      }
    }
  }

  void setOnline(bool online) {
    FyreChat.instance.setOnline(online);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("=> room page rebuild!");
    return ScreenTypeLayout.builder(
      mobile: (context) {
        return Scaffold(
          body: SafeArea(child: _buildRoomsSidebar(isMobile: true)),
        );
      },
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
      padding: EdgeInsets.symmetric(horizontal: SizeConst.kHorizontalPadding),
      decoration: BoxDecoration(
        border: isMobile
            ? Border()
            : Border(
                right: BorderSide(
                  color: context.tertiary,
                  width: 1,
                ),
              ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          FutureBuilder(
            future: FyreChat.instance
                .getUserById(FirebaseAuth.instance.currentUser?.uid ?? ""),
            builder: (context, snapshot) {
              final types.User? user = snapshot.data;
              final hasImage = user?.imageUrl != null;
              if (snapshot.hasData) {
                return Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        context.go("/profile");
                      },
                      child: CircleAvatar(
                        backgroundColor:
                            hasImage ? Colors.transparent : Colors.blue,
                        backgroundImage: hasImage
                            ? NetworkImage(user?.imageUrl ?? "")
                            : null,
                        radius: 16,
                        child: !hasImage
                            ? Text(
                                user!.fullName.toString(),
                                style: const TextStyle(color: Colors.white),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: _buildSearchField()),
                  ],
                );
              } else {
                return Container();
              }
            },
          ),
          const SizedBox(height: 8),
          _buildAppBar(),
         
          const SizedBox(height: 8),
          _buildRoomsList(),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    return Expanded(
      child: ref.watch(selectedRoomProvider) == null
          ? RoomsEmpty()
          : ChatPage(roomId: ""),
    );
  }

  Widget _buildAppBar() {
    return Row(
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
            if (value == 'logout') showLogoutDialog();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'logout', child: Text('Logout')),
            const PopupMenuItem(value: 'Setting', child: Text('Setting')),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return GestureDetector(
      onTap: () => context.go("/users"),
      child: Container(
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
        data: (rooms) {
          if (rooms.isEmpty) {
            ref.read(selectedRoomProvider.notifier).setRoom(null);
          }
          return rooms.isEmpty ? _buildEmptyListState() : _buildRoomList(rooms);
        },
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
        final isSelected = ref.watch(selectedRoomProvider) == room;
        final isDesktop = getDeviceType(MediaQuery.of(context).size) ==
            DeviceScreenType.desktop;

        return ChatRoomTile(
          isDesktop: isDesktop,
          isSelected: isSelected,
          room: room,
          onTap: (p0) {
            _onRoomTap(room);
          },
        );
      },
    );
  }

  void _onRoomTap(types.Room room) {
    final deviceType = getDeviceType(MediaQuery.of(context).size);
    final isDesktop = deviceType == DeviceScreenType.desktop;
    // ||   deviceType == DeviceScreenType.tablet;

    if (isDesktop) {
      ref.read(selectedRoomProvider.notifier).setRoom(room);
    } else {
      ref.read(selectedRoomProvider.notifier).setRoom(room);
      context.go("/chat/${room.id}", extra: room.id);
    }
  }
}
