import 'package:audioplayers/audioplayers.dart';
import 'package:chat_application/view/chat/chat.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:chat_application/controller/chat_provider.dart';
import 'package:chat_application/core/component/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconly/iconly.dart';
import 'dart:io';
import 'package:chat_application/controller/selected_room_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:chat_application/fyrechat/fyrechat.dart' as fc;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

// State notifier for managing the message input state
class MessageInputStateNotifier extends StateNotifier<MessageInputState> {
  MessageInputStateNotifier() : super(MessageInputState());

  void toggleEmojiKeyboard() {
    state = state.copyWith(emojiShowing: !state.emojiShowing);
  }

  void updateText(String text) {
    state = state.copyWith(text: text);
  }

  void resetText() {
    state = state.copyWith(text: '');
  }

  void hideEmojiKeyboard() {
    state = state.copyWith(emojiShowing: false);
  }
}

// State class
class MessageInputState {
  final bool emojiShowing;
  final String text;

  MessageInputState({
    this.emojiShowing = false,
    this.text = '',
  });

  MessageInputState copyWith({
    bool? emojiShowing,
    String? text,
  }) {
    return MessageInputState(
      emojiShowing: emojiShowing ?? this.emojiShowing,
      text: text ?? this.text,
    );
  }
}

// Provider
final messageInputStateProvider =
    StateNotifierProvider<MessageInputStateNotifier, MessageInputState>(
  (ref) => MessageInputStateNotifier(),
);

class MessageInput extends ConsumerStatefulWidget {
  // final Function(String) onSend;

  const MessageInput({
    super.key,
    // required this.onSend,
  });

