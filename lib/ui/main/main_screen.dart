// lib/ui/main/main_screen.dart

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
  int _currentIndex = 0; // Defaults to Home

  final List<Widget> _screens = const [
    HomeScreen(),       // 0
    ExploreScreen(),    // 1 (Now handles Search AND Explore)
    WatchlistScreen(),  // 2
    ProfileScreen(),    // 3
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = const Color(0xFFFFD700); // Gold
    final inactiveColor = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black12, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: isDark ? const Color(0xFF0E0E0E) : Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: activeColor,
          unselectedItemColor: inactiveColor,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'), // Combined Tab
            BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Watchlist'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}