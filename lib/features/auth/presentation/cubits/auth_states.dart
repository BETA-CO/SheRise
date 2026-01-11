// Auth states

import 'package:sherise/features/auth/domain/entities/app_user.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final AppUser user;
  Authenticated(this.user);
}

class Unauthenticated extends AuthState {}

class AuthCodeSent extends AuthState {
  final String verificationId;
  AuthCodeSent(this.verificationId);
}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}
