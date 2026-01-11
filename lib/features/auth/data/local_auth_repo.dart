import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sherise/features/auth/domain/entities/app_user.dart';
import 'package:sherise/features/auth/domain/repo/auth_repo.dart';

class LocalAuthRepo implements AuthRepo {
  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onCheckFailed,
  }) async {
    // Not needed for local auth
  }

  @override
  Future<AppUser?> verifyOtp(String verificationId, String otp) async {
    // Not needed for local auth
    return null;
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
    // user_age no longer stored independently
    await prefs.setString('user_dob', dob.toIso8601String());
    await prefs.setString('user_profile_pic', profilePicPath);
    // Mark as "logged in" effectively by having data
  }

  @override
  Future<void> completeSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setup_complete', true);
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name');
    final surname = prefs.getString('user_surname');
    final dobString = prefs.getString('user_dob');
    final isSetupComplete = prefs.getBool('setup_complete') ?? false;

    if (name != null && dobString != null) {
      return AppUser(
        uid: 'local_user',
        email: null,
        phoneNumber: null,
        creationTime: DateTime.now(), // approximation
        isNewUser: !isSetupComplete,
        name: name,
        surname: surname,
        dob: DateTime.parse(dobString),
        profilePicPath: prefs.getString('user_profile_pic'),
      );
    }
    return null;
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Wipe all data

    // Delete local profile picture
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/profile_pic.png');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignore errors during deletion
    }
  }

  @override
  Future<void> deleteAccount() async {
    await logout();
  }
}
