import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chat_web/chat_service/models/message_models.dart' as types;
import 'package:chat_web/chat_service/service/chat_service.dart';

final searchUsersProvider = FutureProvider.family<List<types.User>, String>(
  (ref, query) {
    return FyreChat.instance.searchUsersByFullName(query);
  },
);
