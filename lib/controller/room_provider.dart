// Stream provider for room updates
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chat_application/fyrechat/fyrechat.dart' as fc;

// First, create a stream provider for the rooms
final roomsStreamProvider = StreamProvider.autoDispose<List<fc.Room>>((ref) {
  return fc.FyreChat.instance.rooms();
});
