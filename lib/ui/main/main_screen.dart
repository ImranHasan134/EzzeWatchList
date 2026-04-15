// lib/ui/main_screen.dart (or wherever your Bottom Nav is)

import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../explore/explore_screen.dart';
import '../watchlist/watchlist_screen.dart';
import '../profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // The 4 main screens of your app
  final List<Widget> _screens = const [
    HomeScreen(),
    ExploreScreen(),
    WatchlistScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // ── 🆕 PopScope INTERCEPTS THE BACK SWIPE ──
    return PopScope(
      // canPop: true means the app will exit.
      // We ONLY want to exit if the user is on the Home Tab (Index 0).
      canPop: _currentIndex == 0,

      onPopInvoked: (didPop) {
        // If didPop is true, it means the app is already exiting. Do nothing.
        if (didPop) return;

        // If the app didn't exit, it means they are on another tab.
        // Send them back to the Home Tab instead!
        setState(() {
          _currentIndex = 0;
        });
      },
      child: Scaffold(
        // IndexedStack keeps the state of your screens alive when switching tabs
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),

        // ── YOUR BOTTOM NAVIGATION BAR ──
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF141414)
              : Colors.white,
          selectedItemColor: const Color(0xFFFFD700), // Your golden accent
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
            BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Watchlist'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}