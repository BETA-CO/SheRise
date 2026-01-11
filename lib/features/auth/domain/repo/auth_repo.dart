// Auth Repo - outlines the possible auth operations for this app

import '../entities/app_user.dart';

abstract class AuthRepo {
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onCheckFailed,
  });
  Future<AppUser?> verifyOtp(String verificationId, String smsCode);
  Future<void> logout();
  Future<AppUser?> getCurrentUser();
  Future<void> deleteAccount();
  Future<void> saveUserDetails({
    required String name,
    required String surname,
    required DateTime dob,
    required String profilePicPath,
  });
  Future<void> completeSetup();
}
