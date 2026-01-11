import 'package:flutter/material.dart';
import 'package:sherise/features/auth/presentation/components/my_navbar.dart';
import 'package:sherise/features/home/presentation/pages/home_pages.dart';
import 'package:sherise/features/home/presentation/pages/videos_page.dart';
import 'package:sherise/features/home/presentation/pages/profile_page.dart';
import 'package:sherise/features/home/presentation/pages/settings_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  late PageController _pageController;

  final List<Widget> _pages = const [
    HomePage(),
    VideosPage(),
    ProfilePage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onNavBarTap(int index) {
    // Jump instantly (no slide animation)
    _pageController.jumpToPage(index);
  }

  // ✅ handle swipe on navbar itself
  void _onHorizontalSwipe(DragEndDetails details) {
    if (details.primaryVelocity == null) return;

    if (details.primaryVelocity! < 0) {
      // Swipe left → go next
      if (_selectedIndex < _pages.length - 1) {
        _pageController.animateToPage(
          _selectedIndex + 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else if (details.primaryVelocity! > 0) {
      // Swipe right → go previous
      if (_selectedIndex > 0) {
        _pageController.animateToPage(
          _selectedIndex - 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF5F7), Colors.white],
          ),
        ),
        child: PageView(
          controller: _pageController,
          allowImplicitScrolling:
              true, // Smooth swipe by pre-rendering adjacent tabs
          physics: const BouncingScrollPhysics(),
          onPageChanged: _onPageChanged,
          children: _pages,
        ),
      ),
      bottomNavigationBar: GestureDetector(
        onHorizontalDragEnd: _onHorizontalSwipe,
        child: Container(
          color: Colors.transparent,
          child: MyNavbar(
            selectedIndex: _selectedIndex,
            onTabChange: _onNavBarTap,
          ),
        ),
      ),
    );
  }
}
