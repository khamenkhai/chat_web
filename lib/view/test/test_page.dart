// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Message Pagination',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         useMaterial3: true,
//       ),
//       home: const MessageScreen(),
//     );
//   }
// }

// class RemoteApi {
//   Future<List<Message>> generateMessages(int startIndex, int count) async {
//     await Future.delayed(
//         const Duration(milliseconds: 300)); // Simulate network delay

//     final now = DateTime.now();
//     final conversationMessages = [
//       "Hey there!",
//       "How are you doing?",
//       "I'm good, thanks! How about you?",
//       "Pretty good! Working on some Flutter code",
//       "That's awesome! What are you building?",
//       "A chat app with infinite scrolling",
//       "Sounds interesting! Need any help?",
//       "Maybe later, thanks!",
//       "Let me know when you're free to meet",
//       "Sure, how about tomorrow?",
//       "Perfect! See you then",
//       "Bring your laptop if you can",
//       "Will do!",
//       "Great! I'll show you my progress",
//       "Looking forward to it",
//       "Same here!",
//       "By the way, did you see the new Flutter update?",
//       "Not yet, what's new?",
//       "Lots of performance improvements",
//       "Nice! I'll check it out",
//     ];

//     return List.generate(count, (index) {
//       final messageIndex = startIndex + index;
//       final isCurrentUser = messageIndex % 2 == 0; // Alternating messages
//       final sender = isCurrentUser ? _currentUserId : _otherUserId;
//       final messageText =
//           conversationMessages[messageIndex % conversationMessages.length];

//       return Message(
//         id: messageIndex,
//         text: '$messageText (Msg ${messageIndex + 1})',
//         sender: sender,
//         time: now.subtract(Duration(minutes: 200 - messageIndex)),
//         isCurrentUser: isCurrentUser,
//       );
//     });
//   }
// }

// class MessageScreen extends StatefulWidget {
//   const MessageScreen({super.key});

//   @override
//   State<MessageScreen> createState() => _MessageScreenState();
// }

// class _MessageScreenState extends State<MessageScreen> {
//   static const _pageSize = 20;
//   final _currentUserId = 'me';
//   final _otherUserId = 'alice'; // Only one other user for conversation

//   final _pagingController = PagingController<int, Message>(
//     getNextPageKey: (state) {
//       if (state.pages?.isEmpty ?? true) return 0;
//       final lastPage = state.pages!.last;
//       return lastPage.length < _pageSize
//           ? null
//           : state.pages!.length * _pageSize;
//     },
//     fetchPage: (pageKey) => RemoteApi.generateMessages(pageKey, _pageSize)
    
//   );

//   Future<List<Message>> _generateMessages(int startIndex, int count) async {
//     await Future.delayed(
//         const Duration(milliseconds: 300)); // Simulate network delay

//     final now = DateTime.now();
//     final conversationMessages = [
//       "Hey there!",
//       "How are you doing?",
//       "I'm good, thanks! How about you?",
//       "Pretty good! Working on some Flutter code",
//       "That's awesome! What are you building?",
//       "A chat app with infinite scrolling",
//       "Sounds interesting! Need any help?",
//       "Maybe later, thanks!",
//       "Let me know when you're free to meet",
//       "Sure, how about tomorrow?",
//       "Perfect! See you then",
//       "Bring your laptop if you can",
//       "Will do!",
//       "Great! I'll show you my progress",
//       "Looking forward to it",
//       "Same here!",
//       "By the way, did you see the new Flutter update?",
//       "Not yet, what's new?",
//       "Lots of performance improvements",
//       "Nice! I'll check it out",
//     ];

//     return List.generate(count, (index) {
//       final messageIndex = startIndex + index;
//       final isCurrentUser = messageIndex % 2 == 0; // Alternating messages
//       final sender = isCurrentUser ? _currentUserId : _otherUserId;
//       final messageText =
//           conversationMessages[messageIndex % conversationMessages.length];

//       return Message(
//         id: messageIndex,
//         text: '$messageText (Msg ${messageIndex + 1})',
//         sender: sender,
//         time: now.subtract(Duration(minutes: 200 - messageIndex)),
//         isCurrentUser: isCurrentUser,
//       );
//     });
//   }

