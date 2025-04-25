// import 'dart:io';
// import 'package:chat_web/chatly_plus/src/chatly_chat_core.dart';
// import 'package:chat_web/controller/chat_controller.dart';
// import 'package:chat_web/view/theme/theme_switch.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
// import 'package:flutter_chat_ui/flutter_chat_ui.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
// import 'package:logger/logger.dart';
// import 'package:mime/mime.dart';
// import 'package:path_provider/path_provider.dart';

// class ChatPage extends ConsumerStatefulWidget {
//   const ChatPage({
//     super.key,
//     required this.room,
//   });

//   final types.Room room;

//   @override
//   ConsumerState<ChatPage> createState() => _ChatPageState();
// }

// class _ChatPageState extends ConsumerState<ChatPage> {
//   static const String _photoText = 'Photo';
//   static const String _fileText = 'File';
//   static const String _cancelText = 'Cancel';
//   static const String _editMessageTitle = 'Edit Message';
//   static const String _editMessageHint = 'Edit your message';
//   static const String _saveText = 'Save';
//   static const String _noDataText = "No data";

//   final _textController = TextEditingController();
//   final Logger logger = Logger();

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       ref.read(chatControllerProvider.notifier).initialize(widget.room);
//     });
//   }

//   @override
//   void didUpdateWidget(ChatPage oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.room.id != widget.room.id) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         ref.read(chatControllerProvider.notifier).initialize(widget.room);
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _textController.dispose();
//     super.dispose();
//   }

