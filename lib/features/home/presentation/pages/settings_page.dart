import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:sherise/features/auth/presentation/pages/pin_lock_screen.dart';
import 'package:sherise/core/services/localization_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  bool _expanded = false;
  bool _callEnabled = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _phoneController = TextEditingController();
  final FlutterNativeContactPicker _contactPicker =
      FlutterNativeContactPicker();
  List<String> _emergencyContacts = [];

  @override
  void initState() {
    super.initState();
    _loadEmergencyContact();
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

  @override
  void dispose() {
    _fadeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadEmergencyContact() async {
    final prefs = await SharedPreferences.getInstance();
    // Load list
    final contacts = prefs.getStringList('emergency_contacts_list') ?? [];
    // Load legacy single contact for migration
    final singleContact = prefs.getString('emergency_contact');

    if (singleContact != null &&
        singleContact.isNotEmpty &&
        !contacts.contains(singleContact)) {
      contacts.add(singleContact);
      await prefs.setStringList('emergency_contacts_list', contacts);
      // Optional: Clear legacy key
      // await prefs.remove('emergency_contact');
    }

    final callEnabled = prefs.getBool('emergency_call_enabled') ?? true;
    final appLockEnabled = prefs.getBool('app_lock_enabled') ?? false;

    if (mounted) {
      setState(() {
        _emergencyContacts = contacts;
        _callEnabled = callEnabled;
        _appLockEnabled = appLockEnabled;
      });
    }
  }

  Future<void> _addEmergencyContact(String number) async {
    // Basic validation/cleaning
    // String cleaned = number.replaceAll(RegExp(r'[^\d+]'), '');
    if (!_emergencyContacts.contains(number)) {
      setState(() {
        _emergencyContacts.add(number);
      });
      await _saveContacts();
    }
  }

  Future<void> _removeEmergencyContact(String number) async {
    setState(() {
      _emergencyContacts.remove(number);
    });
    await _saveContacts();
  }

  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('emergency_contacts_list', _emergencyContacts);
    // Sync primary contact for backward compatibility if needed
    if (_emergencyContacts.isNotEmpty) {
      await prefs.setString('emergency_contact', _emergencyContacts.first);
    } else {
      await prefs.remove('emergency_contact');
    }
  }

  Future<void> _toggleCallEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('emergency_call_enabled', value);
    setState(() {
      _callEnabled = value;
    });
  }

  bool _appLockEnabled = false;

  Future<void> _toggleAppLock(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      // Check if PIN is set
      final pin = prefs.getString('app_pin');
      if (pin == null) {
        // Navigate to PIN setup
        if (!mounted) return;
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
        setState(() {
          _appLockEnabled = true;
        });
      }
    } else {
      await prefs.setBool('app_lock_enabled', false);
      setState(() {
        _appLockEnabled = false;
      });
    }
  }

  Future<void> _changePin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PinLockScreen(isSetup: true),
      ),
    );
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
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Divider(
                              color: Colors.grey.withValues(alpha: 0.25),
                              thickness: 0.7,
                            ),
                          ),
                          _buildSectionTitle('emergency_contact'.tr()),
                          const SizedBox(height: 10),
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
                            ),
                            child: Column(
                              children: [
                                // Add Button
                                InkWell(
                                  onTap: _pickContact,
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF2FCF9),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          color: Color(0xFF00695C),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        "add_contact_btn".tr(),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_emergencyContacts.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  const Divider(height: 1),
                                  const SizedBox(height: 8),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _emergencyContacts.length,
                                    itemBuilder: (context, index) {
                                      final contact = _emergencyContacts[index];
                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: const Icon(
                                          Icons.person_outline,
                                        ),
                                        title: Text(contact),
                                        trailing: IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              _removeEmergencyContact(contact),
                                        ),
                                      );
                                    },
                                  ),
                                ] else
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12.0),
                                    child: Text("no_contacts".tr()),
                                  ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Divider(
                              color: Colors.grey.withValues(alpha: 0.25),
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
                              activeThumbColor: Color(0xFF00695C),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Divider(
                              color: Colors.grey.withValues(alpha: 0.25),
                              thickness: 0.7,
                            ),
                          ),
                          _buildSectionTitle('security_section'.tr()),
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
                            child: Column(
                              children: [
                                SwitchListTile(
                                  title: Text(
                                    'app_lock'.tr(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'app_lock_desc'.tr(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  value: _appLockEnabled,
                                  onChanged: _toggleAppLock,
                                  activeThumbColor: Color(0xFF00695C),
                                ),
                                if (_appLockEnabled) ...[
                                  const Divider(),
                                  ListTile(
                                    title: Text(
                                      'change_pin'.tr(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                    ),
                                    onTap: _changePin,
                                  ),
                                ],
                              ],
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
            // English is always available
            const Icon(Icons.check, color: Colors.green, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _changeLanguage(Locale locale) async {
    if (!mounted) return;
    context.setLocale(locale);
    _closeDropdown();
  }

  Future<void> _handleLanguageTap(Locale locale, bool isPersistent) async {
    // If already persistent, or English, just switch
    if (isPersistent || locale.languageCode == 'en') {
      await _changeLanguage(locale);
      return;
    }

    // Attempt to download to Temp (Session) then switch
    try {
      setState(() {
        _isDownloadingMap[locale.languageCode] = true;
      });

      // Download to cache
      await LocalizationService().downloadToTemp(locale.languageCode);

      // Switch
      await _changeLanguage(locale);
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
        // Switch to English first
        await context.setLocale(const Locale('en'));
      }
      await LocalizationService().deleteLocalLanguage(locale.languageCode);
      await _refreshDownloadStatus();
    }
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
        _addEmergencyContact(number);
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
