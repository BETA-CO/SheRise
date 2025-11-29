import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with TickerProviderStateMixin {
  bool _expanded = false;
  bool _callEnabled = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _phoneController = TextEditingController();
  final FlutterNativeContactPicker _contactPicker =
      FlutterNativeContactPicker();

  @override
  void initState() {
    super.initState();
    _loadEmergencyContact();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadEmergencyContact() async {
    final prefs = await SharedPreferences.getInstance();
    final contact = prefs.getString('emergency_contact');
    final callEnabled = prefs.getBool('emergency_call_enabled') ?? true;
    if (mounted) {
      setState(() {
        if (contact != null) {
          _phoneController.text = contact;
        }
        _callEnabled = callEnabled;
      });
    }
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
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'settings'.tr(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                    color: Colors.black.withOpacity(0.08),
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
                                        color: Colors.black.withOpacity(0.05),
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
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Divider(
                              color: Colors.grey.withOpacity(0.25),
                              thickness: 0.7,
                            ),
                          ),
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
                                  color: Colors.black.withOpacity(0.05),
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
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Divider(
                              color: Colors.grey.withOpacity(0.25),
                              thickness: 0.7,
                            ),
                          ),
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
                                  color: Colors.black.withOpacity(0.05),
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
                              activeColor: Colors.pinkAccent,
                            ),
                          ),
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
    color: Colors.grey.withOpacity(0.2),
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
        _closeDropdown(); // 👈 closes dropdown smoothly after selecting
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

  Future<void> _pickContact() async {
    try {
      final contact = await _contactPicker.selectContact();
      if (contact != null &&
          contact.phoneNumbers != null &&
          contact.phoneNumbers!.isNotEmpty) {
        String number = contact.phoneNumbers!.first;
        // Optional: Clean the number (remove spaces, dashes, etc.)
        // number = number.replaceAll(RegExp(r'[^\d+]'), '');
        setState(() {
          _phoneController.text = number;
        });
        _saveEmergencyContact(number);
      }
    } catch (e) {
      // User cancelled or error
      debugPrint('Contact picker error: $e');
    }
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
