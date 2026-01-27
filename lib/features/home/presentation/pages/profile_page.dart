import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sherise/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:sherise/features/auth/presentation/cubits/auth_states.dart';
import 'package:sherise/features/onboarding/presentation/pages/landing_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadSavedImage();
  }

  Future<void> _loadSavedImage() async {
    final prefs = await SharedPreferences.getInstance();
    // Check both keys to be safe, prioritizing the one used by AuthRepo
    String? imagePath = prefs.getString('user_profile_pic');
    imagePath ??= prefs.getString('profile_image');

    if (imagePath != null && File(imagePath).existsSync()) {
      setState(() => _profileImage = File(imagePath!));
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final dir = await getApplicationDocumentsDirectory();
      final localPath = '${dir.path}/profile_pic.png';
      await File(picked.path).copy(localPath);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image', localPath);

      setState(() {
        _profileImage = File(localPath);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Text(
                      'my_profile'.tr(),
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
                child: BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    if (state is AuthLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is Authenticated) {
                      final user = state.user;
                      // Display Name instead of Email/Phone
                      final surname = user.surname ?? "";
                      final userName = user.name != null
                          ? "${user.name!} $surname".trim()
                          : "User";
                      final userAge = user.age ?? "N/A";
                      final userDob = user.dob != null
                          ? DateFormat('dd MMM yyyy').format(user.dob!)
                          : "N/A";

                      DateTime? creationDate = user.creationTime;
                      String formattedDate = creationDate != null
                          ? DateFormat('MMMM yyyy').format(creationDate)
                          : "N/A";

                      return ScrollConfiguration(
                        behavior: const _BouncyScrollBehavior(),
                        child: _buildProfileContent(
                          context,
                          userName,
                          userAge,
                          userDob,
                          formattedDate,
                          user.profilePicPath,
                        ),
                      );
                    } else if (state is Unauthenticated) {
                      return Center(child: Text('logged_out'.tr()));
                    } else {
                      return Center(child: Text('no_profile_data'.tr()));
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    String name,
    String age,
    String dob,
    String memberSince,
    String? profilePicPath,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.pink.shade100,
                backgroundImage:
                    (profilePicPath != null &&
                        File(profilePicPath).existsSync())
                    ? FileImage(File(profilePicPath))
                    : (_profileImage != null
                          ? FileImage(_profileImage!)
                          : const AssetImage('lib/assets/home page logo.png')
                                as ImageProvider),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF8BA7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Text(
            'hello_user'.tr(args: [name]),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 15),
          const Divider(color: Colors.black26),
          const SizedBox(height: 15),
          _buildInfoRow(Icons.cake_outlined, 'label_age'.tr(), age),
          const SizedBox(height: 15),
          _buildInfoRow(Icons.calendar_month_outlined, 'label_dob'.tr(), dob),
          const SizedBox(height: 15),
          _buildInfoRow(
            Icons.calendar_today_outlined,
            'member_since'.tr(),
            memberSince,
          ),
          const SizedBox(height: 15),
          _buildInfoRow(
            Icons.settings_outlined,
            'account_settings'.tr(),
            'manage_preferences'.tr(),
          ),
          const SizedBox(height: 30),
          const Divider(color: Colors.black26),
          const SizedBox(height: 20),
          // Delete Account button removed as per request
          _buildLogout(context),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: Colors.black54, size: 24),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLogout(BuildContext context) {
    return InkWell(
      onTap: () => _showLogoutDialog(context),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.logout, color: Color(0xFFFF0040), size: 24),
            const SizedBox(width: 16),
            Text(
              'logout'.tr(), // 👈
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFFFF0040),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'confirm_logout'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'logout_prompt'.tr(),
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'cancel'.tr(),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8BA7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthCubit>().logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LandingPage()),
                  (route) => false,
                );
              }
            },
            child: Text('logout'.tr()),
          ),
        ],
      ),
    );
  }
}

class _BouncyScrollBehavior extends ScrollBehavior {
  const _BouncyScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}
