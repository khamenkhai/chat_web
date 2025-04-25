// import 'dart:io';
// import 'package:chat_web/chatly_plus/src/chatly_chat_core.dart';
// import 'package:chat_web/view/theme/theme_switch.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/foundation.dart';
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

// // Stream provider for messages
// final messagesStreamProvider = StreamProvider.autoDispose
//     .family<List<types.Message>, types.Room>((ref, room) {
//   return ChatlyChatCore.instance.messages(room);
// });

// // Stream provider for room updates
// final roomStreamProvider =
//     StreamProvider.autoDispose.family<types.Room, String>((ref, roomId) {
//   return ChatlyChatCore.instance.room(roomId);
// });

// // Provider for attachment uploading state
// final attachmentUploadingProvider =
//     StateProvider.autoDispose<bool>((ref) => false);

// class ChatPage extends StatelessWidget {
//   const ChatPage({
//     super.key,
//     required this.room,
//   });

//   final types.Room room;

//   @override
//   Widget build(BuildContext context) {
//     final Logger logger = Logger();

//     logger.f("Chat Page Rebuid!!", stackTrace: StackTrace.fromString(""));
//     return Scaffold(
//       appBar: AppBar(
//         systemOverlayStyle: SystemUiOverlayStyle.light,
//         title: Text(room.name ?? ""),
//         actions: const [ThemeSwitch()],
//       ),
//       body: _ChatContent(room: room),
//     );
//   }
// }

// class _ChatContent extends ConsumerWidget {
//   const _ChatContent({required this.room});

//   final types.Room room;

//   static const String _photoText = 'Photo';
//   static const String _fileText = 'File';
//   static const String _cancelText = 'Cancel';
//   static const String _editMessageTitle = 'Edit Message';
//   static const String _editMessageHint = 'Edit your message';
//   static const String _saveText = 'Save';

//   Future<void> _handleFileSelection(WidgetRef ref) async {
//     final result = await FilePicker.platform.pickFiles(type: FileType.any);

//     if (result != null && result.files.single.path != null) {
//       ref.read(attachmentUploadingProvider.notifier).state = true;

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

//         ChatlyChatCore.instance.sendMessage(message, room.id);
//       } finally {
//         ref.read(attachmentUploadingProvider.notifier).state = false;
//       }
//     }
//   }

//   Future<void> _handleImageSelection(WidgetRef ref,BuildContext context) async {
//   final logger = Logger();
//   final ImagePicker picker = ImagePicker();

//   try {
//     // For web, we use XFile instead of File
//     final result = await picker.pickImage(
//       imageQuality: 70,
//       maxWidth: 1440,
//       source: ImageSource.gallery,
//     );

//     if (result == null) return;

//     ref.read(attachmentUploadingProvider.notifier).state = true;

//     // For web, we need to handle the file differently
//     if (kIsWeb) {
//       // Handle web-specific file upload
//       final bytes = await result.readAsBytes();
//       final image = await decodeImageFromList(bytes);
      
//       // Generate a unique filename
//       final fileName = '${DateTime.now().millisecondsSinceEpoch}_${result.name}';
//       final reference = FirebaseStorage.instance.ref().child(fileName);
      
//       // Upload the bytes directly for web
//       final uploadTask = reference.putData(
//         bytes,
//         SettableMetadata(contentType: 'image/jpeg'),
//       );
      
//       final snapshot = await uploadTask;
//       final uri = await snapshot.ref.getDownloadURL();

//       // Create and send the message
//       final message = types.PartialImage(
//         height: image.height.toDouble(),
//         name: result.name,
//         size: bytes.length,
//         uri: uri,
//         width: image.width.toDouble(),
//       );

//       ChatlyChatCore.instance.sendMessage(message, room.id);
//     } else {
//       // Mobile/desktop handling (your existing code)
//       final file = File(result.path);
//       final bytes = await result.readAsBytes();
//       final image = await decodeImageFromList(bytes);

//       final reference = FirebaseStorage.instance.ref(result.name);
//       await reference.putFile(file);
//       final uri = await reference.getDownloadURL();

//       final message = types.PartialImage(
//         height: image.height.toDouble(),
//         name: result.name,
//         size: file.lengthSync(),
//         uri: uri,
//         width: image.width.toDouble(),
//       );

