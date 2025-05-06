import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chat_web/models/flutter_chat_types.dart' as types;

// Define a StateProvider for the selected room
final selectedRoomProvider = StateProvider<types.Room?>((ref) => null);
