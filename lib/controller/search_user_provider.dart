import 'package:chat_web/fire_chat/service/chat_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chat_web/fire_chat/models/message_models.dart';

final searchUsersProvider = FutureProvider.family<List<User>, String>(
  (ref, query) {
    return FireChat.instance.searchUsersByFullName(query);
  },
);
