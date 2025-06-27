import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chat_application/fyrechat/fyrechat.dart' as fc;
import 'package:firebase_auth/firebase_auth.dart';

final profileControllerProvider =
    StateNotifierProvider<ProfileController, AsyncValue<fc.User?>>((ref) {
  return ProfileController();
});

class ProfileController extends StateNotifier<AsyncValue<fc.User?>> {
  ProfileController() : super(const AsyncValue.loading()) {
    loadUserData();
  }

  final chatService = fc.FyreChat.instance;

  Future<void> loadUserData() async {
    state = const AsyncValue.loading();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await chatService.getUserById(user.uid);
        state = AsyncValue.data(userData);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    String? imageUrl,
  }) async {
    final currentUser = state.value;
    if (currentUser == null) return;

    state = const AsyncValue.loading();
    try {
      await chatService.updateUserData(
        userId: currentUser.id,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        imageUrl: imageUrl,
      );
      await loadUserData(); // Refresh the data
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> uploadImage() async {
    // Simulate image upload
    await Future.delayed(const Duration(seconds: 1));
  }
}
