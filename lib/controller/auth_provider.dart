import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_web/service/auth_service.dart';

// AUTH STATE
@immutable
abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

// PROVIDER
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref, AuthService()),
);

// CONTROLLER
class AuthController extends StateNotifier<AuthState> {
  final Ref ref;
  final AuthService authService;

  AuthController(this.ref, this.authService) : super(const AuthInitial()) {
    authService.authStateChanges().listen((user) {
      if (user != null) {
        state = AuthAuthenticated(user);
      } else {
        state = const AuthUnauthenticated();
      }
    });
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      state = const AuthLoading();
      await authService.signInWithEmailAndPassword(email, password);
    } on FirebaseAuthException catch (e) {
      state = AuthError(e.message ?? 'Sign in failed');
    }
  }

  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String imageUrl,
  }) async {
    try {
      state = const AuthLoading();
      await authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        imageUrl: imageUrl,
      );
    } on FirebaseAuthException catch (e) {
      state = AuthError(e.message ?? 'Sign up failed');
    } catch (e) {
      state = AuthError('An unexpected error occurred');
    }
  }

   Future<User?> getCurrentUser()async{
    return authService.getCurrentUser();
  }

  Future<void> signOut() async {
    try {
      state = const AuthLoading();
      await authService.signOut();
    } catch (e) {
      state = AuthError('Sign out failed');
    }
  }
}
