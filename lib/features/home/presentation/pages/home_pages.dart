import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sherise/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:sherise/features/auth/presentation/cubits/auth_states.dart';
import 'package:sherise/features/chatbot/presentation/pages/chatbot_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telephony/telephony.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:sherise/features/wellness/wellness_page.dart';
import 'package:sherise/features/map/nearby_places_page.dart';
import 'package:sherise/features/legal/legal_rights_page.dart';
import 'package:sherise/features/safety/safety_service.dart';
import 'package:sherise/features/home/presentation/pages/fake_call_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  // SOS State
  bool _isSOSActive = false;
  int _countdownSeconds = 10;
  Timer? _sosTimer;
  final Telephony telephony = Telephony.instance;

  // Popup State

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

    // Request permissions after the home page is fully visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissions();
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1, milliseconds: 500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _requestPermissions() async {
    // Wait for the app to be fully rendered
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Request permissions sequentially to avoid overwhelming the OS
    await Permission.location.request();
    if (!mounted) return;
    await Permission.contacts.request();
  }

  void _selectRandomQuote() {
    final random = Random();
    randomQuote = quotes[random.nextInt(quotes.length)];
  }

  @override
  void dispose() {
    _sosTimer?.cancel();
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
                              child: BlocBuilder<AuthCubit, AuthState>(
                                builder: (context, state) {
                                  String message = "\"$randomQuote\"";
                                  if (state is Authenticated) {
                                    final user = state.user;
                                    if (user.dob != null) {
                                      final now = DateTime.now();
                                      final isBirthday =
                                          user.dob!.day == now.day &&
                                          user.dob!.month == now.month;

                                      if (isBirthday) {
                                        final userName = user.name ?? "User";
                                        message =
                                            "Happy Birthday $userName, may your day goes safe with us";
                                      }
                                    }
                                  }

                                  return Text(
                                    message,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.pinkAccent,
                                      fontStyle: FontStyle.italic,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: GestureDetector(
                              onTap: _handleEmergencyTap,
                              child: GestureDetector(
                                onTap: _handleEmergencyTap,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 150,
                                      height: 150,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _isSOSActive
                                            ? Colors.white
                                            : const Color(0xFFFF5252),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _isSOSActive
                                                ? Colors.redAccent.withOpacity(
                                                    0.5,
                                                  )
                                                : const Color(
                                                    0xFFFF5252,
                                                  ).withOpacity(0.4),
                                            blurRadius: _isSOSActive ? 30 : 20,
                                            spreadRadius: _isSOSActive ? 10 : 4,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      alignment: Alignment.center,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          if (_isSOSActive) ...[
                                            Text(
                                              "$_countdownSeconds",
                                              style: const TextStyle(
                                                color: Colors.red,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 60,
                                              ),
                                            ),
                                            const Text(
                                              "STOP",
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                letterSpacing: 1.5,
                                              ),
                                            ),
                                          ] else ...[
                                            const Icon(
                                              Icons.sos_rounded,
                                              color: Colors.white,
                                              size: 56,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "EMERGENCY",
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.9,
                                                ),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (_isSOSActive)
                                      SizedBox(
                                        width: 150,
                                        height: 150,
                                        child: CircularProgressIndicator(
                                          value: _countdownSeconds / 10,
                                          strokeWidth: 8,
                                          color: Colors.red,
                                          backgroundColor: Colors.red.shade100,
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
                          const SizedBox(height: 30),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "More Features",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                _buildListFeatureButton(
                                  Icons.spa_outlined,
                                  "Antistress",
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const WellnessPage(),
                                    ),
                                  ),
                                ),
                                _buildListFeatureButton(
                                  Icons.map_outlined,
                                  "Nearby Places",
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const NearbyPlacesPage(),
                                    ),
                                  ),
                                ),
                                _buildListFeatureButton(
                                  Icons.gavel_outlined,
                                  "Legal Rights",
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const LegalRightsPage(),
                                    ),
                                  ),
                                ),
                                _buildListFeatureButton(
                                  Icons.share_location_outlined,
                                  "Share Location",
                                  () async {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    final contact = prefs.getString(
                                      'emergency_contact',
                                    );
                                    if (contact != null && contact.isNotEmpty) {
                                      SafetyService()
                                          .startLocationSharingSession([
                                            contact,
                                          ]);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Live location sharing started (1 hour)',
                                            ),
                                          ),
                                        );
                                      }
                                    } else {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please set emergency contact first',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                                _buildListFeatureButton(
                                  Icons.call_outlined,
                                  "Fake Call",
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const FakeCallPage(),
                                    ),
                                  ),
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

  Future<void> _handleEmergencyTap() async {
    // Request permissions only when user explicitly taps SOS
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.contacts,
      Permission.sms,
      Permission.phone,
    ].request();

    if (statuses[Permission.sms]?.isDenied == true ||
        statuses[Permission.phone]?.isDenied == true ||
        statuses[Permission.location]?.isDenied == true) {
      // Show rationale
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Permissions needed for SOS!")),
        );
      }
      return;
    }

    if (_isSOSActive) {
      // CANCEL SOS
      _stopSOSSequence();
    } else {
      // START SOS SEQUENCE
      _startSOSSequence();
    }
  }

  void _startSOSSequence() {
    // 1. Play Siren immediately
    SafetyService().startSiren();

    setState(() {
      _isSOSActive = true;
      _countdownSeconds = 10;
    });

    // 2. Start Countdown
    _sosTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        setState(() {
          _countdownSeconds--;
        });
      } else {
        // Countdown finished
        _sosTimer?.cancel();
        _executeEmergencyProtocol();
      }
    });
  }

  void _stopSOSSequence() {
    _sosTimer?.cancel();
    SafetyService().stopSiren();
    setState(() {
      _isSOSActive = false;
      _countdownSeconds = 10;
    });
  }

  Future<void> _executeEmergencyProtocol() async {
    // 1. Stop Siren
    await SafetyService().stopSiren();
    setState(() {
      _isSOSActive = false;
      _countdownSeconds = 10;
    });

    // 2. Trigger Actual Emergency (SMS + Call)
    await _triggerEmergency();
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

  Widget _buildListFeatureButton(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: Colors.pinkAccent),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
