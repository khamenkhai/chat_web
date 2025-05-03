import 'dart:io';
import 'package:chat_web/controller/chat_provider.dart';
import 'package:chat_web/controller/selected_room_provider.dart';
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
import 'package:logger/logger.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';

// Provider for tracking attachment upload state
final attachmentUploadingProvider =
    StateProvider.autoDispose<bool>((ref) => false);

// Provider for managing reply message state
final replyMessageProvider = StateProvider<types.Message?>((ref) => null);

/// Main chat page widget that displays a chat room
class ChatPage extends StatelessWidget {
  const ChatPage({super.key, required this.roomId});
  final String roomId;

  @override
  Widget build(BuildContext context) {
    debugPrint("=> chat page rebuilds!");
    // Watch for room data changes
    return Consumer(
      builder: (context, ref, _) {
        final room = ref.read(selectedRoomProvider.notifier).state;
        return Scaffold(
          appBar: AppBar(
            systemOverlayStyle: SystemUiOverlayStyle.light,
            title: Text(room?.name ?? ""),
            actions: const [ThemeSwitch()],
            elevation: 10,
            surfaceTintColor: Colors.transparent,
          ),
          body: room == null ? Container() : _ChatContent(room: room),
        );
      },
    );
  }
}

class _ChatContent extends StatelessWidget {
  _ChatContent({required this.room});
  final types.Room room;

  Future<void> _handleFileSelection(WidgetRef ref) async {
    final result =
        await FilePicker.platform.pickFiles(withData: true); // <-- important
    if (result != null && result.files.single.bytes != null) {
      ref.read(attachmentUploadingProvider.notifier).state = true;

      final fileBytes = result.files.single.bytes!;
      final name = result.files.single.name;

      try {
        final reference = FirebaseStorage.instance.ref(name);
        await reference
            .putData(fileBytes); // <-- use putData instead of putFile
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
  Widget build(BuildContext context) {
    debugPrint("=> chat content rebuilds!");
    return Consumer(
      builder: (context, ref, child) {
        final messagesAsync = ref.watch(messagesStreamProvider(room));
        final isAttachmentUploading = ref.watch(attachmentUploadingProvider);
        final replyTo = ref.watch(replyMessageProvider);
        return messagesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
          data: (messages) {
            debugPrint("=> message rebuilds!");
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
                                        showMessageOptionsDialog(
                                          context: context,
                                          onEdit: () {},
                                          onReply: () {
                                            ref
                                                .read(replyMessageProvider
                                                    .notifier)
                                                .state = message;
                                          },
                                        );
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
                  _replyToWidget(replyTo, ref),
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
                  handleImageSelection: () =>
                      _handleImageSelection(ref, context),
                  handleFileSelection: () => _handleFileSelection(ref),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Container _replyToWidget(types.Message replyTo, WidgetRef ref) {
    return Container(
                  color: Colors.grey[200],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
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
                        onPressed: () => ref
                            .read(replyMessageProvider.notifier)
                            .state = null,
                      )
                    ],
                  ),
                );
  }

  Future<void> showMessageOptionsDialog({
    required BuildContext context,
    required VoidCallback onEdit,
    required VoidCallback onReply,
  }) {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 120, vertical: 200),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 20.0),
                child: Text(
                  "Message Options",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 20),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blueAccent),
                title: const Text("Edit Message"),
                onTap: () {
                  Navigator.pop(context);
                  onEdit();
                },
              ),
              ListTile(
                leading: const Icon(Icons.reply, color: Colors.green),
                title: const Text("Reply to Message"),
                onTap: () {
                  Navigator.pop(context);
                  onReply();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