//       ChatlyChatCore.instance.sendMessage(message, room.id);
//     }
//   } catch (e) {
//     logger.e("Error uploading image", error: e);
//     // Optionally show an error message to the user
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Failed to upload image: ${e.toString()}')),
//     );
//   } finally {
//     ref.read(attachmentUploadingProvider.notifier).state = false;
//   }
// }

//   // Handles image selection and uploads the image to Firebase Storage
//   void _handleImageSelection2(WidgetRef ref) async {
//     Logger logger = Logger();

//     final result = await ImagePicker().pickImage(
//       imageQuality: 70,
//       maxWidth: 1440,
//       source: ImageSource.gallery,
//     );

//     if (result != null) {
//       ref.read(attachmentUploadingProvider.notifier).state = true;
//       final file = File(result.path);
//       final bytes = await result.readAsBytes();
//       final image = await decodeImageFromList(bytes);

//       try {
//         // Upload image to Firebase Storage
//         final reference = FirebaseStorage.instance.ref(result.name);
//         await reference.putFile(file);
//         final uri = await reference.getDownloadURL();

//         // Create an image message and send it
//         final message = types.PartialImage(
//           height: image.height.toDouble(),
//           name: result.name,
//           size: file.lengthSync(),
//           uri: uri,
//           width: image.width.toDouble(),
//         );

//         ChatlyChatCore.instance.sendMessage(message, room.id);
//       } catch (e) {
//         logger.f("Error => ${e}");
//       } finally {
//         ref.read(attachmentUploadingProvider.notifier).state = false;
//       }
//     }
//   }

//   void _handleAttachmentPressed(BuildContext context, WidgetRef ref) {
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
//                   _handleImageSelection(ref,context);
//                 },
//                 child: const Align(
//                   alignment: Alignment.centerLeft,
//                   child: Text(_photoText),
//                 ),
//               ),
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   _handleFileSelection(ref);
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

//   Future<void> _handleMessageTap(
//       BuildContext context, types.Message message) async {
//     if (message is types.FileMessage) {
//       var localPath = message.uri;

//       if (message.uri.startsWith('http')) {
//         try {
//           final updatedMessage = message.copyWith(isLoading: true);
//           ChatlyChatCore.instance.updateMessage(updatedMessage, room.id);

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
//           ChatlyChatCore.instance.updateMessage(updatedMessage, room.id);
//         }
//       }
//     }
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

//       ChatlyChatCore.instance.updateMessage(updatedMessage, room.id);
//     }
//   }

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final Logger logger = Logger();

//     logger.f("Chat widget Rebuid!!", stackTrace: StackTrace.fromString(""));

//     final messagesAsync = ref.watch(messagesStreamProvider(room));
//     final isAttachmentUploading = ref.watch(attachmentUploadingProvider);

//     return messagesAsync.when(
//       loading: () => const Center(child: CircularProgressIndicator()),
//       error: (error, stack) => Center(child: Text('Error: $error')),
//       data: (messages) {
//         return Chat(
//           usePreviewData: true,
//           isAttachmentUploading: isAttachmentUploading,
//           messages: messages,
//           onAttachmentPressed: () => _handleAttachmentPressed(context, ref),
//           onMessageTap: (context, message) =>
//               _handleMessageTap(context, message),
//           onPreviewDataFetched: (message, previewData) {
//             final updatedMessage = message.copyWith(previewData: previewData);
//             ChatlyChatCore.instance.updateMessage(updatedMessage, room.id);
//           },
//           onSendPressed: (message) {
//             ChatlyChatCore.instance.sendMessage(message, room.id);
//           },
//           onMessageLongPress: (context, message) {
//             if (message.author.id == FirebaseAuth.instance.currentUser?.uid) {
//               _showEditMessageDialog(context, message);
//             }
//           },
//           user: types.User(
//             id: FirebaseAuth.instance.currentUser?.uid ?? "",
//           ),
//           showUserNames: true,
//           showUserAvatars: true,
//           useTopSafeAreaInset: true,
//           hideBackgroundOnEmojiMessages: false,
//           isLeftStatus: false,
//           customStatusBuilder: (message, {required context}) {
//             final isSeen = message.metadata?['seen'] == true;
//             return Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(
//                   isSeen ? Icons.done_all : Icons.done,
//                   size: 16,
//                   color: isSeen ? Colors.indigo : Colors.grey,
//                 ),
//                 const SizedBox(width: 4),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
// }
