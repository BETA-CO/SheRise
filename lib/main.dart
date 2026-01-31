import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sherise/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:sherise/colors/colors.dart';
import 'package:sherise/features/auth/data/local_auth_repo.dart';
import 'package:sherise/features/home/data/emergency_service.dart';
import 'package:home_widget/home_widget.dart';
import 'package:sherise/features/auth/presentation/pages/auth_flow_wrapper.dart';
import 'package:sherise/features/onboarding/presentation/pages/landing_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sherise/core/utils/smooth_scroll_behavior.dart';
import 'package:sherise/core/localization/file_asset_loader.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

// Background Callback for Home Widget
@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? data) async {
  if (data?.host == 'emergency') {
    final service = EmergencyService();
    await service.triggerEmergency();
  }
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Parallelize independent initializations to reduce startup time
  await Future.wait([
    EasyLocalization.ensureInitialized(),
    HomeWidget.registerInteractivityCallback(backgroundCallback),
    // Preload shared preferences concurrently
    SharedPreferences.getInstance(),
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Prefs are likely ready now from the parallel wait above
  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

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
      assetLoader: const FileAssetLoader(),
      fallbackLocale: const Locale('en'),
      child: MyApp(onboardingComplete: onboardingComplete),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool onboardingComplete;

  const MyApp({super.key, required this.onboardingComplete});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final authRepo = LocalAuthRepo();

  @override
  void initState() {
    super.initState();
    // FlutterNativeSplash.remove(); // Removed: Handled in AuthFlowWrapper/LandingPage
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit(authRepo: authRepo)..checkAuth(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: lightmode.copyWith(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: CupertinoPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),
        ),
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        builder: (context, child) {
          return ScrollConfiguration(
            behavior: SmoothScrollBehavior(),
            child: child!,
          );
        },
        home: widget.onboardingComplete
            ? const AuthFlowWrapper()
            : const LandingPage(),
      ),
    );
  }
}
