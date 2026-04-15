// lib/ui/watchlist/watchlist_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/database/watch_provider.dart';
import '../../data/models/watch_item.dart';
import '../../widgets/poster_card.dart';
import '../add_edit/add_edit_screen.dart';
import '../detail/detail_screen.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 🆕 The active category filter
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Movie', 'Web Series', 'Anime Movie', 'Anime Series'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WatchProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF5F5F5),
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
          title: const Text('My Watchlist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100), // Height for Tabs + Filter Chips
            child: Column(
              children: [
                // ── TABS (Watched / Watching / Planned) ──
                Container(
                  height: 42,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                    labelColor: const Color(0xFF1A1A1A),
                    unselectedLabelColor: isDark ? Colors.white54 : Colors.black45,
                    tabs: const [
                      Tab(text: 'Watched'),
                      Tab(text: 'Watching'),
                      Tab(text: 'Planned'),
                    ],
                  ),
                ),

                // ── 🆕 CATEGORY FILTER CHIPS ──
                Container(
                  height: 58,
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedCategory = category);
                          },
                          selectedColor: const Color(0xFFFFD700).withOpacity(0.2),
                          checkmarkColor: const Color(0xFFFFD700),
                          backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _WatchListTab(status: WatchStatus.watched, selectedCategory: _selectedCategory),
            _WatchListTab(status: WatchStatus.watching, selectedCategory: _selectedCategory),
            _WatchListTab(status: WatchStatus.planned, selectedCategory: _selectedCategory),
          ],
        ),

        // ── 🆕 FLOATING ACTION BUTTON (+) ──
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditScreen()));
            if (context.mounted) context.read<WatchProvider>().loadAll();
          },
          backgroundColor: const Color(0xFFFFD700),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.add_rounded, color: Color(0xFF1A1A1A), size: 30),
        ),
      ),
    );
  }
}

class _WatchListTab extends StatelessWidget {
  final String status;
  final String selectedCategory; // 🆕 Added category filter

  const _WatchListTab({required this.status, required this.selectedCategory});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<WatchProvider>();

    List<WatchItem> items = switch (status) {
      WatchStatus.watched  => provider.watched,
      WatchStatus.watching => provider.watching,
      _                    => provider.planned,
    };

    // ── 🆕 FILTER LOGIC ──
    if (selectedCategory != 'All') {
      items = items.where((item) => item.category == selectedCategory).toList();
    }

    if (items.isEmpty) {
      return Center(
        child: Text('No $selectedCategory items here.', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.55,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return PosterCard(
          item: item,
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(itemId: item.id!)));
            if (context.mounted) context.read<WatchProvider>().loadAll();
          },
        );
      },
    );
  }
}