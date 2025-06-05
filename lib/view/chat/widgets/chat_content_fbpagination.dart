// import 'package:chat_web/view/chat/chat.dart';
// import 'package:flutter/material.dart';
// import 'package:chat_web/controller/chat_provider.dart';
// import 'package:chat_web/controller/chat_sound_player.dart';
// import 'package:chat_web/core/component/loading_widget.dart';
// import 'package:chat_web/core/const/theme_const.dart';
// import 'package:chat_web/chat_service/models/message_models.dart' as types;
// import 'package:chat_web/chat_service/service/chat_service.dart';
// import 'package:chat_web/view/chat/widgets/edit_message_dialog.dart';
// import 'package:chat_web/view/chat/widgets/message_bubble.dart';
// import 'package:chat_web/view/chat/widgets/message_input.dart';
// import 'package:chat_web/view/chat/widgets/message_options_dialog.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// class ChatContent extends StatefulWidget {
//   final types.Room room;
//   const ChatContent({required this.room, super.key});

//   @override
//   State<ChatContent> createState() => ChatContentState();
// }

// class ChatContentState extends State<ChatContent> {
//   final ChatSoundPlayer _soundPlayer = ChatSoundPlayer();
//   List<types.Message> _previousMessages = [];
//   bool _isMounted = false;

//   @override
//   void initState() {
//     super.initState();
//     _isMounted = true;
//     _initializeSoundPlayer();
//   }

//   @override
//   void dispose() {
//     _isMounted = false;
//     _soundPlayer.dispose();
//     super.dispose();
//   }

//   Future<void> _initializeSoundPlayer() async {
//     await _soundPlayer.initialize();
//   }

//   void _checkForNewMessages(List<types.Message> currentMessages) {
//     if (_previousMessages.isEmpty) {
//       _previousMessages = currentMessages;
//       return;
//     }

//     final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
//     final newMessages = currentMessages.where((message) {
//       return !_previousMessages.any((m) => m.id == message.id) &&
//           ChatSoundPlayer.shouldPlaySound(message, currentUserId);
//     }).toList();

//     if (newMessages.isNotEmpty && _isMounted) {
//       _soundPlayer.playNotificationSound();
//     }

//     _previousMessages = currentMessages;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer(
//       builder: (context, ref, child) {
//         /// message async
//         final messagesAsync = ref.watch(messagesStreamProvider(widget.room));

//         /// to check if a file is uploading
//         final isAttachmentUploading = ref.watch(attachmentUploadingProvider);

//         /// a cached data to save a reply to
//         final replyTo = ref.watch(replyMessageProvider);

//         return messagesAsync.when(
//           loading: () => const Center(child: LoadingWidget()),
//           error: (error, stack) => Center(child: Text('Error: $error')),
//           data: (messages) {
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               _checkForNewMessages(messages);
//             });

//             return Column(
//               children: [
//                 const Divider(height: 1, thickness: 0.5),
//                 Expanded(
//                   child: _buildMessageList(
//                     context,
//                     messages,
//                     ref,
//                     widget.room,
//                   ),
//                 ),
//                 if (replyTo != null) _buildReplyWidget(replyTo, ref),
//                 if (isAttachmentUploading)
//                   const LoadingWidget(),

//                 /// message input box
//                 MessageInput(),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }

//   Widget _buildMessageBubble(
//     bool isMe,
//     BuildContext context,
//     types.Message message,
//     WidgetRef ref,
//     bool showTail, // Add this parameter
//   ) {
//     return Align(
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: MessageBubble(
//         message: message,
//         isMe: isMe,
//         roomId: widget.room.id,
//         room: widget.room,
//         metadata: message.metadata,
//         showTail: showTail, // Pass the parameter
//         onTap: () {},
//         onLongPress: () => _handleLongPress(context, message, ref, isMe),
//       ),
//     );
//   }

// // Update your message list building logic
//   Widget _buildMessageList(
//     BuildContext context,
//     List<types.Message> messages,
//     WidgetRef ref,
//     types.Room room,
//   ) {
//     // Group messages by user and determine which should show tails
//     List<Widget> messageWidgets = [];

//     for (int i = 0; i < messages.length; i++) {

//       final message = messages[i];
//       final currentAuthorId = message.author.id;
//       final showTail = i == messages.length - 1 ||
//           currentAuthorId != messages[i + 1].author.id;

//       if (message.author.id != FirebaseAuth.instance.currentUser?.uid) {
//         FyreChat.instance.markMessageAsSeen(room.id, message.id);
//       }

//       messageWidgets.add(
//         _buildMessageBubble(
//           message.author.id == FirebaseAuth.instance.currentUser?.uid,
//           context,
//           message,
//           ref,
//           showTail,
//         ),
//       );
//     }

//     return CustomScrollView(
//       reverse: true,
//       slivers: [
//         SliverPadding(
//           padding: EdgeInsets.symmetric(
//             vertical: 8,
//             horizontal: MediaQuery.of(context).size.width > 1200
//                 ? 100
//                 : MediaQuery.of(context).size.width > 800
//                     ? 8
//                     : 0,
//           ),
//           sliver: SliverList(
//             delegate: SliverChildListDelegate(messageWidgets),
//           ),
//         ),
//       ],
//     );
//   }

//   void _handleLongPress(
//     BuildContext context,
//     types.Message message,
//     WidgetRef ref,
//     bool isMe,
//   ) {
//     if (isMe) {
//       showMessageOptionsDialog(
//         context: context,
//         onEdit: () => _handleEditMessage(context, message),
//         onDelete: () => _handleDeleteMessage(message),
//         onReply: () => _handleReplyMessage(ref, message),
//         isTextMessage: message is types.TextMessage,
//       );
//     } else {
//       ref.read(replyMessageProvider.notifier).state = message;
//     }
//   }

//   void _handleEditMessage(BuildContext context, types.Message message) {
//     if (message is types.TextMessage) {
//       showEditMessageDialog(
//         context: context,
//         initialMessage: message.text,
//         onSave: (newText) {
//           FyreChat.instance.editTextMessage(
//             roomId: widget.room.id,
//             messageId: message.id,
//             newText: newText,
//           );
//         },
//       );
//     }
//   }

//   void _handleDeleteMessage(types.Message message) {
//     FyreChat.instance.setDeleteMessage(
//       roomId: widget.room.id,
//       messageId: message.id,
//     );
//   }

//   void _handleReplyMessage(WidgetRef ref, types.Message message) {
//     ref.read(replyMessageProvider.notifier).state = message;
//   }

//   Widget _buildReplyWidget(types.Message replyTo, WidgetRef ref) {
//     final messageColors = Theme.of(context).extension<MessageColors>()!;
//     return Container(
//       color: messageColors.otherReplyColor,
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       child: Row(
//         children: [
//           Expanded(
//             child: Text(
//               replyTo is types.TextMessage ? replyTo.text : 'Replying...',
//               style: const TextStyle(fontStyle: FontStyle.italic),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//           IconButton(
//             icon: const Icon(Icons.close),
//             onPressed: () =>
//                 ref.read(replyMessageProvider.notifier).state = null,
//           )
//         ],
//       ),
//     );
//   }
// }
