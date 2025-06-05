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

// class ChatContent extends ConsumerStatefulWidget {
//   final types.Room room;
//   const ChatContent({required this.room, super.key});

//   @override
//   ConsumerState<ChatContent> createState() => ChatContentState();
// }

// class ChatContentState extends ConsumerState<ChatContent> {
//   final ChatSoundPlayer _soundPlayer = ChatSoundPlayer();
//   List<types.Message> _previousMessages = [];
//   bool _isMounted = false;
//   final ScrollController _scrollController = ScrollController();
//   bool _isLoadingMore = false;
//   bool _hasMoreMessages = true;
//   int _messageLimit = 50; // Initial limit
//   final int _messageLimitIncrement = 20; // How many to load each time

//   @override
//   void initState() {
//     super.initState();
//     _scrollController.addListener(_scrollListener);
//     WidgetsBinding.instance.addPostFrameCallback((_) => _checkInitialLoad());
//   }

//   void _checkInitialLoad() {
//     if (_scrollController.hasClients &&
//         _scrollController.position.maxScrollExtent == 0) {
//       _loadMoreMessages();
//     }
//   }

//   void _scrollListener() {
//     if (_scrollController.position.pixels >=
//             _scrollController.position.maxScrollExtent -
//                 100 && // Load 100px before bottom
//         !_isLoadingMore &&
//         _hasMoreMessages) {
//       _loadMoreMessages();
//     }
//   }

//   Future<void> _loadMoreMessages() async {
//     if (_isLoadingMore || !mounted) return;

//     setState(() => _isLoadingMore = true);

//     try {
//       // Increase limit by 20 more messages
//       ref.read(messageLimitProvider.notifier).increaseLimit(20);

//       // Check if we've reached the end
//       final total = await FyreChat.instance.getMessageCount(widget.room.id);
//       if (mounted) {
//         setState(
//             () => _hasMoreMessages = ref.read(messageLimitProvider) < total);
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isLoadingMore = false);
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _isMounted = false;
//     _soundPlayer.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   Future<void> _checkMessageCount() async {
//     try {
//       final totalCount =
//           await FyreChat.instance.getMessageCount(widget.room.id);
//       setState(() {
//         _hasMoreMessages = _messageLimit < totalCount;
//       });
//     } catch (e) {
//       if (_isMounted) {
//         setState(() {
//           _hasMoreMessages = false;
//         });
//       }
//     }
//   }

//   @override
//   void didUpdateWidget(covariant ChatContent oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.room.id != widget.room.id) {
//       // Reset when room changes
//       setState(() {
//         _messageLimit = 50;
//         _hasMoreMessages = true;
//         _isLoadingMore = false;
//       });
//       _checkMessageCount();
//     }
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
//             if (messages.isEmpty && !_isLoadingMore && _hasMoreMessages) {
//               // This handles the case where the initial load returns empty
//               // but there might be more messages
//               WidgetsBinding.instance.addPostFrameCallback((_) {
//                 _loadMoreMessages();

//                 _checkForNewMessages(messages);
//               });
//             }

//             return Column(
//               children: [
//                 const Divider(height: 1, thickness: 0.5),
//                 Expanded(
//                   child: NotificationListener<ScrollNotification>(
//                     onNotification: (notification) {
//                       if (notification is ScrollEndNotification &&
//                           _scrollController.position.pixels ==
//                               _scrollController.position.maxScrollExtent &&
//                           !_isLoadingMore &&
//                           _hasMoreMessages) {
//                         _loadMoreMessages();
//                       }
//                       return false;
//                     },
//                     child: _buildMessageList(
//                       context,
//                       messages,
//                       ref,
//                       widget.room,
//                     ),
//                   ),
//                 ),
//                 // Expanded(
//                 //   child: _buildMessageList(
//                 //     context,
//                 //     messages,
//                 //     ref,
//                 //     widget.room,
//                 //   ),
//                 // ),
//                 if (replyTo != null) _buildReplyWidget(replyTo, ref),
//                 if (isAttachmentUploading) const LoadingWidget(),

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
//     bool showTail,
//   ) {
//     return Align(
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: KeyedSubtree(
//         key: ValueKey(message.id),
//         child: MessageBubble(
//           message: message,
//           isMe: isMe,
//           roomId: widget.room.id,
//           room: widget.room,
//           metadata: message.metadata,
//           showTail: showTail,
//           onTap: () {},
//           onLongPress: () => _handleLongPress(context, message, ref, isMe),
//         ),
//       ),
//     );
//   }

//   Widget _buildMessageBubble2(
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

//   Widget _buildMessageList(
//     BuildContext context,
//     List<types.Message> messages,
//     WidgetRef ref,
//     types.Room room,
//   ) {
//     // Add loading indicator at the top
//     final messageWidgets = [
//       if (_isLoadingMore)
//         const Center(
//           child: Padding(
//             padding: EdgeInsets.all(8.0),
//             child: CircularProgressIndicator(),
//           ),
//         ),
//       ...messages.map((message) {
//         final currentIndex = messages.indexOf(message);
//         final showTail = currentIndex == messages.length - 1 ||
//             message.author.id != messages[currentIndex + 1].author.id;

//         return _buildMessageBubble(
//           message.author.id == FirebaseAuth.instance.currentUser?.uid,
//           context,
//           message,
//           ref,
//           showTail,
//         );
//       }),
//     ];

//     return CustomScrollView(
//       controller: _scrollController,
//       reverse: true,
//       physics: const ClampingScrollPhysics(),
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
//             delegate: SliverChildBuilderDelegate(
//               (context, index) => messageWidgets[index],
//               childCount: messageWidgets.length,
//             ),
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