//   @override
//   void initState() {
//     _pagingController.addListener(() {
//       if (_pagingController.value.error != null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(_pagingController.value.error.toString())),
//         );
//       }
//     });
//     _pagingController.fetchNextPage();
//     super.initState();
//   }

//   @override
//   void dispose() {
//     _pagingController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Chat with $_otherUserId'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _pagingController.refresh,
//           ),
//         ],
//       ),
//       body: ValueListenableBuilder<PagingState<int, Message>>(
//         valueListenable: _pagingController,
//         builder: (context, state, _) {
//           if (state.pages == null && state.isLoading) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (state.error != null && state.pages?.isEmpty == true) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text('Error: ${state.error}'),
//                   ElevatedButton(
//                     onPressed: _pagingController.refresh,
//                     child: const Text('Retry'),
//                   ),
//                 ],
//               ),
//             );
//           }

//           final allItems = state.pages?.expand((page) => page).toList() ?? [];

//           return NotificationListener<ScrollNotification>(
//             onNotification: (notification) {
//               if (notification is ScrollEndNotification &&
//                   notification.metrics.extentAfter < 500 &&
//                   !state.isLoading &&
//                   state.hasNextPage) {
//                 _pagingController.fetchNextPage();
//               }
//               return false;
//             },
//             child: ListView.builder(
//               reverse: true,
//               padding: const EdgeInsets.all(8),
//               itemCount: allItems.length + (state.hasNextPage ? 1 : 0),
//               itemBuilder: (context, index) {
//                 if (index >= allItems.length) {
//                   return const Center(
//                     child: Padding(
//                       padding: EdgeInsets.all(16.0),
//                       child: CircularProgressIndicator(),
//                     ),
//                   );
//                 }

//                 final message = allItems[index];
//                 return MessageBubble(
//                   message: message,
//                   isLast: index == allItems.length - 1,
//                 );
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// class Message {
//   final int id;
//   final String text;
//   final String sender;
//   final DateTime time;
//   final bool isCurrentUser;

//   Message({
//     required this.id,
//     required this.text,
//     required this.sender,
//     required this.time,
//     required this.isCurrentUser,
//   });
// }

// class MessageBubble extends StatelessWidget {
//   final Message message;
//   final bool isLast;

//   const MessageBubble({
//     super.key,
//     required this.message,
//     required this.isLast,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Align(
//       alignment:
//           message.isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         constraints: BoxConstraints(
//           maxWidth: MediaQuery.of(context).size.width * 0.75,
//         ),
//         margin: const EdgeInsets.symmetric(vertical: 4),
//         child: Column(
//           crossAxisAlignment: message.isCurrentUser
//               ? CrossAxisAlignment.end
//               : CrossAxisAlignment.start,
//           children: [
//             Container(
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 16,
//                 vertical: 10,
//               ),
//               decoration: BoxDecoration(
//                 color: message.isCurrentUser
//                     ? Theme.of(context).primaryColor
//                     : Colors.grey[200],
//                 borderRadius: BorderRadius.only(
//                   topLeft: const Radius.circular(16),
//                   topRight: const Radius.circular(16),
//                   bottomLeft: Radius.circular(message.isCurrentUser ? 16 : 0),
//                   bottomRight: Radius.circular(message.isCurrentUser ? 0 : 16),
//                 ),
//               ),
//               child: Text(
//                 message.text,
//                 style: TextStyle(
//                   color: message.isCurrentUser ? Colors.white : Colors.black,
//                 ),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   if (!message.isCurrentUser)
//                     Text(
//                       message.sender,
//                       style: TextStyle(
//                         color: Colors.grey[600],
//                         fontSize: 10,
//                       ),
//                     ),
//                   if (!message.isCurrentUser) const SizedBox(width: 8),
//                   Text(
//                     '${message.time.hour}:${message.time.minute.toString().padLeft(2, '0')}',
//                     style: TextStyle(
//                       color: Colors.grey[500],
//                       fontSize: 10,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             if (!isLast) const SizedBox(height: 8),
//           ],
//         ),
//       ),
//     );
//   }
// }