  @override
  ConsumerState<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends ConsumerState<MessageInput> {
  final _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus &&
          ref.read(messageInputStateProvider).emojiShowing) {
        ref.read(messageInputStateProvider.notifier).hideEmojiKeyboard();
      }
    });
    _loadSound();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadSound() async {
    try {
      await _audioPlayer.setSourceUrl('assets/sounds/message_send.mp3');
    } catch (e) {
      debugPrint('Error loading sound: $e');
    }
  }

  void _handleSendMessage(String text, WidgetRef ref) {
    final reply = ref.read(replyMessageProvider);

    final room = ref.read(selectedRoomProvider);

    if (reply != null) {
      fc.FyreChat.instance.sendReply(
        originalMessage: reply,
        partialReply: fc.PartialText(text: text),
        roomId: room?.id ?? "",
      );
    } else {
      fc.FyreChat.instance.sendMessage(
        fc.PartialText(text: text),
        room?.id ?? "",
      );
    }

    ref.read(replyMessageProvider.notifier).state = null;
  }

  Future<void> _playSendSound() async {
    try {
      await _audioPlayer.setVolume(0.3); // Lower volume for send sound
      await _audioPlayer.resume();
    } catch (e) {
      debugPrint('Error playing send sound: $e');
    }
  }

  void _onEmojiSelected(category, Emoji emoji) {
    _textController
      ..text += emoji.emoji
      ..selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length));
    ref
        .read(messageInputStateProvider.notifier)
        .updateText(_textController.text);
  }

  void _onBackspacePressed() {
    _textController
      ..text = _textController.text.characters.skipLast(1).toString()
      ..selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length));
    ref
        .read(messageInputStateProvider.notifier)
        .updateText(_textController.text);
  }

  void _toggleEmojiKeyboard() {
    final currentState = ref.read(messageInputStateProvider);
    ref.read(messageInputStateProvider.notifier).toggleEmojiKeyboard();

    if (currentState.emojiShowing) {
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
    }
  }

  Future<void> _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null && result.files.single.bytes != null) {
      ref.read(attachmentUploadingProvider.notifier).state = true;

      final fileBytes = result.files.single.bytes!;
      final name = result.files.single.name;

      try {
        final reference = FirebaseStorage.instance.ref(name);
        await reference.putData(fileBytes);
        final uri = await reference.getDownloadURL();

        final message = fc.PartialFile(
          mimeType: lookupMimeType(name),
          name: name,
          size: result.files.single.size,
          uri: uri,
        );
        final room = ref.read(selectedRoomProvider);

        if (room != null) {
          fc.FyreChat.instance.sendMessage(message, room.id);
        }
      } finally {
        ref.read(attachmentUploadingProvider.notifier).state = false;
      }
    }
  }

  Future<void> _handleImageSelection(BuildContext context) async {
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

      final message = fc.PartialImage(
        height: image.height.toDouble(),
        name: result.name,
        size: bytes.length,
        uri: uri,
        width: image.width.toDouble(),
      );
      final room = ref.read(selectedRoomProvider);

      if (room != null) {
        fc.FyreChat.instance.sendMessage(message, room.id);
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
    final messageInputState = ref.watch(messageInputStateProvider);

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
                // crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  isAttachmentUploading
                      ? const LoadingWidget()
                      : IconButton(
                          icon: Icon(
                            IconlyLight.folder,
                            color: Theme.of(context).disabledColor,
                          ),
                          onPressed: _handleFileSelection,
                        ),
                  isImageUploading
                      ? Center(
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                            ),
                            child: const LoadingWidget()),
                      )
                      : Center(
                        child: IconButton(
                            icon: Icon(
                              IconlyLight.image_2,
                              color: Theme.of(context).disabledColor,
                            ),
                            onPressed: () => _handleImageSelection(context),
                          ),
                      ),
                  Expanded(
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (KeyEvent event) {
                      
                        if (event is KeyDownEvent &&
                            (event.logicalKey == LogicalKeyboardKey.enter ||
                                event.logicalKey ==
                                    LogicalKeyboardKey.numpadEnter)) {
                          final text =
                              ref.read(messageInputStateProvider).text.trim();
                          if (text.isNotEmpty) {
                            _handleSendMessage(text, ref);
                            _playSendSound();
                            _textController.clear();
                            ref.read(messageInputStateProvider.notifier)
                              ..resetText()
                              ..hideEmojiKeyboard();
                          }

                          _focusNode.unfocus();
                        }
                      },
                      child: TextField(
                        maxLines: 5,
                        minLines: 1,
                        controller: _textController,
                        focusNode: _focusNode,
                        onChanged: (value) {
                          ref
                              .read(messageInputStateProvider.notifier)
                              .updateText(value);
                        },
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
                              messageInputState.emojiShowing
                                  ? IconlyLight.close_square
                                  : Icons.emoji_emotions_outlined,
                              color: messageInputState.emojiShowing
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).disabledColor,
                            ),
                            onPressed: _toggleEmojiKeyboard,
                          ),
                        ),
                        onTap: () {
                          if (messageInputState.emojiShowing) {
                            ref
                                .read(messageInputStateProvider.notifier)
                                .hideEmojiKeyboard();
                          }
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      IconlyBold.send,
                      color: messageInputState.text.trim().isEmpty
                          ? Theme.of(context).disabledColor
                          : Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: messageInputState.text.trim().isEmpty
                        ? null
                        : () async {
                            _handleSendMessage(messageInputState.text, ref);
                            await _playSendSound();
                            _textController.clear();
                            ref.read(messageInputStateProvider.notifier)
                              ..resetText()
                              ..hideEmojiKeyboard();

                            // Play the send sound
                          },
                  ),
                ],
              );
            },
          ),
        ),
        Offstage(
          offstage: !messageInputState.emojiShowing,
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
                  buttonMode: ButtonMode.MATERIAL,
                ),
                categoryViewConfig: CategoryViewConfig(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  iconColor: Colors.grey,
                  iconColorSelected: Theme.of(context).colorScheme.primary,
                  backspaceColor: Theme.of(context).colorScheme.primary,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                ),
                skinToneConfig: const SkinToneConfig(
                  enabled: true,
                ),
                bottomActionBarConfig: BottomActionBarConfig(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  buttonColor: Theme.of(context).colorScheme.primary,
                  buttonIconColor: Theme.of(context).colorScheme.onPrimary,
                ),
                searchViewConfig: SearchViewConfig(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
