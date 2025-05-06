import 'package:chat_web/core/const/chatly_chat_core_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_web/models/flutter_chat_types.dart' as types;

/// Handles all message-related operations
class ChatlyMessageManager {
  ChatlyMessageManager({
    required this.firebaseUser,
    required this.config,
    required this.firestore,
  });

  final User? firebaseUser;
  final ChatlyChatCoreConfig config;
  final FirebaseFirestore firestore;

  /// Removes message document
  Future<void> deleteMessage(String roomId, String messageId) async {
    await firestore
        .collection('${config.roomsCollectionName}/$roomId/messages')
        .doc(messageId)
        .delete();
  }

  /// Returns a stream of messages from Firebase for a given room
  Stream<List<types.Message>> messages(
    types.Room room, {
    List<Object?>? endAt,
    List<Object?>? endBefore,
    int? limit,
    List<Object?>? startAfter,
    List<Object?>? startAt,
  }) {
    var query = firestore
        .collection('${config.roomsCollectionName}/${room.id}/messages')
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

            final seenBy = data['seenBy'] as Map<String, dynamic>? ?? {};
            final allUsersHaveSeen =
                room.users.every((user) => seenBy.containsKey(user.id));

            final message = types.Message.fromJson(data).copyWith(
              metadata: {
                ...data['metadata'] ?? {},
                'seen': allUsersHaveSeen,
              },
            );

            return _processReplyMetadata(message, room);
          }),
        );

        return messages;
      },
    );
  }

  /// Sends a message to the Firestore
  Future<void> sendMessage(dynamic partialMessage, String roomId) async {
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
      };

      await firestore
          .collection('${config.roomsCollectionName}/$roomId/messages')
          .add(messageMap);

      // Update room's last message
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

      await firestore
          .collection(config.roomsCollectionName)
          .doc(roomId)
          .update({
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMsg': lastMessageText,
      });
    }
  }

  /// Sends a reply message to the Firestore
  Future<void> sendMessageReply(
      types.Message partialMessage, String roomId) async {
    if (firebaseUser == null) return;

    types.Message? message = partialMessage;

    final messageMap = message.toJson();
    messageMap.removeWhere((key, value) => key == 'author' || key == 'id');
    messageMap['authorId'] = firebaseUser!.uid;
    messageMap['createdAt'] = FieldValue.serverTimestamp();
    messageMap['updatedAt'] = FieldValue.serverTimestamp();
    messageMap['seenBy'] = {
      firebaseUser!.uid: FieldValue.serverTimestamp(),
    };

    await firestore
        .collection('${config.roomsCollectionName}/$roomId/messages')
        .add(messageMap);

    // Update room's last message
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

    await firestore
        .collection(config.roomsCollectionName)
        .doc(roomId)
        .update({
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMsg': lastMessageText,
    });
  }

  /// Updates a message in the Firestore
  Future<void> updateMessage(types.Message message, String roomId) async {
    if (firebaseUser == null) return;
    if (message.author.id != firebaseUser!.uid) return;

    final messageMap = message.toJson();
    messageMap.removeWhere(
      (key, value) => key == 'author' || key == 'createdAt' || key == 'id',
    );
    messageMap['authorId'] = message.author.id;
    messageMap['updatedAt'] = FieldValue.serverTimestamp();

    await firestore
        .collection('${config.roomsCollectionName}/$roomId/messages')
        .doc(message.id)
        .update(messageMap);
  }

  /// Processes reply metadata for a message
  types.Message _processReplyMetadata(types.Message message, types.Room room) {
    if (message.metadata?['replyToMessageId'] != null) {
      // Add logic to process reply metadata if needed
      // For example, you might want to fetch the replied message details
      // and attach them to the metadata
    }
    return message;
  }
}