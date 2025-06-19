// ignore_for_file: deprecated_member_use

import 'package:chat_web/chat_service/fyrechat.dart';
import 'package:chat_web/controller/room_provider.dart';
import 'package:chat_web/controller/selected_room_provider.dart';
import 'package:chat_web/core/const/size_const.dart';
import 'package:chat_web/view/rooms/widgets/chat_room_tile.dart';
import 'package:chat_web/view/rooms/widgets/rooms_empty.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:chat_web/chat_service/models/message_models.dart' as types;
import 'package:skeletonizer/skeletonizer.dart';
import 'dart:async';
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Logout",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Are you sure you want to logout?",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Cancel",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            FilledButton(
              onPressed: () => _logout(),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(
                "Log Out",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onError,
                ),
              ),
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
      width: isMobile ? double.infinity : 380,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: isMobile
            ? null
            : Border(
                right: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
      ),
      child: Column(
        children: [
          // Header Section with improved spacing and elevation
          Container(
            padding: const EdgeInsets.fromLTRB(
              SizeConst.kHorizontalPadding,
              20,
              SizeConst.kHorizontalPadding,
              16,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildUserProfileSection(),
                const SizedBox(height: 20),
                _buildAppBar(),
                const SizedBox(height: 16),
                _buildSearchField(),
              ],
            ),
          ),
          
          // Rooms List Section
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SizeConst.kHorizontalPadding,
              ),
              child: _buildRoomsList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileSection() {
    return FutureBuilder(
      future: FyreChat.instance
          .getUserById(FirebaseAuth.instance.currentUser?.uid ?? ""),
      builder: (context, snapshot) {
        final types.User? user = snapshot.data;
        final hasImage = user?.imageUrl != null;
        
        if (snapshot.hasData) {
          return Row(
            children: [
              // Enhanced Avatar with online indicator
              Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      context.go("/profile");
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.shadow.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        backgroundColor: hasImage 
                          ? Colors.transparent 
                          : Theme.of(context).colorScheme.primary,
                        backgroundImage: hasImage
                            ? NetworkImage(user?.imageUrl ?? "")
                            : null,
                        radius: 22,
                        child: !hasImage
                            ? Text(
                                user?.fullName.isNotEmpty == true 
                                  ? user!.fullName[0].toUpperCase()
                                  : '?',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  // Online status indicator
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
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
              
              // User info section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'Unknown User',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Online',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        } else {
          return SizedBox(
            height: 44,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 16,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 12,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildChatArea() {
    return Expanded(
      child: ref.watch(selectedRoomProvider) == null
          ? const RoomsEmpty()
          : const ChatPage(roomId: ""),
    );
  }

  Widget _buildAppBar() {
    return Row(
      children: [
        Text(
          'Messages',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.more_vert_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            onSelected: (value) {
              if (value == 'logout') showLogoutDialog();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'Setting',
                child: Row(
                  children: [
                    Icon(
                      Icons.settings_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return GestureDetector(
      onTap: () => context.go("/users"),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              "Search conversations...",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomsList() {
    final roomsAsync = ref.watch(roomsStreamProvider);

    return roomsAsync.when(
      loading: () => _buildRoomList([
        const Room(id: "dfdfdfadf", users: [], type: null, imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRuNhTZJTtkR6b-ADMhmzPvVwaLuLdz273wvQ&s"),
        const Room(id: "dfdfdfadf", users: [], type: null, imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRuNhTZJTtkR6b-ADMhmzPvVwaLuLdz273wvQ&s"),
        const Room(id: "dfdfdfadf", users: [], type: null, imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRuNhTZJTtkR6b-ADMhmzPvVwaLuLdz273wvQ&s"),
        const Room(id: "dfdfdfadf", users: [], type: null, imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRuNhTZJTtkR6b-ADMhmzPvVwaLuLdz273wvQ&s"),
        const Room(id: "dfdfdfadf", users: [], type: null, imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRuNhTZJTtkR6b-ADMhmzPvVwaLuLdz273wvQ&s"),
      ], true),
      error: (error, stack) => _buildErrorState(),
      data: (rooms) {
        if (rooms.isEmpty) {
          ref.read(selectedRoomProvider.notifier).setRoom(null);
        }
        return rooms.isEmpty
            ? _buildEmptyListState()
            : _buildRoomList(rooms, false);
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.error.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading conversations',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please try again later',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyListState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'No conversations yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a new conversation to get started',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomList(List<types.Room> rooms, bool enabled) {
    final sortedRooms = List<types.Room>.from(rooms)
      ..sort((a, b) => (b.updatedAt ?? 0).compareTo(a.updatedAt ?? 0));

    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: sortedRooms.length,
      separatorBuilder: (context, index) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final room = sortedRooms[index];
        final isSelected = ref.watch(selectedRoomProvider) == room;
        final isDesktop = getDeviceType(MediaQuery.of(context).size) ==
            DeviceScreenType.desktop;

        return Skeletonizer(
          enabled: enabled,
          child: ChatRoomTile(
            isDesktop: isDesktop,
            isSelected: isSelected,
            room: room,
            onTap: (p0) {
              _onRoomTap(room);
            },
          ),
        );
      },
    );
  }

  void _onRoomTap(types.Room room) {
    final deviceType = getDeviceType(MediaQuery.of(context).size);
    final isDesktop = deviceType == DeviceScreenType.desktop;

    if (isDesktop) {
      ref.read(selectedRoomProvider.notifier).setRoom(room);
    } else {
      ref.read(selectedRoomProvider.notifier).setRoom(room);
      context.go("/chat/${room.id}", extra: room.id);
    }
  }
}

