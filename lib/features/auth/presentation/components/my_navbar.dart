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
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Container(
              width: constraints.maxWidth,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 200, 200),
                borderRadius: BorderRadius.circular(55),
              ),
              padding: const EdgeInsets.all(3),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 214, 214),
                  borderRadius: BorderRadius.circular(45),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 6),
                  child: GNav(
                    haptic: true,
                    backgroundColor: Colors.transparent,
                    color: Colors.black,
                    activeColor: Colors.black,
                    tabBackgroundColor:
                        const Color.fromARGB(119, 255, 255, 255),
                    gap: 6,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    selectedIndex: selectedIndex,
                    tabs: const [
                      GButton(icon: Icons.home, text: 'Home'),
                      GButton(icon: Icons.video_library, text: 'Video'),
                      GButton(icon: Icons.person, text: 'Profile'),
                      GButton(icon: Icons.settings, text: 'Settings'),
                    ],
                    onTabChange: onTabChange,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
