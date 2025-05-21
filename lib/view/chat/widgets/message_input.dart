import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:chat_web/controller/chat_provider.dart';
import 'package:chat_web/core/component/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'dart:io';
import 'package:chat_web/controller/selected_room_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:chat_web/chat_service/models/message_models.dart' as types;
import 'package:chat_web/chat_service/service/chat_service.dart';
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
  bool _emojiShowing = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _emojiShowing) {
        setState(() => _emojiShowing = false);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onEmojiSelected(category, Emoji emoji) {
    _textController
      ..text += emoji.emoji
      ..selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length));
  }

  void _onBackspacePressed() {
    _textController
      ..text = _textController.text.characters.skipLast(1).toString()
      ..selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length));
  }

  void _toggleEmojiKeyboard() {
    setState(() {
      _emojiShowing = !_emojiShowing;
      if (_emojiShowing) {
        _focusNode.unfocus();
      } else {
        _focusNode.requestFocus();
      }
    });
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

        final room = ref.read(selectedRoomProvider.notifier).state;

        if (room != null) {
          FyreChat.instance.sendMessage(message, room.id);
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

      final uploadTask = foundation.kIsWeb
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
        FyreChat.instance.sendMessage(message, room.id);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
    } finally {
      ref.read(imageUploadingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Consumer(
            builder: (context, ref, child) {
              final isAttachmentUploading =
                  ref.watch(attachmentUploadingProvider);
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
                      ? Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 5,
                          ),
                          child: LoadingWidget())
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
                      focusNode: _focusNode,
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
                        suffixIcon: IconButton(
                          icon: Icon(
                            _emojiShowing
                                ? IconlyLight.close_square
                                : Icons.emoji_emotions_outlined,
                            color: _emojiShowing
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).disabledColor,
                          ),
                          onPressed: _toggleEmojiKeyboard,
                        ),
                      ),
                      onChanged: (text) => setState(() {}),
                      onTap: () {
                        if (_emojiShowing) {
                          setState(() => _emojiShowing = false);
                        }
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
                            setState(() => _emojiShowing = false);
                          },
                  ),
                ],
              );
            },
          ),
        ),
        Offstage(
          offstage: !_emojiShowing,
          child: SizedBox(
            height: 250,
            child: EmojiPicker(
              onEmojiSelected: _onEmojiSelected,
              onBackspacePressed: _onBackspacePressed,
              config: Config(
                height: 256,
                checkPlatformCompatibility: true,
                emojiViewConfig: EmojiViewConfig(
                  emojiSizeMax: 28 *
                      (foundation.defaultTargetPlatform == TargetPlatform.iOS
                          ? 1.30
                          : 1.0),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  // bottomActionBarColor: Theme.of(context).colorScheme.surface,
                  buttonMode: ButtonMode.MATERIAL,
                ),
                categoryViewConfig: CategoryViewConfig(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  iconColor: Colors.grey,
                  iconColorSelected: Theme.of(context).colorScheme.primary,
                  backspaceColor: Theme.of(context).colorScheme.primary,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  // showBackspaceButton: true,
                ),
                skinToneConfig: SkinToneConfig(
                  enabled: true,
                ),
                bottomActionBarConfig: BottomActionBarConfig(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  buttonColor: Theme.of(context).colorScheme.primary,
                  buttonIconColor: Theme.of(context).colorScheme.onPrimary,
                ),
                searchViewConfig: SearchViewConfig(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  // buttonColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
