// lib/ui/main_scaffold.dart

import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'search/search_screen.dart';
import 'profile/profile_screen.dart';
import 'add_edit/add_edit_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 1) {
      // Launch Add Screen as a modal
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddEditScreen()),
      );
    } else {
      // Switch tabs
      setState(() {
        _selectedIndex = index > 1 ? index - 1 : index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int navIndex = _selectedIndex >= 1 ? _selectedIndex + 1 : _selectedIndex;

    // 🆕 PopScope handles the modern back-swipe behavior
    return PopScope(
      // Only allow the app to close if we are on the Home screen (index 0)
      canPop: _selectedIndex == 0,
      onPopInvoked: (bool didPop) {
        // If it successfully popped (exited the app), do nothing
        if (didPop) return;

        // If it was blocked from popping, send the user back to the Home screen
        setState(() {
          _selectedIndex = 0;
        });
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: navIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
          indicatorColor: const Color(0xFFFFD700).withOpacity(0.3),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: Color(0xFFFFD700)),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.add_circle_outline, size: 28),
              selectedIcon: Icon(Icons.add_circle, color: Color(0xFFFFD700), size: 28),
              label: 'Add',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search, color: Color(0xFFFFD700)),
              label: 'Search',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: Color(0xFFFFD700)),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}