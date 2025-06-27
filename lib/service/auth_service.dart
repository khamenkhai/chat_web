import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_application/fyrechat/fyrechat.dart' as fc;

class AuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String imageUrl,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await fc.FyreChat.instance.createUserInFirestore(
      fc.User(
        id: credential.user!.uid,
        firstName: firstName,
        lastName: lastName,
        imageUrl: imageUrl,
      ),
    );
  }

  Future<User?> getCurrentUser()async{
    return _auth.currentUser;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
