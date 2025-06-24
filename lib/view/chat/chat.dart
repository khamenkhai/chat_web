import 'package:chat_web/controller/selected_room_provider.dart';
import 'package:chat_web/core/component/custom_error_widget.dart';
import 'package:chat_web/core/component/loading_widget.dart';
import 'package:chat_web/chat_service/models/message_models.dart' as types;
import 'package:chat_web/chat_service/models/message_models.dart';
import 'package:chat_web/chat_service/service/chat_service.dart';
import 'package:chat_web/core/utils/format_last_seen.dart';
import 'package:chat_web/view/chat/chat_content.dart';
import 'package:chat_web/view/common/user_avatar.dart';
import 'package:chat_web/view/theme/theme_switch.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Provider for managing reply message state
final replyMessageProvider = StateProvider<types.Message?>((ref) => null);

/// Main chat page widget that displays a chat room
class ChatPage extends StatelessWidget {
  const ChatPage({super.key, required this.roomId});
  final String roomId;

  bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width > 1200;
  }

  @override
  Widget build(BuildContext context) {
    // Add this listener for screen size changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isDesktop(context)) {
        context.go("/");

        // Delay slightly to allow the page to build before popping
        Future.delayed(Duration.zero, () {});
      }
    });

    debugPrint("=> chat page rebuilds!");

    final isMobile = MediaQuery.of(context).size.width < 600;

    // Watch for room data changes
    return Consumer(
      builder: (context, ref, _) {
        // Use `watch` to react to changes (if needed)
        final Room? room = ref.watch(selectedRoomProvider);

        if (room == null) {
          return FutureBuilder(
            future: FyreChat.instance.getRoomById(roomId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingWidget();
              }
              if (snapshot.hasError) {
                return CustomErrorWidget(
                  errorText: "${snapshot.error}",
                ); // Handle errors properly
              }
              // Update state safely (avoid side effects in `builder`)
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(selectedRoomProvider.notifier).setRoom(snapshot.data!);
              });
              return _chatScaffold(room: snapshot.data!, isMobile: isMobile,context: context);
            },
          );
        }
        return _chatScaffold(room: room, isMobile: isMobile,context: context);
      },
    );
  }

  Scaffold _chatScaffold({
    required types.Room room,
    required bool isMobile,
   required BuildContext context
  }) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        title: ListTile(
          contentPadding: const EdgeInsets.all(0),
          minVerticalPadding: 1,
          leading: isMobile
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      
                      onPressed: () {
                        context.go("/");
                      },
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 8),
                    UserAvatar(room: room)
                  ],
                )
              : UserAvatar(room: room),
          title: Text(room.name ?? ""),
          subtitle: StreamBuilder(
            stream: FyreChat.instance.getUserByIdStream(
              room.users
                  .firstWhere(
                      (e) => e.id != FirebaseAuth.instance.currentUser?.uid)
                  .id,
            ),
            builder: (context, snapshot) {
              final bool isOnline = snapshot.data?.isOnline ?? false;
              return Text(
                isOnline
                    ? "Active Now"
                    : formatLastSeen(snapshot.data?.lastSeen),
                style: const TextStyle(fontSize: 12, height: 0),
              );
            },
          ),
        ),
        leadingWidth: 0,
        actions: const [
          ThemeSwitch(),
          SizedBox(width: 10),
        ],
        surfaceTintColor: Colors.transparent,
      ),
      body: ChatContent(room: room),
    );
  }

  String formatTime(int? dateTime) {
    try {
      final formattedTime = DateFormat.jm().format(
        DateTime.fromMillisecondsSinceEpoch(dateTime ?? 0),
      );

      return formattedTime;
    } catch (e) {
      return "Invalid time!";
    }
  }
}
