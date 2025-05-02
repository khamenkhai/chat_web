import 'dart:io';
import 'package:chat_web/controller/chat_provider.dart';
import 'package:chat_web/controller/room_provider.dart';
import 'package:chat_web/service/chat_service.dart';
import 'package:chat_web/view/chat/widgets/message_bubble.dart';
import 'package:chat_web/view/chat/widgets/message_input.dart';
import 'package:chat_web/view/theme/theme_switch.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';

// Provider for attachment uploading state
final attachmentUploadingProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

// Reply message state
final replyMessageProvider = StateProvider<types.Message?>((ref) => null);

class ChatPage extends ConsumerWidget {
  const ChatPage({super.key, required this.roomId});
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomStreamProvider(roomId));

    return roomAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $error')),
      ),
      data: (room) => Scaffold(
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle.light,
          title: Text(room.name ?? ""),
          actions: const [
            ThemeSwitch(),
          ],
          elevation: 10,
          surfaceTintColor: Colors.transparent,
        ),
        body: _ChatContent(room: room),
      ),
    );
  }
}

class _ChatContent extends ConsumerWidget {
  _ChatContent({required this.room});

  final types.Room room;

  static const String _photoText = 'Photo';
  static const String _fileText = 'File';
  static const String _cancelText = 'Cancel';

  // Helper function to group messages by day
  Map<DateTime, List<types.Message>> _groupMessagesByDay(
      List<types.Message> messages) {
    final Map<DateTime, List<types.Message>> groupedMessages = {};

    for (final message in messages) {
      final messageDate =
          DateTime.fromMillisecondsSinceEpoch(message.createdAt!);
      final day =
          DateTime(messageDate.year, messageDate.month, messageDate.day);

      if (groupedMessages.containsKey(day)) {
        groupedMessages[day]!.add(message);
      } else {
        groupedMessages[day] = [message];
      }
    }

    return groupedMessages;
  }

  // Helper function to format day header
  String _formatDayHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE, MMMM d').format(date);
    }
  }

  Future<void> _handleFileSelection(WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null && result.files.single.bytes != null) {
      ref.read(attachmentUploadingProvider.notifier).state = true;

      final fileBytes = result.files.single.bytes!;
      final name = result.files.single.name;

      try {
        final reference = FirebaseStorage.instance.ref(name);
        await reference.putData(fileBytes);
        final uri = await reference.getDownloadURL();

        final message = types.PartialFile(
          mimeType: lookupMimeType(name),
          name: name,
          size: result.files.single.size,
          uri: uri,
        );

        ChatlyChatCore.instance.sendMessage(message, room.id);
      } finally {
        ref.read(attachmentUploadingProvider.notifier).state = false;
      }
    }
  }

  Future<void> _handleImageSelection(
    WidgetRef ref,
    BuildContext context,
  ) async {
    final picker = ImagePicker();
    try {
      final result = await picker.pickImage(
          imageQuality: 70, maxWidth: 1440, source: ImageSource.gallery);
      if (result == null) return;

      ref.read(attachmentUploadingProvider.notifier).state = true;

      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${result.name}';
      final reference = FirebaseStorage.instance.ref().child(fileName);

      final uploadTask = kIsWeb
          ? reference.putData(
              bytes, SettableMetadata(contentType: 'image/jpeg'))
          : reference.putFile(File(result.path));

      final snapshot = await uploadTask;
      final uri = await snapshot.ref.getDownloadURL();

      final message = types.PartialImage(
        height: image.height.toDouble(),
        name: result.name,
        size: bytes.length,
        uri: uri,
        width: image.width.toDouble(),
      );

      ChatlyChatCore.instance.sendMessage(message, room.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
    } finally {
      ref.read(attachmentUploadingProvider.notifier).state = false;
    }
  }

  void _handleAttachmentPressed(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: SizedBox(
          height: 144,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleImageSelection(ref, context);
                },
                child: const Align(
                    alignment: Alignment.centerLeft, child: Text(_photoText)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleFileSelection(ref);
                },
                child: const Align(
                    alignment: Alignment.centerLeft, child: Text(_fileText)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Align(
                    alignment: Alignment.centerLeft, child: Text(_cancelText)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleMessageTap(
      BuildContext context, types.Message message) async {
    if (message is types.FileMessage && message.uri.startsWith('http')) {
      try {
        final updated = message.copyWith(isLoading: true);
        ChatlyChatCore.instance.updateMessage(updated, room.id);

        final res = await http.get(Uri.parse(message.uri));
        final dir = (await getApplicationDocumentsDirectory()).path;
        final localPath = '$dir/${message.name}';

        if (!File(localPath).existsSync()) {
          await File(localPath).writeAsBytes(res.bodyBytes);
        }
      } finally {
        final updated = message.copyWith(isLoading: false);
        ChatlyChatCore.instance.updateMessage(updated, room.id);
      }
    }
  }

  final Logger logger = Logger();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(messagesStreamProvider(room));
    final isAttachmentUploading = ref.watch(attachmentUploadingProvider);
    final replyTo = ref.watch(replyMessageProvider);

    return messagesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (messages) {
        // Group messages by day
        final groupedMessages = _groupMessagesByDay(messages);
        final sortedDays = groupedMessages.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        return Column(
          children: [
            Expanded(
              child: CustomScrollView(
                reverse: true,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final day = sortedDays[index];
                          final dayMessages = groupedMessages[day]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Day header
                              _dayHeader(context, day),
                              // Messages for this day
                              ...dayMessages.map((message) {
                                final isMe = message.author.id ==
                                    FirebaseAuth.instance.currentUser?.uid;

                                if (message.author.id !=
                                    FirebaseAuth.instance.currentUser?.uid) {
                                  ChatlyChatCore.instance
                                      .markMessageAsSeen(room.id, message.id);
                                }

                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Align(
                                    alignment: isMe
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                                0.75,
                                      ),
                                      child: MessageBubble(
                                        message: message,
                                        isMe: isMe,
                                        roomId: room.id,
                                        metadata: message.metadata,
                                        onTap: () =>
                                            _handleMessageTap(context, message),
                                        onLongPress: () {
                                          ref
                                              .read(
                                                  replyMessageProvider.notifier)
                                              .state = message;
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          );
                        },
                        childCount: sortedDays.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (replyTo != null)
              Container(
                color: Colors.grey[200],
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        replyTo is types.TextMessage
                            ? replyTo.text
                            : 'Replying...',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () =>
                          ref.read(replyMessageProvider.notifier).state = null,
                    )
                  ],
                ),
              ),
            if (isAttachmentUploading)
              const LinearProgressIndicator(minHeight: 2),
            MessageInput(
              onSend: (text) {
                final reply = ref.read(replyMessageProvider);

                if (reply != null) {
                  ChatlyChatCore.instance.sendReply(
                    originalMessage: reply,
                    partialReply: types.PartialText(text: text),
                    roomId: room.id,
                  );
                } else {
                  ChatlyChatCore.instance.sendMessage(
                    types.PartialText(text: text),
                    room.id,
                  );
                }

                ref.read(replyMessageProvider.notifier).state = null;
              },
              onAttachmentPressed: () => _handleAttachmentPressed(context, ref),
            ),
          ],
        );
      },
    );
  }

  Padding _dayHeader(BuildContext context, DateTime day) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          child: Text(
            _formatDayHeader(day),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
          ),
        ),
      ),
    );
  }
}
