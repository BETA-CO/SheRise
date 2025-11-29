import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telephony/telephony.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter/foundation.dart';

class EmergencyService {
  final Telephony telephony = Telephony.instance;

  Future<void> triggerEmergency({
    Function(String)? onError,
    Function(String)? onSuccess,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final contactNumber = prefs.getString('emergency_contact');

    if (contactNumber == null || contactNumber.isEmpty) {
      onError?.call('Please set an emergency contact in Settings first!');
      return;
    }

    // Check permissions
    if (await Permission.location.isDenied ||
        await Permission.sms.isDenied ||
        await Permission.phone.isDenied) {
      onError?.call('Missing permissions. Please open app to grant them.');
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String message =
          "Your daughter needs help! Location: https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";

      // 1. Send SMS
      await telephony.sendSms(to: contactNumber, message: message).catchError((
        error,
      ) {
        debugPrint('SMS Error: $error');
        onError?.call('SMS Error: $error');
      });

      // 2. Make Direct Call
      // Check preference first
      final callEnabled = prefs.getBool('emergency_call_enabled') ?? true;
      if (callEnabled) {
        // Small delay to ensure SMS process starts
        await Future.delayed(const Duration(seconds: 2));
        await FlutterPhoneDirectCaller.callNumber(contactNumber);
      }

      onSuccess?.call('Emergency SOS triggered!');
    } catch (e) {
      onError?.call('Error triggering emergency: $e');
    }
  }
}
