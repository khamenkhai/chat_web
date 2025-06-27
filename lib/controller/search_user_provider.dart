import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chat_application/fyrechat/fyrechat.dart' as fc;

final searchUsersProvider = FutureProvider.family<List<fc.User>, String>(
  (ref, query) {
    return fc.FyreChat.instance.searchUsersByFullName(query);
  },
);
