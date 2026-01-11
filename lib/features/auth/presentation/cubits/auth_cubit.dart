import 'package:sherise/features/auth/domain/entities/app_user.dart';
import 'package:sherise/features/auth/domain/repo/auth_repo.dart';
import 'package:sherise/features/auth/presentation/cubits/auth_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepo authRepo;
  AppUser? _currentUser;
  String? _verificationId;

  AuthCubit({required this.authRepo}) : super(AuthInitial());

  AppUser? get currentUser => _currentUser;

  void checkAuth() async {
    emit(AuthLoading());
    final AppUser? user = await authRepo.getCurrentUser();
    if (user != null) {
      _currentUser = user;
      emit(Authenticated(user));
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> sendOtp(String phoneNumber) async {
    emit(AuthLoading());
    await authRepo.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      onCodeSent: (verificationId) {
        _verificationId = verificationId;
        emit(AuthCodeSent(verificationId));
      },
      onCheckFailed: (error) {
        emit(AuthError(error));
        emit(Unauthenticated());
      },
    );
  }

  Future<void> verifyOtp(String otp) async {
    if (_verificationId == null) {
      emit(AuthError("Verification ID is missing. Request code again."));
      return;
    }
    emit(AuthLoading());
    try {
      final user = await authRepo.verifyOtp(_verificationId!, otp);
      if (user != null) {
        _currentUser = user;
        // Check if profile details are present. If not, maybe we are in setup flow?
        // But verifyOtp just logs in. The UI decides where to go next.
        emit(Authenticated(user));
      } else {
        emit(AuthError("Verification failed"));
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(Unauthenticated());
    }
  }

  Future<void> saveUserDetails({
    required String name,
    required String surname,
    required DateTime dob,
    required String profilePicPath,
  }) async {
    // Ideally this is called after phone verification or during it.
    // If the user is already authenticated (via phone), we just update the local data.
    emit(AuthLoading());
    try {
      await authRepo.saveUserDetails(
        name: name,
        surname: surname,
        dob: dob,
        profilePicPath: profilePicPath,
      );
      // Reload current user to include new details
      final updatedUser = await authRepo.getCurrentUser();
      if (updatedUser != null) {
        _currentUser = updatedUser;
        emit(Authenticated(updatedUser));
      } else {
        // Should not happen if we were authenticated
        checkAuth();
      }
    } catch (e) {
      emit(AuthError("Failed to save details: $e"));
      // Maintain previous state if possible, or reload
      checkAuth();
    }
  }

  Future<void> logout() async {
    emit(AuthLoading());
    await authRepo.logout();
    _currentUser = null;
    emit(Unauthenticated());
  }

  Future<void> deleteAccount() async {
    try {
      emit(AuthLoading());
      await authRepo.deleteAccount();
      _currentUser = null;
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(Unauthenticated());
    }
  }

  Future<void> completeSetup() async {
    emit(AuthLoading());
    try {
      await authRepo.completeSetup();
      final user = await authRepo.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        emit(Authenticated(user));
      } else {
        checkAuth();
      }
    } catch (e) {
      emit(AuthError(e.toString()));
      checkAuth();
    }
  }
}