//   void _handleAttachmentPressed() {
//     showModalBottomSheet<void>(
//       context: context,
//       builder: (BuildContext context) => SafeArea(
//         child: SizedBox(
//           height: 144,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: <Widget>[
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   _handleImageSelection();
//                 },
//                 child: const Align(
//                   alignment: Alignment.centerLeft,
//                   child: Text(_photoText),
//                 ),
//               ),
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   _handleFileSelection();
//                 },
//                 child: const Align(
//                   alignment: Alignment.centerLeft,
//                   child: Text(_fileText),
//                 ),
//               ),
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Align(
//                   alignment: Alignment.centerLeft,
//                   child: Text(_cancelText),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _handleFileSelection() async {
//     final result = await FilePicker.platform.pickFiles(type: FileType.any);

//     if (result != null && result.files.single.path != null) {
//       final controller = ref.read(chatControllerProvider.notifier);
//       controller.setAttachmentUploading(true);

//       final file = File(result.files.single.path!);
//       final name = result.files.single.name;

//       try {
//         final reference = FirebaseStorage.instance.ref(name);
//         await reference.putFile(file);
//         final uri = await reference.getDownloadURL();

//         final message = types.PartialFile(
//           mimeType: lookupMimeType(file.path),
//           name: name,
//           size: result.files.single.size,
//           uri: uri,
//         );

//         ChatlyChatCore.instance.sendMessage(message, widget.room.id);
//       } finally {
//         controller.setAttachmentUploading(false);
//       }
//     }
//   }

//   Future<void> _handleImageSelection() async {
//     final result = await ImagePicker().pickImage(
//       imageQuality: 70,
//       maxWidth: 1440,
//       source: ImageSource.gallery,
//     );

//     if (result != null) {
//       final controller = ref.read(chatControllerProvider.notifier);
//       controller.setAttachmentUploading(true);

//       final file = File(result.path);
//       final bytes = await result.readAsBytes();
//       final image = await decodeImageFromList(bytes);

//       try {
//         final reference = FirebaseStorage.instance.ref(result.name);
//         await reference.putFile(file);
//         final uri = await reference.getDownloadURL();

//         final message = types.PartialImage(
//           height: image.height.toDouble(),
//           name: result.name,
//           size: file.lengthSync(),
//           uri: uri,
//           width: image.width.toDouble(),
//         );

//         ChatlyChatCore.instance.sendMessage(message, widget.room.id);
//       } finally {
//         controller.setAttachmentUploading(false);
//       }
//     }
//   }

//   void _handleMessageTap(BuildContext _, types.Message message) async {
//     if (message is types.FileMessage) {
//       var localPath = message.uri;

//       if (message.uri.startsWith('http')) {
//         try {
//           final updatedMessage = message.copyWith(isLoading: true);
//           ChatlyChatCore.instance.updateMessage(updatedMessage, widget.room.id);

//           final client = http.Client();
//           final request = await client.get(Uri.parse(message.uri));
//           final bytes = request.bodyBytes;
//           final documentsDir = (await getApplicationDocumentsDirectory()).path;
//           localPath = '$documentsDir/${message.name}';

//           if (!File(localPath).existsSync()) {
//             await File(localPath).writeAsBytes(bytes);
//           }
//         } finally {
//           final updatedMessage = message.copyWith(isLoading: false);
//           ChatlyChatCore.instance.updateMessage(updatedMessage, widget.room.id);
//         }
//       }
//     }
//   }

//   void _handlePreviewDataFetched(
//     types.TextMessage message,
//     types.PreviewData previewData,
//   ) {
//     final updatedMessage = message.copyWith(previewData: previewData);
//     ChatlyChatCore.instance.updateMessage(updatedMessage, widget.room.id);
//   }

//   void _handleSendPressed(types.PartialText message) {
//     ChatlyChatCore.instance.sendMessage(message, widget.room.id);
//   }

//   void _showEditMessageDialog(BuildContext context, types.Message message) {
//     final TextEditingController controller = TextEditingController();

//     if (message is types.TextMessage) {
//       controller.text = message.text;
//     }

//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text(_editMessageTitle),
//           content: TextField(
//             controller: controller,
//             decoration: const InputDecoration(hintText: _editMessageHint),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text(_cancelText),
//             ),
//             TextButton(
//               onPressed: () {
//                 if (controller.text.trim().isNotEmpty) {
//                   _updateMessage(message, controller.text.trim());
//                   Navigator.pop(context);
//                 }
//               },
//               child: const Text(_saveText),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _updateMessage(types.Message message, String newText) {
//     if (message is types.TextMessage) {
//       final updatedMessage = message.copyWith(
//         text: newText,
//         updatedAt: DateTime.now().millisecondsSinceEpoch,
//         metadata: {
//           ...message.metadata ?? {},
//           'isEdited': true,
//         },
//       );

//       ChatlyChatCore.instance.updateMessage(updatedMessage, widget.room.id);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final room = ref.watch(
//       chatControllerProvider.select((state) => state.room),
//     );
//     final isAttachmentUploading = ref.watch(
//       chatControllerProvider.select((state) => state.isAttachmentUploading),
//     );
//     final messages = ref.watch(
//       chatControllerProvider.select((state) => state.messages),
//     );

//     logger.f("chat page rebuild",stackTrace: StackTrace.fromString(""));

//     return Scaffold(
//       appBar: AppBar(
//         systemOverlayStyle: SystemUiOverlayStyle.light,
//         title: Text(widget.room.name ?? ""),
//         actions: const [ThemeSwitch()],
//       ),
//       body: room == null
//           ? const Center(child: Text(_noDataText))
//           : Chat(
//               usePreviewData: true,
//               isAttachmentUploading: isAttachmentUploading,
//               messages: messages,
//               onAttachmentPressed: _handleAttachmentPressed,
//               onMessageTap: _handleMessageTap,
//               onPreviewDataFetched: _handlePreviewDataFetched,
//               onSendPressed: _handleSendPressed,
//               onMessageLongPress: (context, message) {
//                 if (message.author.id ==
//                     FirebaseAuth.instance.currentUser?.uid) {
//                   _showEditMessageDialog(context, message);
//                 }
//               },
//               user: types.User(
//                 id: FirebaseAuth.instance.currentUser?.uid ?? "",
//               ),
//               showUserNames: true,
//               showUserAvatars: true,
//               useTopSafeAreaInset: true,
//               hideBackgroundOnEmojiMessages: false,
//               isLeftStatus: false,
//               customStatusBuilder: (message, {required context}) {
//                 final isSeen = message.metadata?['seen'] == true;
//                 return Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(
//                       isSeen ? Icons.done_all : Icons.done,
//                       size: 16,
//                       color: isSeen ? Colors.indigo : Colors.grey,
//                     ),
//                     const SizedBox(width: 4),
//                   ],
//                 );
//               },
//             ),
//     );
//   }
// }