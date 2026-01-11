/*
Auth page - Entry point for authentication flow.
Redirects to UserDetailsPage for Name/Age/DOB collection.
*/

import 'package:flutter/material.dart';
import 'package:sherise/features/auth/presentation/pages/user_details_page.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const UserDetailsPage();
  }
}
