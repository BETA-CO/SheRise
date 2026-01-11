import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Bring to foreground
  if (service is AndroidServiceInstance) {
    if (await service.isForegroundService()) {
      flutterLocalNotificationsPlugin.show(
        888,
        'SheRise Safety Service',
        'Active Location Sharing Enabled',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'sherise_safety_channel',
            'Safety Service',
            icon: 'ic_bg_service_small',
            ongoing: true,
          ),
        ),
      );
    }
  }

  // Periodic Location Updates
  Timer.periodic(const Duration(seconds: 15), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        // Update notification content if needed
        // service.setForegroundNotificationInfo(...)
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print('Background Location: ${position.latitude}, ${position.longitude}');

      // Here we would implement the logic to send this to the trusted contacts
      // For now, we print it. To fully implement, we need to pass the recipients list
      // to this isolate or fetch from SharedPreferences.

      final prefs = await SharedPreferences.getInstance();
      String? contact = prefs.getString('emergency_contact');
      // Optimizing: Don't spam SMS every 15s. Logic needed to send only every X mins.

      service.invoke('update', {
        "lat": position.latitude,
        "lng": position.longitude,
      });
    } catch (e) {
      print("Background Location Error: $e");
    }
  });
}

class BackgroundLocationService {
  Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'sherise_safety_channel',
        initialNotificationTitle: 'SheRise Service',
        initialNotificationContent: 'Initializing...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        onForeground: onStart,
        onBackground: onServiceIosBackground,
      ),
    );
  }

  // Start the service
  Future<void> startService() async {
    final service = FlutterBackgroundService();
    await service.startService();
  }

  // Stop the service
  void stopService() {
    final service = FlutterBackgroundService();
    service.invoke("stopService");
  }
}

@pragma('vm:entry-point')
Future<bool> onServiceIosBackground(ServiceInstance service) async {
  return true;
}
