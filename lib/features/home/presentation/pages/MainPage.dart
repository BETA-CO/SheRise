import 'package:flutter/material.dart';
import 'package:sherise/features/auth/presentation/components/my_navbar.dart';
import 'package:sherise/features/home/presentation/pages/home_pages.dart';
import 'package:sherise/features/home/presentation/pages/videos_page.dart';
import 'package:sherise/features/home/presentation/pages/profile_page.dart';
import 'package:sherise/features/chatbot/presentation/pages/chatbot_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  Key _navBarKey = UniqueKey();
  late PageController _pageController;

  List<Widget> get _pages => const [
    HomePage(),
    VideosPage(),
    ProfilePage(),
    ChatBotPage(),
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
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ChatBotPage()),
      ).then((_) {
        // Force update to reset navbar state if it got stuck
        setState(() {
          _navBarKey = UniqueKey();
        });
      });
      return;
    }
    // Jump instantly (no slide animation)
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: false,
      body: Container(
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
        child: PageView(
          controller: _pageController,
          allowImplicitScrolling:
              true, // Smooth swipe by pre-rendering adjacent tabs
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: _onPageChanged,
          children: _pages,
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.transparent,
        child: MyNavbar(
          key: _navBarKey,
          selectedIndex: _selectedIndex,
          onTabChange: _onNavBarTap,
        ),
      ),
    );
  }
}
