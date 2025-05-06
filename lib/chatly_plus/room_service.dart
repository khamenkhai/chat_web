import 'package:chat_web/core/const/chatly_chat_core_config.dart';
import 'package:chat_web/core/utils/chat_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_web/models/flutter_chat_types.dart' as types;

/// Handles all room-related operations
class ChatlyRoomService {
  ChatlyRoomService({
    required this.firebaseUser,
    required this.config,
    required this.firestore,
  });

  final User? firebaseUser;
  final ChatlyChatCoreConfig config;
  final FirebaseFirestore firestore;

  /// Creates a chat group room with [users]. Creator is automatically
  /// added to the group. [name] is required and will be used as
  /// a group name. Add an optional [imageUrl] that will be a group avatar
  /// and [metadata] for any additional custom data.
  Future<types.Room> createGroupRoom({
    types.Role creatorRole = types.Role.admin,
    String? imageUrl,
    Map<String, dynamic>? metadata,
    required String name,
    required List<types.User> users,
  }) async {
    if (firebaseUser == null) return Future.error('User does not exist');

    final currentUser = await fetchUser(
      firestore,
      firebaseUser!.uid,
      config.usersCollectionName,
      role: creatorRole.toShortString(),
    );

    final roomUsers = [types.User.fromJson(currentUser)] + users;

    final room = await firestore.collection(config.roomsCollectionName).add({
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

    // Sort two user ids array to always have the same array for both users
    final userIds = [fu.uid, otherUser.id]..sort();

    final roomQuery = await firestore
        .collection(config.roomsCollectionName)
        .where('type', isEqualTo: types.RoomType.direct.toShortString())
        .where('userIds', isEqualTo: userIds)
        .limit(1)
        .get();

    // Check if room already exist
    if (roomQuery.docs.isNotEmpty) {
      final room = (await processRoomsQuery(
        fu,
        firestore,
        roomQuery,
        config.usersCollectionName,
      ))
          .first;
      return room;
    }

    // To support old chats created without sorted array
    final oldRoomQuery = await firestore
        .collection(config.roomsCollectionName)
        .where('type', isEqualTo: types.RoomType.direct.toShortString())
        .where('userIds', isEqualTo: userIds.reversed.toList())
        .limit(1)
        .get();

    if (oldRoomQuery.docs.isNotEmpty) {
      final room = (await processRoomsQuery(
        fu,
        firestore,
        oldRoomQuery,
        config.usersCollectionName,
      ))
          .first;
      return room;
    }

    final currentUser = await fetchUser(
      firestore,
      fu.uid,
      config.usersCollectionName,
    );

    final users = [types.User.fromJson(currentUser), otherUser];

    // Create new room with sorted user ids array
    final room = await firestore.collection(config.roomsCollectionName).add({
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

  /// Removes room document
  Future<void> deleteRoom(String roomId) async {
    await firestore.collection(config.roomsCollectionName).doc(roomId).delete();
  }

  /// Returns a stream of changes in a room from Firebase
  Stream<types.Room> room(String roomId) {
    final fu = firebaseUser;
    if (fu == null) return const Stream.empty();

    return firestore
        .collection(config.roomsCollectionName)
        .doc(roomId)
        .snapshots()
        .asyncMap(
          (doc) => processRoomDocument(
            doc,
            fu,
            firestore,
            config.usersCollectionName,
          ),
        );
  }

  /// Returns a stream of rooms from Firebase
  Stream<List<types.Room>> rooms({bool orderByUpdatedAt = false}) {
    final fu = firebaseUser;
    if (fu == null) return const Stream.empty();

    final collection = orderByUpdatedAt
        ? firestore
            .collection(config.roomsCollectionName)
            .where('userIds', arrayContains: fu.uid)
            .orderBy('updatedAt', descending: true)
        : firestore
            .collection(config.roomsCollectionName)
            .where('userIds', arrayContains: fu.uid);

    return collection.snapshots().asyncMap(
          (query) => processRoomsQuery(
            fu,
            firestore,
            query,
            config.usersCollectionName,
          ),
        );
  }

  /// Updates a room in the Firestore
  Future<void> updateRoom(types.Room room) async {
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

    await firestore
        .collection(config.roomsCollectionName)
        .doc(room.id)
        .update(roomMap);
  }
}