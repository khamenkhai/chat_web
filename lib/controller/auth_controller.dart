import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  (ref) => AuthController(ref),
);

// CONTROLLER
class AuthController extends StateNotifier<AuthState> {
  final Ref ref;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthController(this.ref) : super(const AuthInitial()) {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        state = AuthAuthenticated(user);
      } else {
        state = const AuthUnauthenticated();
      }
    });
  }

  Future<void> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      state = const AuthLoading();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // Firebase handles state update through authStateChanges stream
    } on FirebaseAuthException catch (e) {
      state = AuthError(e.message ?? 'Sign in failed');
    }
  }

  Future<void> signUpWithEmailAndPassword(
      String email, String password) async {
    try {
      state = const AuthLoading();
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      state = AuthError(e.message ?? 'Sign up failed');
    }
  }

  Future<void> signOut() async {
    try {
      state = const AuthLoading();
      await _auth.signOut();
    } catch (e) {
      state = AuthError('Sign out failed');
    }
  }
}
