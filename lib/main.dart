import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sherise/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:sherise/colors/colors.dart';
import 'package:sherise/features/auth/data/local_auth_repo.dart';
import 'package:sherise/features/home/data/emergency_service.dart';
import 'package:sherise/features/safety/safety_service.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sherise/core/utils/smooth_scroll_behavior.dart';
import 'package:sherise/core/localization/file_asset_loader.dart';
import 'package:sherise/features/onboarding/presentation/pages/splash_screen.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:telephony/telephony.dart';

Timer? _widgetSosTimer;

// Background Callback for Home Widget
@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? data) async {
  if (data?.host == 'emergency') {
    WidgetsFlutterBinding.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    final isPlaying = prefs.getBool('widget_siren_playing') ?? false;
    final safetyService = SafetyService();
    
    if (isPlaying) {
      // User tapped during the waiting sequence
      _widgetSosTimer?.cancel();
      _widgetSosTimer = null;
      
      await safetyService.stopSiren();
      await prefs.setBool('widget_siren_playing', false);
      await HomeWidget.saveWidgetData<String>('widget_text', 'SOS');
      await HomeWidget.saveWidgetData<String>('widget_bg', 'idle');
      await HomeWidget.updateWidget(androidName: 'EmergencyWidget');
    } else {
      await safetyService.startSiren();
      await prefs.setBool('widget_siren_playing', true);
      await HomeWidget.saveWidgetData<String>('widget_text', 'STOP');
      await HomeWidget.saveWidgetData<String>('widget_bg', 'active');
      await HomeWidget.updateWidget(androidName: 'EmergencyWidget');
      
      final callEnabled = prefs.getBool('emergency_call_enabled') ?? true;
      if (callEnabled) {
        _widgetSosTimer?.cancel();
        _widgetSosTimer = Timer(const Duration(seconds: 10), () async {
          _widgetSosTimer = null;
          
          await safetyService.stopSiren();
          final latestPrefs = await SharedPreferences.getInstance();
          await latestPrefs.setBool('widget_siren_playing', false);
          
          await HomeWidget.saveWidgetData<String>('widget_text', 'SOS');
          await HomeWidget.saveWidgetData<String>('widget_bg', 'idle');
          await HomeWidget.updateWidget(androidName: 'EmergencyWidget');
          
          final service = EmergencyService();
          await service.triggerEmergency();
        });
      }
    }
  } else if (data?.host == 'location') {
    WidgetsFlutterBinding.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    final contactNumber = prefs.getString('emergency_contact');
    if (contactNumber != null && contactNumber.isNotEmpty) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        String message = "My current location: https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";
        await Telephony.instance.sendSms(to: contactNumber, message: message);
      } catch (e) {
        Position? position = await Geolocator.getLastKnownPosition();
        if (position != null) {
          String message = "My last known location: https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";
          await Telephony.instance.sendSms(to: contactNumber, message: message);
        }
      }
    }
  }
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Parallelize independent initializations to reduce startup time
  await Future.wait([
    dotenv.load(fileName: ".env"), // Load env vars
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
    RestartWidget(
      child: EasyLocalization(
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
    ),
  );
}

class RestartWidget extends StatefulWidget {
  final Widget child;

  const RestartWidget({super.key, required this.child});

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>()?.restartApp();
  }

  @override
  State<RestartWidget> createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key key = UniqueKey();

  void restartApp() {
    setState(() {
      key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: key, child: widget.child);
  }
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
        home: SplashScreen(onboardingComplete: widget.onboardingComplete),
      ),
    );
  }
}
