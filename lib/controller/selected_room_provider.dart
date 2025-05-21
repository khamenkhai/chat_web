import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chat_web/chat_service/models/message_models.dart' as types;

// Define a StateProvider for the selected room
final selectedRoomProvider = StateProvider<types.Room?>((ref) => null);
