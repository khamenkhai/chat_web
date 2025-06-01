import 'package:chat_web/chat_service/models/message_models.dart' as types;

class MessageHandler {
  static bool shouldPlaySound(
    types.Message message,
    String currentUserId, {
    Duration threshold = const Duration(seconds: 10),
  }) {
    if (message.author.id == currentUserId) return false;
    
    final messageTime = DateTime.fromMillisecondsSinceEpoch(message.createdAt!);
    final timeDifference = DateTime.now().difference(messageTime);
    
    return timeDifference <= threshold;
  }
}