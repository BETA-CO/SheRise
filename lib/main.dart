import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sherise/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:sherise/colors/colors.dart';
import 'package:sherise/firebase_options.dart';
import 'package:sherise/features/auth/data/firebase_auth_repo.dart';
import 'package:sherise/features/safety/safety_service.dart';
import 'package:sherise/features/home/data/emergency_service.dart';
import 'package:home_widget/home_widget.dart';
import 'package:sherise/features/auth/presentation/pages/auth_flow_wrapper.dart';
import 'package:sherise/features/onboarding/presentation/pages/landing_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Background Callback for Home Widget
@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? data) async {
  if (data?.host == 'emergency') {
    final service = EmergencyService();
    await service.triggerEmergency();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HomeWidget.registerInteractivityCallback(backgroundCallback);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('mr'),
        Locale('te'),
        Locale('bn'),
        Locale('pa'),
      ],
      path: 'lib/assets/lang',
      fallbackLocale: const Locale('en'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final firebaseAuthRepo = FirebaseAuthRepo();
  final safetyService = SafetyService(); // Initialize SafetyService
  bool? _onboardingComplete;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
    safetyService.init(); // Start listening for shakes
  }

  @override
  void dispose() {
    safetyService.dispose();
    super.dispose();
  }

  Future<void> _checkOnboardingStatus() async {
    // Add a small delay to ensure shared prefs is ready if needed,
    // though usually await SharedPreferences.getInstance() is enough
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking onboarding status
    if (_onboardingComplete == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (context) =>
              AuthCubit(authRepo: firebaseAuthRepo)..checkAuth(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: lightmode,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: _onboardingComplete!
            ? const AuthFlowWrapper()
            : const LandingPage(),
      ),
    );
  }
}
