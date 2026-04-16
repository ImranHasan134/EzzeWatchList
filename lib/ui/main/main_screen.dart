// lib/ui/main_screen.dart

import 'dart:ui';
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

  final List<Widget> _screens = const [
    HomeScreen(),
    ExploreScreen(),
    WatchlistScreen(),
    ProfileScreen(),
  ];

  // ── 🆕 SLIMMER NAVBAR DEFINITIONS ──
  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.grid_view_rounded, 'label': 'Home'},
    {'icon': Icons.compass_calibration_rounded, 'label': 'Discover'},
    {'icon': Icons.movie_filter_rounded, 'label': 'Library'},
    {'icon': Icons.person_2_rounded, 'label': 'Profile'},
  ];

  final goldGradient = const LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvoked: (didPop) {
        if (didPop) return;
        setState(() => _currentIndex = 0);
      },
      child: Scaffold(
        extendBody: true, // Keeps the blur effect overlapping the content
        backgroundColor: isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF5F5F5),

        // ── 🆕 SMOOTH PAGE TRANSITIONS (PRESERVES STATE) ──
        body: Stack(
          children: List.generate(_screens.length, (index) {
            final bool isActive = _currentIndex == index;
            return IgnorePointer(
              ignoring: !isActive, // Prevents tapping on hidden screens
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                opacity: isActive ? 1.0 : 0.0,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  scale: isActive ? 1.0 : 0.96, // Slight zoom effect
                  child: _screens[index],
                ),
              ),
            );
          }),
        ),

        // ── 🆕 SLIM, SLIDING FLOATING DOCK ──
        bottomNavigationBar: SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 16), // Tighter margins
            padding: const EdgeInsets.all(8), // Snug internal padding
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.85) : Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12, width: 1),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_navItems.length, (index) {
                final bool isSelected = _currentIndex == index;

                return GestureDetector(
                  onTap: () => setState(() => _currentIndex = index),
                  behavior: HitTestBehavior.opaque,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // ── FADING GRADIENT BACKGROUND ──
                      // This solves the "snapping" issue by fading the gradient in smoothly
                      Positioned.fill(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: isSelected ? 1.0 : 0.0,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: goldGradient,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),

                      // ── SLIDING CONTENT ──
                      // AnimatedSize physically pushes the other icons away smoothly
                      AnimatedSize(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), // Slimmer padding
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _navItems[index]['icon'],
                                color: isSelected ? Colors.black : Colors.grey,
                                size: 22, // Smaller icon
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 6),
                                Text(
                                  _navItems[index]['label'],
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12, // Smaller text
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}