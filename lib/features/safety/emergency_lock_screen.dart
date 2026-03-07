import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sherise/features/safety/safety_service.dart';
import 'package:sherise/features/auth/data/biometric_service.dart';

class EmergencyLockScreen extends StatefulWidget {
  const EmergencyLockScreen({super.key});

  @override
  State<EmergencyLockScreen> createState() => _EmergencyLockScreenState();
}

class _EmergencyLockScreenState extends State<EmergencyLockScreen> {
  final BiometricService _biometricService = BiometricService();
  String _errorMessage = "";

  Future<void> _handleStopEmergency() async {
    final bool didAuthenticate = await _biometricService.authenticate();

    if (didAuthenticate) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('emergency_active', false);
      await SafetyService().stopSiren();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      setState(() {
        _errorMessage = "Authentication failed! Emergency continues.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade900,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 100,
              ),
              const SizedBox(height: 24),
              const Text(
                'EMERGENCY MODE ACTIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Siren and Strobe are active.\nLocation sent to emergency contacts.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.yellow,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.lock_open),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red.shade900,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _handleStopEmergency,
                  label: const Text(
                    'USE DEVICE LOCK TO STOP',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
