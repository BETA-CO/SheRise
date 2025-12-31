import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'package:telephony/telephony.dart';
import 'package:vibration/vibration.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sherise/features/safety/shake_detector.dart';

class SafetyService {
  final Telephony _telephony = Telephony.instance;
  final AudioPlayer _audioPlayer = AudioPlayer();
  ShakeDetector? _shakeDetector;
  bool _ispanicModeActive = false;

  // Initialize the safety service
  void init() {
    _shakeDetector = ShakeDetector(onPhoneShake: _triggerPanicMode);
    _shakeDetector?.startListening();
  }

  void dispose() {
    _shakeDetector?.stopListening();
    _audioPlayer.dispose();
  }

  Future<void> _triggerPanicMode() async {
    if (_ispanicModeActive) return;
    _ispanicModeActive = true;

    // 1. Vibrate
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(
        pattern: [500, 1000, 500, 1000],
        intensities: [1, 255, 1, 255],
      );
    }

    // 2. Play Sound (Siren)
    // Assuming we have a siren.mp3 in assets/sounds/ or we can play a system sound
    // For now, let's just use vibration as the primary feedback if sound is missing,
    // but code is here for sound.
    try {
      await _audioPlayer.setSource(AssetSource('sounds/siren.mp3'));
      await _audioPlayer.resume();
    } catch (e) {
      print("Audio player error: $e");
    }

    // 3. Send SMS with Location
    await _sendEmergencySMS();

    // Reset panic mode after some time or manual stop
    Future.delayed(const Duration(seconds: 10), () {
      _stopPanicMode();
    });
  }

  Future<void> _stopPanicMode() async {
    _ispanicModeActive = false;
    await _audioPlayer.stop();
    Vibration.cancel();
  }

  Future<void> _sendEmergencySMS() async {
    // Check permissions
    bool? permissionsGranted = await _telephony.requestPhoneAndSmsPermissions;
    if (permissionsGranted != true) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String googleMapsLink =
          "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";
      String message =
          "HELP! I need emergency assistance. My location: $googleMapsLink";

      // TODO: Replace with actual emergency contacts from user settings
      List<String> recipients = ["1234567890"];

      for (String recipient in recipients) {
        await _telephony.sendSms(to: recipient, message: message);
      }
    } catch (e) {
      print("Error sending emergency SMS: $e");
    }
  }

  // Live Location Sharing (Passive)
  // Live Location Sharing (Passive)
  Timer? _locationTimer;
  bool _isSharingLocation = false;

  Future<void> startLocationSharingSession(List<String> recipients) async {
    if (_isSharingLocation) return;
    _isSharingLocation = true;

    // Send immediate update
    await _sendLocationUpdate(recipients, isFirst: true);

    // Schedule updates every 10 minutes for 1 hour (6 updates total)
    int updatesSent = 0;
    const int maxUpdates = 6;

    _locationTimer = Timer.periodic(const Duration(minutes: 10), (timer) async {
      updatesSent++;
      if (updatesSent >= maxUpdates) {
        stopLocationSharingSession();
      } else {
        await _sendLocationUpdate(recipients);
      }
    });
  }

  void stopLocationSharingSession() {
    _isSharingLocation = false;
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  Future<void> _sendLocationUpdate(
    List<String> recipients, {
    bool isFirst = false,
  }) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String googleMapsLink =
          "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";
      String prefix = isFirst
          ? "Started sharing my live location (1h session):"
          : "Update: My current location:";
      String message = "$prefix $googleMapsLink";

      for (String recipient in recipients) {
        await _telephony.sendSms(to: recipient, message: message);
      }
    } catch (e) {
      print("Error sharing location: $e");
    }
  }
}
