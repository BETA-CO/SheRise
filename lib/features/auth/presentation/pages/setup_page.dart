import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sherise/core/services/localization_service.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sherise/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sherise/features/home/presentation/pages/MainPage.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:permission_handler/permission_handler.dart';

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

  // Profile Picture State
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadDefaults();
    _refreshDownloadStatus();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
  }

  final Set<String> _downloadedLanguages = {};
  final Map<String, bool> _isDownloadingMap = {};

  Future<void> _refreshDownloadStatus() async {
    final service = LocalizationService();
    // Codes excluding 'en'
    final codes = ['hi', 'mr', 'te', 'bn', 'pa'];
    final downloaded = <String>{};
    for (var code in codes) {
      if (await service.isLanguageDownloaded(code)) {
        downloaded.add(code);
      }
    }
    if (mounted) {
      setState(() {
        _downloadedLanguages.clear();
        _downloadedLanguages.addAll(downloaded);
      });
    }
  }

  Future<void> _loadDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _callEnabled = prefs.getBool('emergency_call_enabled') ?? true;

        final contact = prefs.getString('emergency_contact');
        if (contact != null) {
          _phoneController.text = contact;
        }
      });
      // Load existing profile pic if needed, usually passed from AuthCubit but local state for setup is fine
      // If we wanted to show existing, we'd grab it from cubit.
      // _profileImage = File(context.read<AuthCubit>().currentUser?.profilePicPath ?? "");
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
      _saveProfilePic(image.path);
    }
  }

  Future<void> _saveProfilePic(String path) async {
    final user = context.read<AuthCubit>().currentUser;
    if (user != null) {
      // We need to keep existing data, just update the profile pic
      await context.read<AuthCubit>().saveUserDetails(
        name: user.name ?? "",
        surname: user.surname ?? "",
        dob: user.dob ?? DateTime.now(),
        profilePicPath: path,
      );
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

  Future<void> _pickContact() async {
    try {
      final permissionStatus = await Permission.contacts.request();
      if (permissionStatus.isGranted) {
        final FlutterNativeContactPicker contactPicker =
            FlutterNativeContactPicker();
        final contact = await contactPicker.selectContact();

        if (contact != null &&
            contact.phoneNumbers != null &&
            contact.phoneNumbers!.isNotEmpty) {
          String cleanNumber = contact.phoneNumbers!.first.replaceAll(
            RegExp(r'[^\d+]'),
            '',
          );

          if (cleanNumber.startsWith('+91') && cleanNumber.length == 13) {
            cleanNumber = cleanNumber.substring(3);
          }

          if (cleanNumber.length >= 10) {
            setState(() {
              _phoneController.text = cleanNumber.substring(
                cleanNumber.length - 10,
              );
            });
            await _saveEmergencyContact(_phoneController.text);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invalid contact number format'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contacts permission required'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error picking contact: $e");
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
    final phoneText = _phoneController.text.trim();
    if (phoneText.isEmpty ||
        phoneText.length != 10 ||
        !RegExp(r'^[0-9]+$').hasMatch(phoneText)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit emergency number.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (mounted) {
      // 1. Mark setup as complete in backend/repo
      await context.read<AuthCubit>().completeSetup();

      // 2. Force navigation to MainPage
      // Using pushAndRemoveUntil ensures we reset the stack and don't go back to setup
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainPage()),
          (route) => false,
        );
      }
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
              colors: [
                Color.fromARGB(255, 234, 245, 255),
                Color(0xFFF5FAFF),
                Colors.white,
              ],
              stops: [0.40, 0.60, 1.0],
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
                    'welcome_title'.tr(),
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
                          // Profile Picture Section
                          const SizedBox(height: 20),
                          Center(
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 60,
                                    backgroundColor: Colors.grey[200],
                                    backgroundImage: _profileImage != null
                                        ? FileImage(_profileImage!)
                                        : null,
                                    child: _profileImage == null
                                        ? Icon(
                                            Icons.person,
                                            size: 60,
                                            color: Colors.grey[400],
                                          )
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF2FCF9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Color(0xFF00695C),
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: Text(
                              "set_profile_pic".tr(),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // AI Support Info
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome,
                                      color: Color(0xFF00695C),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'ai_support_title'.tr(),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF00695C),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'ai_support_desc'.tr(),
                                  style: const TextStyle(
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

                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                            child: Text(
                              "restart_warning".tr(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                          _buildSectionTitle('emergency_contact'.tr()),
                          const SizedBox(height: 10),
                          if (_phoneController.text.isEmpty) ...[
                            // Manual Entry Section
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
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                ),
                                onChanged: (val) {
                                  _saveEmergencyContact(val);
                                  if (val.length == 10) {
                                    setState(() {});
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Contact Picker Section
                            InkWell(
                              onTap: _pickContact,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.contacts_rounded,
                                      color: Colors.black,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'select_from_contacts'.tr().isEmpty
                                          ? "Select from Contacts"
                                          : 'select_from_contacts'.tr(),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ] else ...[
                            // Display Selected Contact
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
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
                                border: Border.all(
                                  color: const Color(0xFF00695C).withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00695C).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.phone,
                                      color: Color(0xFF00695C),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Emergency Contact',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          _phoneController.text,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _phoneController.clear();
                                      });
                                      _saveEmergencyContact("");
                                    },
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

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
                              activeThumbColor: Color(0xFF00695C),
                            ),
                          ),

                          const SizedBox(height: 24),

                          const SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _finishSetup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color.fromARGB(
                                  255,
                                  177,
                                  217,
                                  255,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 5,
                              ),
                              child: Text(
                                'finish_setup'.tr(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
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
    if (locale.languageCode == 'en') {
      return _buildEnglishOption(context, name);
    }

    final isSelected = context.locale == locale;
    final isDownloaded = _downloadedLanguages.contains(locale.languageCode);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _handleLanguageTap(locale, isDownloaded),
              child: Row(
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected ? Colors.pinkAccent : Colors.black87,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.check_circle,
                      color: Colors.pinkAccent,
                      size: 16,
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (isDownloaded)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              tooltip: 'Delete Language',
              onPressed: () => _confirmDeleteLanguage(locale),
            )
          else
            _isDownloadingMap[locale.languageCode] == true
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(
                      Icons.download_rounded,
                      color: Colors.blueAccent,
                    ),
                    tooltip: 'Download Language',
                    onPressed: () => _makePermanent(locale),
                  ),
        ],
      ),
    );
  }

  Widget _buildEnglishOption(BuildContext context, String name) {
    final isSelected = context.locale.languageCode == 'en';
    return InkWell(
      onTap: () => _changeLanguage(const Locale('en')),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.pinkAccent : Colors.black87,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.check_circle,
                color: Colors.pinkAccent,
                size: 16,
              ),
            ],
            const Spacer(),
            const Icon(Icons.check, color: Colors.green, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _changeLanguage(Locale locale) async {
    if (!mounted) return;

    // If same locale, try to force reload by switching
    if (context.locale == locale && locale.languageCode != 'en') {
      await context.setLocale(const Locale('en'));
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 50));
    }

    await context.setLocale(locale);
    if (mounted) setState(() {});
    _closeDropdown();
  }

  Future<void> _handleLanguageTap(Locale locale, bool isPersistent) async {
    if (isPersistent || locale.languageCode == 'en') {
      await _changeLanguage(locale);
      return;
    }

    try {
      setState(() {
        _isDownloadingMap[locale.languageCode] = true;
      });

      await LocalizationService().downloadToTemp(locale.languageCode);
      await context.setLocale(locale);

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Download the language to use it offline"),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingMap[locale.languageCode] = false;
        });
      }
    }
  }

  Future<void> _makePermanent(Locale locale) async {
    try {
      setState(() {
        _isDownloadingMap[locale.languageCode] = true;
      });

      await LocalizationService().makePermanent(locale.languageCode);
      await _refreshDownloadStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${_getLanguageName(locale)} is now available offline",
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Download failed. Check internet.")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingMap[locale.languageCode] = false;
        });
      }
    }
  }

  Future<void> _confirmDeleteLanguage(Locale locale) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Language"),
        content: Text(
          "Are you sure you want to delete ${_getLanguageName(locale)}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      if (context.locale == locale) {
        await context.setLocale(const Locale('en'));
      }
      await LocalizationService().deleteLocalLanguage(locale.languageCode);
      await _refreshDownloadStatus();
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
