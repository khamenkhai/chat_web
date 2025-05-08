import 'package:chat_web/controller/chat_provider.dart';
import 'package:chat_web/core/component/loading_widget.dart';
import 'package:chat_web/fire_chat/service/chat_service.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'dart:io';
import 'package:chat_web/controller/selected_room_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:chat_web/fire_chat/models/message_models.dart' as types;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

class MessageInput extends StatefulWidget {
  final Function(String) onSend;

  const MessageInput({
    super.key,
    required this.onSend,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Consumer(
        builder: (context, ref, child) {
          final isAttachmentUploading = ref.watch(attachmentUploadingProvider);

          final isImageUploading = ref.watch(imageUploadingProvider);

          return Row(
            children: [
              isAttachmentUploading
                  ? LoadingWidget()
                  : IconButton(
                      icon: Icon(
                        IconlyLight.folder,
                        color: Theme.of(context).disabledColor,
                      ),
                      onPressed: () => _handleFileSelection(ref),
                    ),
              isImageUploading
                  ? LoadingWidget()
                  : IconButton(
                      icon: Icon(
                        IconlyLight.image_2,
                        color: Theme.of(context).disabledColor,
                      ),
                      onPressed: () => _handleImageSelection(ref, context),
                    ),
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (text) {
                    setState(() {});
                  },
                ),
              ),
              IconButton(
                icon: Icon(
                  IconlyBold.send,
                  color: _textController.text.trim().isEmpty
                      ? Theme.of(context).disabledColor
                      : Theme.of(context).colorScheme.primary,
                ),
                onPressed: _textController.text.trim().isEmpty
                    ? null
                    : () {
                        widget.onSend(_textController.text);
                        _textController.clear();
                        setState(() {});
                      },
              ),
            ],
          );
        },
      ),
    );
  }

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

        final room = ref.read(selectedRoomProvider.notifier).state;

        if (room != null) {
          FireChat.instance.sendMessage(message, room.id);
        }
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

      ref.read(imageUploadingProvider.notifier).state = true;

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
      final room = ref.read(selectedRoomProvider.notifier).state;
      if (room != null) {
        FireChat.instance.sendMessage(message, room.id);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
    } finally {
      ref.read(imageUploadingProvider.notifier).state = false;
    }
  }
}
