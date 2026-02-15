import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:sherise/features/home/data/ai_guardian_service.dart';
import 'package:sherise/core/services/background_call_manager.dart';
import 'package:proximity_sensor/proximity_sensor.dart';

class FakeCallPage extends StatefulWidget {
  const FakeCallPage({super.key});

  @override
  State<FakeCallPage> createState() => _FakeCallPageState();
}

class _FakeCallPageState extends State<FakeCallPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _vibrationTimer;

  @override
  void initState() {
    super.initState();
    _startRinging();
  }

  void _startRinging() async {
    try {
      final bytes = await rootBundle.load('lib/assets/sounds/ringtone.mp3');
      await _audioPlayer.setSource(BytesSource(bytes.buffer.asUint8List()));
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.resume();
    } catch (e) {
      debugPrint("Error playing ringtone: $e");
    }

    if (await Vibration.hasVibrator()) {
      _vibrationTimer = Timer.periodic(const Duration(milliseconds: 1000), (
        timer,
      ) {
        Vibration.vibrate(duration: 500);
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _vibrationTimer?.cancel();
    Vibration.cancel();
    super.dispose();
  }

  void _acceptCall() {
    _audioPlayer.stop();
    _vibrationTimer?.cancel();
    Vibration.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const DummyCallScreen()),
    );
  }

  void _declineCall() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              "https://w0.peakpx.com/wallpaper/5/2/HD-wallpaper-ios-14-stock-original-black-gradient-grey.jpg",
            ),
            fit: BoxFit.cover,
            opacity: 0.8,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  SizedBox(height: 60),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "fake_caller_name".tr(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "fake_caller_type".tr(),
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 80, left: 40, right: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        GestureDetector(
                          onTap: _declineCall,
                          child: Container(
                            height: 75,
                            width: 75,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.call_end,
                              color: Colors.white,
                              size: 35,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "call_decline".tr(),
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        GestureDetector(
                          onTap: _acceptCall,
                          child: Container(
                            height: 75,
                            width: 75,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.call,
                              color: Colors.white,
                              size: 35,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "call_accept".tr(),
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DummyCallScreen extends StatefulWidget {
  const DummyCallScreen({super.key});

  @override
  State<DummyCallScreen> createState() => _DummyCallScreenState();
}

class _DummyCallScreenState extends State<DummyCallScreen> {
  final AIGuardianService _aiService = AIGuardianService();
  StreamSubscription<dynamic>? _proximitySubscription;
  bool _isNear = false;

  Timer? _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _initializeGuardian();
  }

  void _initializeGuardian() async {
    // 1. Start Background Service
    await BackgroundCallManager.initialize();
    await BackgroundCallManager.startService();

    // 2. Initialize AI Services
    await _aiService.initTTS();
    await _aiService.initSpeech();

    // 3. Start Proximity Sensor
    _proximitySubscription = ProximitySensor.events.listen((int event) {
      if (mounted) {
        setState(() {
          // proximity_sensor plugin: 1 (or >0) usually means Object Detected (Near)
          // 0 usually means No Object (Far)
          // We want screen OFF (isNear=true) when Detected.
          _isNear = (event > 0);
        });
      }
    });

    // Start listening after a short delay to allow TTS init
    Future.delayed(const Duration(seconds: 1), () {
      _aiService.speak("Hello? Is everything okay?");
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _proximitySubscription?.cancel();
    _aiService.dispose();
    BackgroundCallManager.stopService();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int min = seconds ~/ 60;
    int sec = seconds % 60;
    return "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    const SizedBox(height: 60),
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, size: 60, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "fake_caller_name".tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _formatTime(_seconds),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 3,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    children: [
                      _buildCallOption(Icons.mic_off, "call_opt_mute".tr()),
                      _buildCallOption(Icons.dialpad, "call_opt_keypad".tr()),
                      _buildCallOption(
                        Icons.volume_up,
                        "call_opt_speaker".tr(),
                      ),
                      _buildCallOption(Icons.add, "call_opt_add".tr()),
                      _buildCallOption(Icons.videocam, "call_opt_video".tr()),
                      _buildCallOption(
                        Icons.contacts,
                        "call_opt_contacts".tr(),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 50),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      height: 75,
                      width: 75,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.call_end,
                        color: Colors.white,
                        size: 35,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Proximity Screen Off
        if (_isNear)
          Container(
            color: Colors.black,
            width: double.infinity,
            height: double.infinity,
          ),
      ],
    );
  }

  Widget _buildCallOption(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
