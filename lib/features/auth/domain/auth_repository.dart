import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  User? get currentUser;

  Future<User?> signIn(String email, String password);
  Future<User?> signUp(String email, String password);
  Future<void> signOut();
  Future<void> deleteAccount();
  Future<void> reloadUser();
  Future<void> sendEmailVerification();
  bool isEmailVerified();
}
