import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sherise/features/home/data/ai_guardian_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIGuardianBackgroundService {
  static final FlutterBackgroundService _service = FlutterBackgroundService();

  static Future<void> initialize() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'ai_guardian_channel', // id
      'AI Guardian Service', // name
      description: 'Maintains AI Guardian connection',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    if (await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission() !=
        true) {
      // Handle permission denied
    }

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'ai_guardian_channel',
        initialNotificationTitle: 'AI Guardian Active',
        initialNotificationContent: 'Initializing...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  static Future<void> startService() async {
    await _service.startService();
  }

  static Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke("stopService");
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    // Load env for API keys if needed
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint("Error loading .env in background: $e");
    }

    final AIGuardianService aiGuardian = AIGuardianService();

    // Initialize AI Service
    await aiGuardian.initSpeech();
    await aiGuardian.initTTS();
    aiGuardian.startListening();

    // Initial Greeting (Safety Check)
    await Future.delayed(const Duration(seconds: 1));
    await aiGuardian.speak("Hello? Is everything okay?");

    // Timer for notification
    int secondsElapsed = 0;
    Timer? timer;

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      timer?.cancel();
      aiGuardian.dispose();
      service.stopSelf();
    });

    // Start Timer
    timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      secondsElapsed++;
      String formattedTime = _formatDuration(Duration(seconds: secondsElapsed));

      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          // Update notification with "End Call" action
          // Note: To add actions dynamically, we might need to use flutter_local_notifications directly
          // but flutter_background_service helper is limited.
          // For now, we update the content. A custom notification approach is better for actions
          // but let's try to see if we can use the plugin's notification update mechanism.

          service.setForegroundNotificationInfo(
            title: "AI Guardian Active",
            content: "Call Duration: $formattedTime",
          );

          // To add buttons, we need to use flutter_local_notifications plugin instance
          // and update the notification with the SAME ID (888).
          _updateNotificationWithAction(secondsElapsed);
        }
      }
    });
  }

  static void _updateNotificationWithAction(int secondsElapsed) {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    String formattedTime = _formatDuration(Duration(seconds: secondsElapsed));

    flutterLocalNotificationsPlugin.show(
      id: 888,
      title: 'AI Guardian Active',
      body: 'Call Duration: $formattedTime',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'ai_guardian_channel',
          'AI Guardian Service',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          /* actions: [
            AndroidNotificationAction(
              'stop_service',
              'End Call',
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ], */
        ),
      ),
    );
  }

  static String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @pragma('vm:entry-point')
  static bool onIosBackground(ServiceInstance service) {
    WidgetsFlutterBinding.ensureInitialized();
    return true;
  }
}
