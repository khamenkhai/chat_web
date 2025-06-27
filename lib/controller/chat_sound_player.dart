import 'package:audioplayers/audioplayers.dart';
import 'package:chat_application/fyrechat/fyrechat.dart' as fc;

class ChatSoundPlayer {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;

  static bool shouldPlaySound(
    fc.Message message,
    String currentUserId, {
    Duration threshold = const Duration(seconds: 10),
  }) {
    if (message.author.id == currentUserId) return false;

    final messageTime = DateTime.fromMillisecondsSinceEpoch(message.createdAt!);
    final timeDifference = DateTime.now().difference(messageTime);

    return timeDifference <= threshold;
  }

  Future<void> initialize() async {
    try {
      await _audioPlayer.setSourceUrl('assets/sounds/message_sound.mp3');
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
    }
  }

  Future<void> playNotificationSound() async {
    if (!_isInitialized) return;

    try {
      await _audioPlayer.setVolume(0.5);
      await _audioPlayer.resume();
    } catch (e) {
      // Handle error if needed
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
