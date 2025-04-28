// Your imports remain the same
import 'dart:io';
import 'package:chat_web/chatly_plus/src/chatly_chat_core.dart';
import 'package:chat_web/view/chat/widgets/message_widget.dart';
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
import 'package:logger/logger.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';

// Stream provider for messages
final messagesStreamProvider = StreamProvider.autoDispose
    .family<List<types.Message>, types.Room>((ref, room) {
  return ChatlyChatCore.instance.messages(room);
});

// Stream provider for room updates
final roomStreamProvider =
    StreamProvider.autoDispose.family<types.Room, String>((ref, roomId) {
  return ChatlyChatCore.instance.room(roomId);
});

// Provider for attachment uploading state
final attachmentUploadingProvider =
    StateProvider.autoDispose<bool>((ref) => false);

// Reply message state
final replyMessageProvider = StateProvider<types.Message?>((ref) => null);

class ChatPage extends StatelessWidget {
  const ChatPage({super.key, required this.room});
  final types.Room room;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Text(room.name ?? ""),
        actions: const [ThemeSwitch()],
        elevation: 10,
        surfaceTintColor: Colors.transparent,
      ),
      body: _ChatContent(room: room),
    );
  }
}

class _ChatContent extends ConsumerWidget {
  _ChatContent({required this.room});
  final types.Room room;

  static const String _photoText = 'Photo';
  static const String _fileText = 'File';
  static const String _cancelText = 'Cancel';

  Future<void> _handleFileSelection(WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      ref.read(attachmentUploadingProvider.notifier).state = true;
      final file = File(result.files.single.path!);
      final name = result.files.single.name;

      try {
        final reference = FirebaseStorage.instance.ref(name);
        await reference.putFile(file);
        final uri = await reference.getDownloadURL();

        final message = types.PartialFile(
          mimeType: lookupMimeType(file.path),
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
      WidgetRef ref, BuildContext context) async {
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

  // // Marks messages as seen when the room is opened
  // void _onRoomOpened(String roomId, List<types.Message> messages) async {
  //   for (final message in messages) {
  //     if (message.author.id != FirebaseAuth.instance.currentUser?.uid) {
  //       await ChatlyChatCore.instance.markMessageAsSeen(roomId, message.id);
  //     }
  //   }
  // }

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
                          final message = messages[index];
                          final isMe = message.author.id ==
                              FirebaseAuth.instance.currentUser?.uid;

                          // _onRoomOpened(room.id, messages);
                          if (message.author.id !=
                              FirebaseAuth.instance.currentUser?.uid) {
                            ChatlyChatCore.instance
                                .markMessageAsSeen(room.id, message.id);
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
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
                                        .read(replyMessageProvider.notifier)
                                        .state = message;
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: messages.length,
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
                  ///to send reply message
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
}
