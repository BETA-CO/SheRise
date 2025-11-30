import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sherise/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:sherise/features/auth/presentation/cubits/auth_states.dart';
import 'package:sherise/features/auth/presentation/pages/pin_lock_screen.dart';

class AppLockWrapper extends StatefulWidget {
  final Widget child;
  const AppLockWrapper({super.key, required this.child});

  @override
  State<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends State<AppLockWrapper>
    with WidgetsBindingObserver {
  bool _isLocked = false;
  bool _isAppLockEnabled = false;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAppLockStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkAppLockStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAppLockEnabled = prefs.getBool('app_lock_enabled') ?? false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _handlePaused();
    } else if (state == AppLifecycleState.resumed) {
      _handleResumed();
    }
  }

  Future<void> _handlePaused() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('app_lock_enabled') ?? false;
    if (enabled) {
      setState(() {
        _isLocked = true;
        _isAppLockEnabled = true;
      });
    } else {
      setState(() {
        _isAppLockEnabled = false;
      });
    }
  }

  Future<void> _handleResumed() async {
    if (_isLocked && _isAppLockEnabled && _isAuthenticated) {
      // UI will show lock screen automatically due to _isLocked = true
    }
  }

  void _onUnlock() {
    setState(() {
      _isLocked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          setState(() {
            _isAuthenticated = true;
          });
          if (_isAppLockEnabled) {
            setState(() {
              _isLocked = true;
            });
          }
        } else if (state is Unauthenticated) {
          setState(() {
            _isAuthenticated = false;
            _isLocked = false;
          });
        }
      },
      child: Stack(
        children: [
          widget.child,
          if (_isLocked && _isAuthenticated) PinLockScreen(onUnlock: _onUnlock),
        ],
      ),
    );
  }
}
