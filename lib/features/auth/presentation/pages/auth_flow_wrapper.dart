import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sherise/features/auth/presentation/components/app_lock_wrapper.dart';
import 'package:sherise/features/auth/presentation/components/loading.dart';
import 'package:sherise/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:sherise/features/auth/presentation/cubits/auth_states.dart';
import 'package:sherise/features/auth/presentation/pages/auth_page.dart';
import 'package:sherise/features/auth/presentation/pages/setup_page.dart';
import 'package:sherise/features/home/presentation/pages/MainPage.dart';

class AuthFlowWrapper extends StatelessWidget {
  const AuthFlowWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLockWrapper(
      child: BlocConsumer<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is Unauthenticated) {
            return const AuthPage();
          }
          if (state is Authenticated) {
            if (state.user.isNewUser) {
              return const SetupPage();
            }
            return const MainPage();
          } else {
            return const LoadingScreen();
          }
        },
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
      ),
    );
  }
}
