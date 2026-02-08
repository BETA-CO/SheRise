import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class MyNavbar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabChange;

  const MyNavbar({
    super.key,
    required this.selectedIndex,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 234, 245, 255),
        boxShadow: [
          BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(.1)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
          child: GNav(
            rippleColor: const Color(0xFF00695C).withOpacity(0.1),
            hoverColor: const Color(0xFF00695C).withOpacity(0.1),
            gap: 8,
            activeColor: const Color(0xFF00695C),
            iconSize: 24,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            duration: const Duration(milliseconds: 400),
            tabBackgroundColor: const Color(0xFFF2FCF9),
            // tabActiveBorder: Border.all(color: Colors.black, width: 0.2),
            color: const Color(0xFF00695C),
            selectedIndex: selectedIndex,
            onTabChange: onTabChange,
            tabs: const [
              GButton(icon: Icons.home, text: 'Home'),
              GButton(icon: Icons.video_library, text: 'Video'),
              GButton(icon: Icons.person, text: 'Profile'),
              GButton(icon: Icons.settings, text: 'Settings'),
            ],
          ),
        ),
      ),
    );
  }
}
