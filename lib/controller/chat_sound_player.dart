import 'package:audioplayers/audioplayers.dart';

class ChatSoundPlayer {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;

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