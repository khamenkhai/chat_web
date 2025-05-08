import 'dart:async';
import 'package:chat_web/core/utils/chat_util.dart';
import 'package:chat_web/fire_chat/const/fire_chat_const.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:chat_web/fire_chat/models/message_models.dart' as types;

class FireChat {
  FireChat._privateConstructor() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      firebaseUser = user;
    });
  }

  static final FireChat instance = FireChat._privateConstructor();

  /// Current logged-in user. Update is handled internally.
  User? firebaseUser = FirebaseAuth.instance.currentUser;

  /// Getter for FirebaseFirestore singleton
  FirebaseFirestore get getFirebaseFirestore => FirebaseFirestore.instance;

  /// create room
  Future<types.Room> createGroupRoom({
    types.Role creatorRole = types.Role.admin,
    String? imageUrl,
    Map<String, dynamic>? metadata,
    required String name,
    required List<types.User> users,
  }) async {
    if (firebaseUser == null) return Future.error('User does not exist');

    final currentUser = await fetchUser(
      getFirebaseFirestore,
      firebaseUser!.uid,
      FireChatConst.usersCollectionName,
      role: creatorRole.toShortString(),
    );

    final roomUsers = [types.User.fromJson(currentUser)] + users;

    final room = await getFirebaseFirestore
        .collection(FireChatConst.roomsCollectionName)
        .add({
      'createdAt': FieldValue.serverTimestamp(),
      'imageUrl': imageUrl,
      'metadata': metadata,
      'name': name,
      'type': types.RoomType.group.toShortString(),
      'updatedAt': FieldValue.serverTimestamp(),
      'userIds': roomUsers.map((u) => u.id).toList(),
      'userRoles': roomUsers.fold<Map<String, String?>>(
        {},
        (previousValue, user) => {
          ...previousValue,
          user.id: user.role?.toShortString(),
        },
      ),
    });

    return types.Room(
      id: room.id,
      imageUrl: imageUrl,
      metadata: metadata,
      name: name,
      type: types.RoomType.group,
      users: roomUsers,
    );
  }

  /// Creates a direct chat for 2 people. Add [metadata] for any additional
  /// custom data.
  Future<types.Room> createRoom(
    types.User otherUser, {
    Map<String, dynamic>? metadata,
  }) async {
    final fu = firebaseUser;

    if (fu == null) return Future.error('User does not exist');

    // Sort two user ids array to always have the same array for both users,
    // this will make it easy to find the room if exist and make one read only.
    final userIds = [fu.uid, otherUser.id]..sort();

    final roomQuery = await getFirebaseFirestore
        .collection(FireChatConst.roomsCollectionName)
        .where('type', isEqualTo: types.RoomType.direct.toShortString())
        .where('userIds', isEqualTo: userIds)
        .limit(1)
        .get();

    // Check if room already exist.
    if (roomQuery.docs.isNotEmpty) {
      final room = (await processRoomsQuery(
        fu,
        getFirebaseFirestore,
        roomQuery,
        FireChatConst.usersCollectionName,
      ))
          .first;

      return room;
    }

    // To support old chats created without sorted array,
    // try to check the room by reversing user ids array.
    final oldRoomQuery = await getFirebaseFirestore
        .collection(FireChatConst.roomsCollectionName)
        .where('type', isEqualTo: types.RoomType.direct.toShortString())
        .where('userIds', isEqualTo: userIds.reversed.toList())
        .limit(1)
        .get();

    // Check if room already exist.
    if (oldRoomQuery.docs.isNotEmpty) {
      final room = (await processRoomsQuery(
        fu,
        getFirebaseFirestore,
        oldRoomQuery,
        FireChatConst.usersCollectionName,
      ))
          .first;

      return room;
    }

    final currentUser = await fetchUser(
      getFirebaseFirestore,
      fu.uid,
      FireChatConst.usersCollectionName,
    );

    final users = [types.User.fromJson(currentUser), otherUser];

    // Create new room with sorted user ids array.
    final room = await getFirebaseFirestore
        .collection(FireChatConst.roomsCollectionName)
        .add({
      'createdAt': FieldValue.serverTimestamp(),
      'imageUrl': null,
      'metadata': metadata,
      'name': null,
      'type': types.RoomType.direct.toShortString(),
      'updatedAt': FieldValue.serverTimestamp(),
      'userIds': userIds,
      'userRoles': null,
    });

    return types.Room(
      id: room.id,
      metadata: metadata,
      type: types.RoomType.direct,
      users: users,
    );
  }

  /// Creates [types.User] in Firebase to store name and avatar used on
  /// rooms list.
  Future<void> createUserInFirestore(types.User user) async {
    await getFirebaseFirestore
        .collection(FireChatConst.usersCollectionName)
        .doc(user.id)
        .set({
      'createdAt': FieldValue.serverTimestamp(),
      'firstName': user.firstName,
      'imageUrl': user.imageUrl,
      'lastName': user.lastName,
      'lastSeen': FieldValue.serverTimestamp(),
      'metadata': user.metadata,
      'role': user.role?.toShortString(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Removes message document.
  Future<void> deleteMessage(String roomId, String messageId) async {
    await getFirebaseFirestore
        .collection('${FireChatConst.roomsCollectionName}/$roomId/messages')
        .doc(messageId)
        .delete();
  }

  /// Removes room document.
  Future<void> deleteRoom(String roomId) async {
    await getFirebaseFirestore
        .collection(FireChatConst.roomsCollectionName)
        .doc(roomId)
        .delete();
  }

  /// Removes [types.User] from `users` collection in Firebase.
  Future<void> deleteUserFromFirestore(String userId) async {
    await getFirebaseFirestore
        .collection(FireChatConst.usersCollectionName)
        .doc(userId)
        .delete();
  }

  /// Returns a stream of messages from Firebase for a given room.
  ////// Returns a stream of messages from Firebase for a given room.
  /// Now with enhanced reply support.
  Stream<List<types.Message>> messages(
    types.Room room, {
    List<Object?>? endAt,
    List<Object?>? endBefore,
    int? limit,
    List<Object?>? startAfter,
    List<Object?>? startAt,
  }) {
    var query = getFirebaseFirestore
        .collection('${FireChatConst.roomsCollectionName}/${room.id}/messages')
        .orderBy('createdAt', descending: true);

    if (endAt != null) query = query.endAt(endAt);
    if (endBefore != null) query = query.endBefore(endBefore);
    if (limit != null) query = query.limit(limit);
    if (startAfter != null) query = query.startAfter(startAfter);
    if (startAt != null) query = query.startAt(startAt);

    return query.snapshots().asyncMap(
      (snapshot) async {
        final messages = await Future.wait(
          snapshot.docs.map((doc) async {
            final data = doc.data();
            final author = room.users.firstWhere(
              (u) => u.id == data['authorId'],
              orElse: () => types.User(id: data['authorId'] as String),
            );

            data['author'] = author.toJson();
            data['createdAt'] = data['createdAt']?.millisecondsSinceEpoch;
            data['id'] = doc.id;
            data['updatedAt'] = data['updatedAt']?.millisecondsSinceEpoch;

            // Check if the message has been seen by all users
            final seenBy = data['seenBy'] as Map<String, dynamic>? ?? {};
            final allUsersHaveSeen =
                room.users.every((user) => seenBy.containsKey(user.id));

            // Create the message
            final message = types.Message.fromJson(data).copyWith(
              metadata: {
                ...data['metadata'] ?? {},
                'seen': allUsersHaveSeen,
              },
            );

            // Process reply metadata if exists
            return _processReplyMetadata(message, room);
          }),
        );

        return messages;
      },
    );
  }

  /// Returns a stream of changes in a room from Firebase.
  Stream<types.Room> room(String roomId) {
    final fu = firebaseUser;

    if (fu == null) return const Stream.empty();

    return getFirebaseFirestore
        .collection(FireChatConst.roomsCollectionName)
        .doc(roomId)
        .snapshots()
        .asyncMap(
          (doc) => processRoomDocument(
            doc,
            fu,
            getFirebaseFirestore,
            FireChatConst.usersCollectionName,
          ),
        );
  }

  /// get rooms data list
  Stream<List<types.Room>> rooms({bool orderByUpdatedAt = false}) {
    final fu = firebaseUser;

    if (fu == null) return const Stream.empty();

    final collection = orderByUpdatedAt
        ? getFirebaseFirestore
            .collection(FireChatConst.roomsCollectionName)
            .where('userIds', arrayContains: fu.uid)
            .orderBy('updatedAt', descending: true)
        : getFirebaseFirestore
            .collection(FireChatConst.roomsCollectionName)
            .where('userIds', arrayContains: fu.uid);

    return collection.snapshots().asyncMap(
          (query) => processRoomsQuery(
            fu,
            getFirebaseFirestore,
            query,
            FireChatConst.usersCollectionName,
          ),
        );
  }

  Future<List<types.Room>> roomList({bool orderByUpdatedAt = false}) async {
    final fu = firebaseUser;

    if (fu == null) return [];

    final collection = orderByUpdatedAt
        ? getFirebaseFirestore
            .collection(FireChatConst.roomsCollectionName)
            .where('userIds', arrayContains: fu.uid)
            .orderBy('updatedAt', descending: true)
        : getFirebaseFirestore
            .collection(FireChatConst.roomsCollectionName)
            .where('userIds', arrayContains: fu.uid);

    final query = await collection.get();

    return processRoomsQuery(
      fu,
      getFirebaseFirestore,
      query,
      FireChatConst.usersCollectionName,
    );
  }

  void sendMessageReply(types.Message partialMessage, String roomId) async {
    if (firebaseUser == null) return;

    types.Message? message = partialMessage;

    final messageMap = message.toJson();
    messageMap.removeWhere((key, value) => key == 'author' || key == 'id');
    messageMap['authorId'] = firebaseUser!.uid;
    messageMap['createdAt'] = FieldValue.serverTimestamp();
    messageMap['updatedAt'] = FieldValue.serverTimestamp();
    messageMap['seenBy'] = {
      firebaseUser!.uid: FieldValue.serverTimestamp(),

      /// Sender has seen the message
    };

    await getFirebaseFirestore
        .collection('${FireChatConst.roomsCollectionName}/$roomId/messages')
        .add(messageMap);

    // Extract the text content of the message
    String lastMessageText = '';
    if (message is types.TextMessage) {
      lastMessageText = message.text;
    } else if (message is types.ImageMessage) {
      lastMessageText = '📷 Image';
    } else if (message is types.FileMessage) {
      lastMessageText = '📄 File';
    } else if (message is types.CustomMessage) {
      lastMessageText = 'Custom Message';
    }

    await getFirebaseFirestore
        .collection(FireChatConst.roomsCollectionName)
        .doc(roomId)
        .update({
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMsg': lastMessageText
    });
  }

  /// Sends a message to the Firestore. Accepts any partial message and a
  /// room ID. If arbitraty data is provided in the [partialMessage]
  /// does nothing.
  void sendMessage(dynamic partialMessage, String roomId) async {
    if (firebaseUser == null) return;

    types.Message? message;

    if (partialMessage is types.PartialCustom) {
      message = types.CustomMessage.fromPartial(
        author: types.User(id: firebaseUser!.uid),
        id: '',
        partialCustom: partialMessage,
      );
    } else if (partialMessage is types.PartialFile) {
      message = types.FileMessage.fromPartial(
        author: types.User(id: firebaseUser!.uid),
        id: '',
        partialFile: partialMessage,
      );
    } else if (partialMessage is types.PartialImage) {
      message = types.ImageMessage.fromPartial(
        author: types.User(id: firebaseUser!.uid),
        id: '',
        partialImage: partialMessage,
      );
    } else if (partialMessage is types.PartialText) {
      message = types.TextMessage.fromPartial(
        author: types.User(id: firebaseUser!.uid),
        id: '',
        partialText: partialMessage,
      );
    }

    if (message != null) {
      final messageMap = message.toJson();
      messageMap.removeWhere((key, value) => key == 'author' || key == 'id');
      messageMap['authorId'] = firebaseUser!.uid;
      messageMap['createdAt'] = FieldValue.serverTimestamp();
      messageMap['updatedAt'] = FieldValue.serverTimestamp();
      messageMap['seenBy'] = {
        firebaseUser!.uid: FieldValue.serverTimestamp(),

        /// Sender has seen the message
      };

      await getFirebaseFirestore
          .collection('${FireChatConst.roomsCollectionName}/$roomId/messages')
          .add(messageMap);

      // Extract the text content of the message
      String lastMessageText = '';
      if (message is types.TextMessage) {
        lastMessageText = message.text;
      } else if (message is types.ImageMessage) {
        lastMessageText = '📷 Image';
      } else if (message is types.FileMessage) {
        lastMessageText = '📄 File';
      } else if (message is types.CustomMessage) {
        lastMessageText = 'Custom Message';
      }

      await getFirebaseFirestore
          .collection(FireChatConst.roomsCollectionName)
          .doc(roomId)
          .update({
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMsg': lastMessageText
      });
    }
  }

  /// Updates a message in the Firestore. Accepts any message and a
  /// room ID. Message will probably be taken from the [messages] stream.
  void updateMessage(types.Message message, String roomId) async {
    if (firebaseUser == null) return;
    if (message.author.id != firebaseUser!.uid) return;

    final messageMap = message.toJson();
    messageMap.removeWhere(
      (key, value) => key == 'author' || key == 'createdAt' || key == 'id',
    );
    messageMap['authorId'] = message.author.id;
    messageMap['updatedAt'] = FieldValue.serverTimestamp();

    await getFirebaseFirestore
        .collection('${FireChatConst.roomsCollectionName}/$roomId/messages')
        .doc(message.id)
        .update(messageMap);
  }

  void updateRoom(types.Room room) async {
    if (firebaseUser == null) return;

    final roomMap = room.toJson();
    roomMap.removeWhere((key, value) =>
        key == 'createdAt' ||
        key == 'id' ||
        key == 'lastMessages' ||
        key == 'users');

    if (room.type == types.RoomType.direct) {
      roomMap['imageUrl'] = null;
      roomMap['name'] = null;
    }

    roomMap['lastMessages'] = room.lastMessages?.map((m) {
      final messageMap = m.toJson();

      messageMap.removeWhere((key, value) =>
          key == 'author' ||
          key == 'createdAt' ||
          key == 'id' ||
          key == 'updatedAt');

      messageMap['authorId'] = m.author.id;

      return messageMap;
    }).toList();
    roomMap['updatedAt'] = FieldValue.serverTimestamp();
    roomMap['userIds'] = room.users.map((u) => u.id).toList();

    await getFirebaseFirestore
        .collection(FireChatConst.roomsCollectionName)
        .doc(room.id)
        .update(roomMap);
  }

  /// Returns a stream of all users from Firebase.
  Stream<List<types.User>> users() {
    if (firebaseUser == null) return const Stream.empty();
    return getFirebaseFirestore
        .collection(FireChatConst.usersCollectionName)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.fold<List<types.User>>(
            [],
            (previousValue, doc) {
              if (firebaseUser!.uid == doc.id) return previousValue;

              final data = doc.data();

              data['createdAt'] = data['createdAt']?.millisecondsSinceEpoch;
              data['id'] = doc.id;
              data['lastSeen'] = data['lastSeen']?.millisecondsSinceEpoch;
              data['updatedAt'] = data['updatedAt']?.millisecondsSinceEpoch;

              return [...previousValue, types.User.fromJson(data)];
            },
          ),
        );
  }

  /// Marks a message as seen if not already.
  /// Updates Firestore with the user's ID and timestamp.
  Future<void> markMessageAsSeen(String roomId, String messageId) async {
    final fu = firebaseUser;

    if (fu == null) return;

    /// Check if the user has already seen the message
    final hasSeen = await hasUserSeenMessage(roomId, messageId);

    if (!hasSeen) {
      /// Update the `seenBy` field only if the user hasn't seen the message yet
      await getFirebaseFirestore
          .collection('${FireChatConst.roomsCollectionName}/$roomId/messages')
          .doc(messageId)
          .update({
        'seenBy.${fu.uid}': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Checks if the user has seen a message.
  Future<bool> hasUserSeenMessage(String roomId, String messageId) async {
    final fu = firebaseUser;

    if (fu == null) return false;

    /// Fetch the current message document
    final messageDoc = await getFirebaseFirestore
        .collection('${FireChatConst.roomsCollectionName}/$roomId/messages')
        .doc(messageId)
        .get();

    if (!messageDoc.exists) return false;

    /// Get the current `seenBy` map
    final seenBy = messageDoc.data()?['seenBy'] as Map<String, dynamic>? ?? {};

    /// Check if the current user has already seen the message
    return seenBy.containsKey(fu.uid);
  }

  /// Checks if the recipient has seen the message.
  bool isMessageSeen(types.Message message) {
    final isSeen = message.metadata?['seen'] == true;
    return isSeen;
  }

  /// Fetches the custom `lastMsg` field for a specific room by its ID.
  Future<String?> getLastMessage(String roomId) async {
    try {
      final roomDoc = await getFirebaseFirestore
          .collection(FireChatConst.roomsCollectionName)
          .doc(roomId)
          .get();

      if (roomDoc.exists) {
        // Return the `lastMsg` field if it exists
        return roomDoc.data()?['lastMsg'] as String?;
      } else {
        // Room document does not exist
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching last message: $e');
      }
      return null;
    }
  }

  /// Sends a reply to a message in the Firestore.
  /// Accepts the original message being replied to, the partial reply message,
  /// and the room ID.
  Future<void> sendReply({
    required types.Message originalMessage,
    required dynamic partialReply,
    required String roomId,
  }) async {
    if (firebaseUser == null) return;

    // Create the reply message with reference to the original
    types.Message? replyMessage;

    if (partialReply is types.PartialText) {
      replyMessage = types.TextMessage.fromPartial(
        author: types.User(id: firebaseUser!.uid),
        id: '',
        partialText: partialReply,
      ).copyWith(
        repliedMessage: originalMessage,
        metadata: {
          ...partialReply.metadata ?? {},
          // 'replyTo': originalMessage.toJson(),
        },
      );
    } else if (partialReply is types.PartialImage) {
      replyMessage = types.ImageMessage.fromPartial(
        author: types.User(id: firebaseUser!.uid),
        id: '',
        partialImage: partialReply,
      ).copyWith(
        repliedMessage: originalMessage,
        metadata: {
          ...partialReply.metadata ?? {},
        },
      );
    } else if (partialReply is types.PartialFile) {
      replyMessage = types.FileMessage.fromPartial(
        author: types.User(id: firebaseUser!.uid),
        id: '',
        partialFile: partialReply,
      ).copyWith(
        repliedMessage: originalMessage,
        metadata: {
          ...partialReply.metadata ?? {},
        },
      );
    } else if (partialReply is types.PartialCustom) {
      replyMessage = types.CustomMessage.fromPartial(
        author: types.User(id: firebaseUser!.uid),
        id: '',
        partialCustom: partialReply,
      ).copyWith(
        repliedMessage: originalMessage,
        metadata: {
          ...partialReply.metadata ?? {},
        },
      );
    }

    if (replyMessage != null) {
      // debugPrint("=> reply message : $replyMessage");
      sendMessageReply(replyMessage, roomId);
    } else {
      // debugPrint("=> reply message : $replyMessage");
    }
  }

  types.Message _processReplyMetadata(
    types.Message message,
    types.Room room,
  ) {
    // If message has a replied message, ensure its author is properly set from room users
    if (message.repliedMessage != null) {
      final repliedMessage = message.repliedMessage!;
      final originalAuthor = room.users.firstWhere(
        (u) => u.id == repliedMessage.author.id,
        orElse: () =>
            repliedMessage.author, // Fall back to original author if not found
      );
      // Return message with updated repliedMessage author
      return message.copyWith(
        repliedMessage: repliedMessage.copyWith(author: originalAuthor),
      );
    }
    // Return original message if no replied message
    return message;
  }

  /// Edits an existing text message and marks it as edited in metadata
  Future<void> editTextMessage({
    required String roomId,
    required String messageId,
    required String newText,
  }) async {
    if (firebaseUser == null) return;

    // First get the existing message to verify ownership
    final messageDoc = await getFirebaseFirestore
        .collection('${FireChatConst.roomsCollectionName}/$roomId/messages')
        .doc(messageId)
        .get();

    if (!messageDoc.exists) throw Exception('Message not found');
    if (messageDoc.data()?['authorId'] != firebaseUser!.uid) {
      throw Exception('Only message author can edit');
    }

    // Update the message with new text and edited metadata
    await getFirebaseFirestore
        .collection('${FireChatConst.roomsCollectionName}/$roomId/messages')
        .doc(messageId)
        .update({
      'text': newText,
      "isEdited": true,
      'updatedAt': FieldValue.serverTimestamp(),
      'metadata': {
        ...messageDoc.data()?['metadata'] ?? {},
        'edited': true,
        'editedAt': FieldValue.serverTimestamp(),
      },
    });
  }

  /// Edits an existing text message and marks it as edited in metadata
  Future<void> setDeleteMessage({
    required String roomId,
    required String messageId,
  }) async {
    if (firebaseUser == null) return;

    // First get the existing message to verify ownership
    final messageDoc = await getFirebaseFirestore
        .collection('${FireChatConst.roomsCollectionName}/$roomId/messages')
        .doc(messageId)
        .get();

    if (!messageDoc.exists) throw Exception('Message not found');
    if (messageDoc.data()?['authorId'] != firebaseUser!.uid) {
      throw Exception('Only message author can edit');
    }

    // Update the message with new text and edited metadata
    await getFirebaseFirestore
        .collection('${FireChatConst.roomsCollectionName}/$roomId/messages')
        .doc(messageId)
        .update(
      {
        "isDeleted": true,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  /// Returns a stream of the last message in a room, checking if it's deleted
  Stream<types.Message?> lastMessageStream(String roomId) {
    return getFirebaseFirestore
        .collection('${FireChatConst.roomsCollectionName}/$roomId/messages')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final data = doc.data();

      // Skip if message is deleted
      // if (data['isDeleted'] == true) return null;

      // Get room to resolve author info
      final roomDoc = await getFirebaseFirestore
          .collection(FireChatConst.roomsCollectionName)
          .doc(roomId)
          .get();

      if (!roomDoc.exists) return null;

      final room = await processRoomDocument(
        roomDoc,
        firebaseUser!,
        getFirebaseFirestore,
        FireChatConst.usersCollectionName,
      );

      final author = room.users.firstWhere(
        (u) => u.id == data['authorId'],
        orElse: () => types.User(id: data['authorId'] as String),
      );

      data['author'] = author.toJson();
      data['createdAt'] = data['createdAt']?.millisecondsSinceEpoch;
      data['id'] = doc.id;
      data['updatedAt'] = data['updatedAt']?.millisecondsSinceEpoch;
      data['isDeleted'] = data['isDeleted'];

      return types.Message.fromJson(data);
    });
  }
}
