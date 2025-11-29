import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sherise/features/chatbot/presentation/pages/chatbot_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telephony/telephony.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int _tapCount = 0;
  DateTime? _lastTapTime;
  final Telephony telephony = Telephony.instance;

  // Popup State
  // Timer for reset
  Timer? _resetTimer;

  final List<String> quotes = [
    "You are doing amazing, keep going!",
    "I believe in you, don't give up.",
    "You've got this, just breathe.",
    "Your strength inspires everyone around you.",
    "Take it one step at a time, you're doing great.",
    "You deserve all the happiness in the world.",
    "Don't forget how far you've come.",
    "I'm cheering for you, always.",
    "You are capable of incredible things.",
    "Trust yourself, you know the way.",
  ];

  late String randomQuote;

  @override
  void initState() {
    super.initState();
    _selectRandomQuote();
    _requestPermissions();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1, milliseconds: 500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.location,
      Permission.sms,
      Permission.phone,
      Permission.contacts,
    ].request();
  }

  void _selectRandomQuote() {
    final random = Random();
    randomQuote = quotes[random.nextInt(quotes.length)];
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color.fromARGB(255, 255, 236, 242), Colors.white],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            "welcome_back".tr(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 24,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ChatBotPage(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.message_outlined,
                              color: Colors.black,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                '"$randomQuote"',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.pinkAccent,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: GestureDetector(
                              onTap: _handleEmergencyTap,
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFFF5252),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFF5252,
                                      ).withOpacity(0.4),
                                      blurRadius: 20,
                                      spreadRadius: 4,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.sos_rounded,
                                      color: Colors.white,
                                      size: 56,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _tapCount > 0
                                          ? "${8 - _tapCount}"
                                          : "EMERGENCY",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.bold,
                                        fontSize: _tapCount > 0 ? 24 : 14,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          // 4 Feature Buttons
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildFeatureButton(
                                        Icons.local_police_outlined,
                                        "Police",
                                        () => _showCallConfirmationDialog(
                                          "Police",
                                          "100",
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildFeatureButton(
                                        Icons.support_agent_outlined,
                                        "Women Helpline",
                                        () => _showCallConfirmationDialog(
                                          "Women Helpline",
                                          "1091",
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildFeatureButton(
                                        Icons.medical_services_outlined,
                                        "Ambulance",
                                        () => _showCallConfirmationDialog(
                                          "Ambulance",
                                          "108",
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildFeatureButton(
                                        Icons.monitor_heart_outlined,
                                        "Medical Advice",
                                        () => _showCallConfirmationDialog(
                                          "Medical Advice",
                                          "104",
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Custom Popup
        ],
      ),
    );
  }

  void _showCallConfirmationDialog(String name, String number) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Call $name?"),
        content: Text("Are you sure you want to call $number?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              FlutterPhoneDirectCaller.callNumber(number);
            },
            child: const Text(
              "Call",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _handleEmergencyTap() async {
    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) > const Duration(seconds: 2)) {
      setState(() {
        _tapCount = 0; // Reset if too slow
      });
    }
    _lastTapTime = now;

    setState(() {
      _tapCount++;
    });

    // Cancel existing timer
    _resetTimer?.cancel();

    if (_tapCount < 8) {
      // Set timer to reset count after 2 seconds of inactivity
      _resetTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _tapCount = 0;
          });
        }
      });
    } else {
      setState(() {
        _tapCount = 0;
      });
      _triggerEmergency();
    }
  }

  Future<void> _triggerEmergency() async {
    final prefs = await SharedPreferences.getInstance();
    final contactNumber = prefs.getString('emergency_contact');

    if (contactNumber == null || contactNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set an emergency contact in Settings first!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check permissions again just in case
    if (await Permission.location.isDenied ||
        await Permission.sms.isDenied ||
        await Permission.phone.isDenied) {
      await _requestPermissions();
      if (await Permission.location.isDenied) return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String message =
          "Your daughter needs help! Location: https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";

      // 1. Send SMS in Background using Telephony
      await telephony.sendSms(to: contactNumber, message: message).catchError((
        error,
      ) {
        debugPrint('SMS Error: $error');
      });

      // 2. Make Direct Call
      // Check preference first
      final callEnabled = prefs.getBool('emergency_call_enabled') ?? true;
      if (callEnabled) {
        // Small delay to ensure SMS process starts
        await Future.delayed(const Duration(seconds: 2));
        await FlutterPhoneDirectCaller.callNumber(contactNumber);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error triggering emergency: $e')));
    }
  }

  Widget _buildFeatureButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1.3,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.pinkAccent),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
