import 'package:audioplayers/audioplayers.dart';
import 'package:torch_light/torch_light.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:telephony/telephony.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:sherise/features/safety/shake_detector.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SafetyService {
  static final SafetyService _instance = SafetyService._internal();
  static const _channel = MethodChannel('com.example.sherise/emergency');

  factory SafetyService() {
    return _instance;
  }

  SafetyService._internal() {
    _initAudio();
  }


  void _initAudio() async {
    // Global configuration to allow mixing with other apps and active mic sessions
    await AudioPlayer.global.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          usageType: AndroidUsageType.alarm,
          contentType: AndroidContentType.sonification,
          audioFocus: AndroidAudioFocus.none, // Don't request exclusive focus
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playAndRecord,
          options: {
            AVAudioSessionOptions.mixWithOthers,
            AVAudioSessionOptions.defaultToSpeaker,
            AVAudioSessionOptions.allowBluetooth,
          },
        ),
      ),
    );
  }

  final Telephony _telephony = Telephony.instance;
  final AudioPlayer _audioPlayer = AudioPlayer();

  void dispose() {
    _audioPlayer.dispose();
    _stopStrobe();
  }

  // --- Public Methods for SOS Button ---

  Future<void> startSiren() async {
    try {
      // Use BytesSource to play from rootBundle regardless of asset prefix
      final bytes = await rootBundle.load('lib/assets/sounds/siren.mp3');
      await _audioPlayer.setSource(BytesSource(bytes.buffer.asUint8List()));
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop); // Keep siren looping
      await _audioPlayer.resume();
      _startStrobe();
    } catch (e) {
      debugPrint("Audio player error (Assets missing?): $e");
    }
  }

  Future<void> stopSiren() async {
    await _audioPlayer.stop();
    await _stopStrobe();
  }

  Future<void> sendEmergencySMS() async {
    await _sendEmergencySMS();
  }

  // --- Internal Logic ---

  Future<void> _sendEmergencySMS() async {
    // Check permissions
    bool? permissionsGranted = await _telephony.requestPhoneAndSmsPermissions;
    if (permissionsGranted != true) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      String googleMapsLink =
          "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";
      String message =
          "HELP! I need emergency assistance. My location: $googleMapsLink";

      final prefs = await SharedPreferences.getInstance();
      String? primaryContact = prefs.getString('emergency_contact');
      List<String>? otherContacts = prefs.getStringList(
        'emergency_contacts_list',
      );

      List<String> recipients = [];

      // Add primary contact
      if (primaryContact != null && primaryContact.isNotEmpty) {
        recipients.add(primaryContact);
      }

      // Add other contacts from trusted circle
      if (otherContacts != null) {
        recipients.addAll(otherContacts);
      }

      // Deduplicate
      recipients = recipients.toSet().toList();

      if (recipients.isEmpty) {
        debugPrint("No emergency contacts saved!");
        return;
      }

      for (String recipient in recipients) {
        await _telephony.sendSms(to: recipient, message: message);
      }
    } catch (e) {
      debugPrint("Error sending emergency SMS: $e");
    }
  }

  // Live Location Sharing (Passive)
  Timer? _locationTimer;
  bool _isSharingLocation = false;

  Future<void> startLocationSharingSession(List<String> recipients) async {
    if (_isSharingLocation) return;
    _isSharingLocation = true;

    // Send immediate update
    await _sendLocationUpdate(recipients, isFirst: true);

    // Schedule updates every 15 minutes for 1 hour (4 updates total)
    int updatesSent = 0;
    const int maxUpdates = 4;

    _locationTimer = Timer.periodic(const Duration(minutes: 15), (timer) async {
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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
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
      debugPrint("Error sharing location: $e");
    }
  }

  // --- Flashlight Strobe Logic ---
  Timer? _strobeTimer;

  void _startStrobe() {
    _strobeTimer?.cancel();
    bool isOn = true;
    // Toggle every 100ms for high frequency
    _strobeTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      try {
        if (isOn) {
          await TorchLight.enableTorch();
        } else {
          await TorchLight.disableTorch();
        }
        isOn = !isOn;
      } catch (e) {
        debugPrint("Torch error: $e");
      }
    });
  }

  Future<void> _stopStrobe() async {
    _strobeTimer?.cancel();
    _strobeTimer = null;
    try {
      await TorchLight.disableTorch();
    } catch (e) {
      debugPrint("Torch error on stop: $e");
    }
  }
}
