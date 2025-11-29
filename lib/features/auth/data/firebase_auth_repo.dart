//Firebase is our backend - you can swap out here...

import 'package:firebase_auth/firebase_auth.dart';
import 'package:sherise/features/auth/domain/entities/app_user.dart';
import 'package:sherise/features/auth/domain/repo/auth_repo.dart';

class FirebaseAuthRepo implements AuthRepo {
  //firebase auth
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  @override
  Future<AppUser?> loginWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      AppUser user = AppUser(
        uid: userCredential.user!.uid,
        email: email,
        creationTime: userCredential.user!.metadata.creationTime,
      );

      return user;
    } catch (e) {
      throw Exception('Login Failed: $e');
    }
  }

  @override
  Future<AppUser?> registerWithEmailPassword(
    String name,
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      AppUser user = AppUser(
        uid: userCredential.user!.uid,
        email: email,
        creationTime: userCredential.user!.metadata.creationTime,
      );

      return user;
    } catch (e) {
      throw Exception('Registration Failed: $e');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final user = firebaseAuth.currentUser;

      if (user == null) throw Exception('No user found');

      await user.delete();

      await logout();
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = firebaseAuth.currentUser;

    if (firebaseUser == null) return null;

    return AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email!,
      creationTime: firebaseUser.metadata.creationTime,
    );
  }

  @override
  Future<void> logout() async {
    await firebaseAuth.signOut();
  }

  @override
  Future<String> sendPasswordResetEmail(String email) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
      return "Password reset email sent! check your inbox";
    } catch (e) {
      return "An error occured: $e";
    }
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    try {
      // Use Firebase Auth's provider-based Google sign-in
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();

      // Add scopes if needed
      googleProvider.addScope('email');

      // Try signInWithProvider first (works better on some devices)
      UserCredential userCredential;
      try {
        userCredential = await firebaseAuth.signInWithProvider(googleProvider);
      } catch (providerError) {
        // Alternative: Use signInWithCredential with manual OAuth flow
        // This is a fallback method
        throw Exception(
          'Provider sign-in not supported on this device. Please use email/password login or try a different device.',
        );
      }

      // Get the Firebase user
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        return null;
      }

      AppUser appUser = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        creationTime: firebaseUser.metadata.creationTime,
      );

      return appUser;
    } catch (e) {
      return null;
    }
  }
}
