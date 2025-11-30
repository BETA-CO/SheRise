//Firebase is our backend - you can swap out here...

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sherise/features/auth/domain/entities/app_user.dart';
import 'package:sherise/features/auth/domain/repo/auth_repo.dart';

class FirebaseAuthRepo implements AuthRepo {
  //firebase auth
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  Future<AppUser?> loginWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      AppUser user = AppUser(
        uid: userCredential.user!.uid,
        email: email,
        creationTime: userCredential.user!.metadata.creationTime,
        isNewUser: false, // Login implies existing user
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
        isNewUser: true, // Registration implies new user
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
      isNewUser: false, // Current user is already logged in
    );
  }

  @override
  Future<void> logout() async {
    await _googleSignIn.signOut();
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
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google [UserCredential]
      final UserCredential userCredential = await firebaseAuth
          .signInWithCredential(credential);

      // Get the Firebase user
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        return null;
      }

      // Check if it's a new user
      // creationTime and lastSignInTime are usually close for new users
      // But userCredential.additionalUserInfo?.isNewUser is more reliable
      bool isNew = userCredential.additionalUserInfo?.isNewUser ?? false;

      AppUser appUser = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        creationTime: firebaseUser.metadata.creationTime,
        isNewUser: isNew,
      );

      return appUser;
    } catch (e) {
      print("Google Sign In Error: $e");
      return null;
    }
  }
}
