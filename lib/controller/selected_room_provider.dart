import 'dart:convert';
import 'package:chat_web/core/local_data/shared_prefs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chat_web/chat_service/models/message_models.dart' as types;

final selectedRoomProvider =
    StateNotifierProvider<PersistentSelectedRoomNotifier, types.Room?>((ref) {
  return PersistentSelectedRoomNotifier(ref);
});

class PersistentSelectedRoomNotifier extends StateNotifier<types.Room?> {
  final Ref ref;
  final SharedPref _sharedPref = SharedPref();

  PersistentSelectedRoomNotifier(this.ref) : super(null) {
    _loadPersistedData();
  }

  Future<void> _loadPersistedData() async {
    print("=>=> loading data!");
    try {
      final jsonString = await _sharedPref.getString(key: 'selectedRoom');
      if (jsonString.isNotEmpty) {
        final room = types.Room.fromJson(jsonDecode(jsonString));
        state = room;
          print("=>=> data ${room}!");
      }
      if (kDebugMode) {
        print("selected room : $state");
      }
    } catch (e) {
      debugPrint('Error loading persisted room: $e');
    }
  }

  Future<void> loadData() async => _loadPersistedData();

  Future<void> setRoom(types.Room? room) async {
    state = room;
    try {
      if (room == null) {
        await _sharedPref.clearData(key: 'selectedRoom');
      } else {
        await _sharedPref.setString(
          key: 'selectedRoom',
          value: jsonEncode(room.toJson()),
        );
      }
    } catch (e) {
      debugPrint('Error persisting room: $e');
    }
  }
}
