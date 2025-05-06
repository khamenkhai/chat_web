import 'package:chat_web/core/const/chatly_chat_core_config.dart';
import 'package:chat_web/core/utils/chat_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_web/models/flutter_chat_types.dart' as types;

/// Handles all user-related operations
class ChatlyUserManager {
  ChatlyUserManager({
    required this.firebaseUser,
    required this.config,
    required this.firestore,
  });

  final User? firebaseUser;
  final ChatlyChatCoreConfig config;
  final FirebaseFirestore firestore;

  /// Creates [types.User] in Firebase to store name and avatar used on
  /// rooms list.
  Future<void> createUserInFirestore(types.User user) async {
    await firestore.collection(config.usersCollectionName).doc(user.id).set({
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

  /// Removes [types.User] from `users` collection in Firebase.
  Future<void> deleteUserFromFirestore(String userId) async {
    await firestore.collection(config.usersCollectionName).doc(userId).delete();
  }

  /// Returns a stream of all users from Firebase.
  Stream<List<types.User>> users() {
    if (firebaseUser == null) return const Stream.empty();
    return firestore.collection(config.usersCollectionName).snapshots().map(
      (snapshot) {
      return snapshot.docs.fold<List<types.User>>(
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
      );
    });
  }
}