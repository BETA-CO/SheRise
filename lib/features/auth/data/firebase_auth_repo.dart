import 'package:firebase_auth/firebase_auth.dart';
import 'package:sherise/features/auth/domain/entities/app_user.dart';
import 'package:sherise/features/auth/domain/repo/auth_repo.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseAuthRepo implements AuthRepo {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onCheckFailed,
  }) async {
    await firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-resolution (Android only usually)
        // We can either sign in automatically or let the user know.
        // For simplicity in this flow, we might just sign in or treat it as verified.
        // But usually we just let the code validation handle it unless we fully support auto-verify.
        // Let's sign in to ensure the flow completes.
        try {
          await firebaseAuth.signInWithCredential(credential);
          // We don't have a specific callback for "done" without ID here in the repo interface,
          // but the UI monitoring the stream or the cubit will see the auth state change.
          // However, to fit the standard flow, usually we just wait for code input.
          // If we want auto-verify:
          // onCodeSent("AUTO_VERIFIED"); // Hacky.
        } catch (e) {
          onCheckFailed(e.toString());
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        onCheckFailed(e.message ?? "Verification Failed");
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Timeout
      },
    );
  }

  @override
  Future<AppUser?> verifyOtp(String verificationId, String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final userCredential = await firebaseAuth.signInWithCredential(
        credential,
      );
      final firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // Load local details to return a full user
        final localDetails = await loadUserDetails();
        return AppUser(
          uid: firebaseUser.uid,
          email: firebaseUser.email,
          phoneNumber: firebaseUser.phoneNumber,
          creationTime: firebaseUser.metadata.creationTime,
          isNewUser: userCredential.additionalUserInfo?.isNewUser ?? false,
          name: localDetails?['name'],
          surname: localDetails?['surname'],
          dob: localDetails?['dob'] != null
              ? DateTime.parse(localDetails!['dob'])
              : null,
          profilePicPath: localDetails?['profilePicPath'],
        );
      }
      return null;
    } catch (e) {
      throw Exception('OTP Verification Failed: $e');
    }
  }

  @override
  Future<void> saveUserDetails({
    required String name,
    required String surname,
    required DateTime dob,
    required String profilePicPath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_surname', surname);
    // age is calculated dynamically now
    await prefs.setString('user_dob', dob.toIso8601String());
    await prefs.setString('user_profile_pic', profilePicPath);
  }

  Future<Map<String, dynamic>?> loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name');
    final surname = prefs.getString('user_surname');
    final dob = prefs.getString('user_dob');
    final profilePic = prefs.getString('user_profile_pic');

    if (name != null) {
      return {
        'name': name,
        'surname': surname,
        'dob': dob,
        'profilePicPath': profilePic,
      };
    }
    return null;
  }

  @override
  Future<void> completeSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setup_complete', true);
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    final localDetails = await loadUserDetails();
    final prefs = await SharedPreferences.getInstance();
    final isSetupComplete = prefs.getBool('setup_complete') ?? false;

    return AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email,
      phoneNumber: firebaseUser.phoneNumber,
      creationTime: firebaseUser.metadata.creationTime,
      isNewUser: !isSetupComplete,
      name: localDetails?['name'],
      surname: localDetails?['surname'],
      dob: localDetails?['dob'] != null
          ? DateTime.parse(localDetails!['dob'])
          : null,
      profilePicPath: localDetails?['profilePicPath'],
    );
  }

  @override
  Future<void> logout() async {
    await firebaseAuth.signOut();
    // Optional: Clear local data? The user said "store this data... somewhere".
    // Usually logout implies clearing session. But maybe we keep the data for next login?
    // Let's keep it for now as "Profile" often persists on device.
    // If user wants to "forget", we'd clear.
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) throw Exception('No user found');
      await user.delete();
      await logout();
      // Clear local data on account deletion
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_name');
      await prefs.remove('user_surname');
      await prefs.remove('user_dob');
      await prefs.remove('user_profile_pic');
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }
}
