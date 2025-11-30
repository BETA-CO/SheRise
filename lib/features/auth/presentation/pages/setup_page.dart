import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:sherise/features/auth/presentation/pages/pin_lock_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sherise/features/auth/presentation/cubits/auth_cubit.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> with TickerProviderStateMixin {
  bool _expanded = false;
  bool _callEnabled = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _phoneController = TextEditingController();
  final FlutterNativeContactPicker _contactPicker =
      FlutterNativeContactPicker();
  bool _appLockEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadDefaults();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _loadDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _callEnabled = prefs.getBool('emergency_call_enabled') ?? true;
        _appLockEnabled = prefs.getBool('app_lock_enabled') ?? false;
        final contact = prefs.getString('emergency_contact');
        if (contact != null) {
          _phoneController.text = contact;
        }
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveEmergencyContact(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('emergency_contact', value);
  }

  Future<void> _toggleCallEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('emergency_call_enabled', value);
    setState(() {
      _callEnabled = value;
    });
  }

  Future<void> _toggleAppLock(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      // Check if PIN is set
      final pin = prefs.getString('app_pin');
      if (pin == null) {
        if (!mounted) return; // Fix async gap
        // Navigate to PIN setup
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => const PinLockScreen(isSetup: true),
          ),
        );

        if (result == true) {
          await prefs.setBool('app_lock_enabled', true);
          if (mounted) {
            setState(() {
              _appLockEnabled = true;
            });
          }
        }
      } else {
        await prefs.setBool('app_lock_enabled', true);
        if (mounted) {
          setState(() {
            _appLockEnabled = true;
          });
        }
      }
    } else {
      await prefs.setBool('app_lock_enabled', false);
      if (mounted) {
        setState(() {
          _appLockEnabled = false;
        });
      }
    }
  }

  Future<void> _pickContact() async {
    try {
      final contact = await _contactPicker.selectContact();
      if (contact != null &&
          contact.phoneNumbers != null &&
          contact.phoneNumbers!.isNotEmpty) {
        String number = contact.phoneNumbers!.first;
        if (mounted) {
          setState(() {
            _phoneController.text = number;
          });
        }
        _saveEmergencyContact(number);
      }
    } catch (e) {
      debugPrint('Contact picker error: $e');
    }
  }

  void _toggleDropdown() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _fadeController.forward();
      } else {
        _fadeController.reverse();
      }
    });
  }

  void _closeDropdown() {
    if (_expanded) {
      setState(() {
        _expanded = false;
        _fadeController.reverse();
      });
    }
  }

  Future<void> _finishSetup() async {
    // Mark setup as complete in Cubit, which triggers main.dart to show MainPage
    if (mounted) {
      // We don't need to await this, it's a synchronous state emission
      // But we should ensure the widget is still mounted
      context.read<AuthCubit>().completeSetup();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeDropdown,
        child: Container(
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
                    vertical: 20,
                  ),
                  child: Text(
                    'Welcome to SheRise',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 28,
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // AI Support Info
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.pinkAccent.withValues(
                                    alpha: 0.1,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.pinkAccent.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome,
                                      color: Colors.pinkAccent,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'AI Support Available',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.pinkAccent,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'SheRise comes with an intelligent AI assistant to help you with safety tips, legal advice, and emotional support. You can access it anytime from the home screen.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          _buildSectionTitle('language'.tr()),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: _toggleDropdown,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _getLanguageName(context.locale),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  AnimatedRotation(
                                    turns: _expanded ? 0.5 : 0,
                                    duration: const Duration(milliseconds: 200),
                                    child: const Icon(Icons.expand_more),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizeTransition(
                            sizeFactor: _fadeAnimation,
                            axisAlignment: -1.0,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      _buildLangOption(
                                        context,
                                        'English',
                                        const Locale('en'),
                                      ),
                                      _dividerLine(),
                                      _buildLangOption(
                                        context,
                                        'हिन्दी',
                                        const Locale('hi'),
                                      ),
                                      _dividerLine(),
                                      _buildLangOption(
                                        context,
                                        'मराठी',
                                        const Locale('mr'),
                                      ),
                                      _dividerLine(),
                                      _buildLangOption(
                                        context,
                                        'తెలుగు',
                                        const Locale('te'),
                                      ),
                                      _dividerLine(),
                                      _buildLangOption(
                                        context,
                                        'বাংলা',
                                        const Locale('bn'),
                                      ),
                                      _dividerLine(),
                                      _buildLangOption(
                                        context,
                                        'ਪੰਜਾਬੀ',
                                        const Locale('pa'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                          _buildSectionTitle('emergency_contact'.tr()),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'enter_phone_number'.tr(),
                                prefixIcon: const Icon(
                                  Icons.phone,
                                  color: Colors.black,
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(
                                    Icons.contacts,
                                    color: Colors.black,
                                  ),
                                  onPressed: _pickContact,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                              ),
                              onChanged: _saveEmergencyContact,
                            ),
                          ),

                          const SizedBox(height: 24),
                          _buildSectionTitle('sos_settings'.tr()),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: SwitchListTile(
                              title: Text(
                                'call_after_sos'.tr(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                'auto_call_emergency'.tr(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              value: _callEnabled,
                              onChanged: _toggleCallEnabled,
                              activeThumbImage: null,
                              activeColor: Colors.pinkAccent,
                            ),
                          ),

                          const SizedBox(height: 24),
                          _buildSectionTitle('Security'),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: SwitchListTile(
                              title: const Text(
                                'App Lock',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: const Text(
                                'Require authentication when opening app',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              value: _appLockEnabled,
                              onChanged: _toggleAppLock,
                              activeColor: Colors.pinkAccent,
                            ),
                          ),

                          const SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _finishSetup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pinkAccent,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 5,
                              ),
                              child: const Text(
                                'Finish Setup',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dividerLine() => Divider(
    color: Colors.grey.withValues(alpha: 0.2),
    height: 0,
    thickness: 0.6,
    indent: 12,
    endIndent: 12,
  );

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 2.0, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildLangOption(BuildContext context, String name, Locale locale) {
    final isSelected = context.locale == locale;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        context.setLocale(locale);
        _closeDropdown();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFE5EC) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.pinkAccent : Colors.black87,
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.pinkAccent,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  String _getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'hi':
        return 'हिन्दी';
      case 'mr':
        return 'मराठी';
      case 'te':
        return 'తెలుగు';
      case 'bn':
        return 'বাংলা';
      case 'pa':
        return 'ਪੰਜਾਬੀ';
      default:
        return 'English';
    }
  }
}
