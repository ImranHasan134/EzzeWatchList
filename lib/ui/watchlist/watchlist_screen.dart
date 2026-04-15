// lib/ui/watchlist/watchlist_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/database/watch_provider.dart';
import '../../data/models/watch_item.dart';
import '../../widgets/poster_card.dart';
import '../add_edit/add_edit_screen.dart';
import '../detail/detail_screen.dart';
import '../../widgets/custom_header.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Movie', 'Web Series', 'Anime Movie', 'Anime Series'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // ── 🆕 LISTENER: Tells the app to rebuild when you swipe tabs so the dice hides/shows
    _tabController.addListener(() {
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WatchProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _pickRandomShow(BuildContext context) {
    final provider = context.read<WatchProvider>();
    final plannedItems = provider.planned;

    // ── FILTER CHECK: Only shuffle from current category if a filter is active
    final filterItems = _selectedCategory == 'All'
        ? plannedItems
        : plannedItems.where((i) => i.category == _selectedCategory).toList();

    if (filterItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Your Planned list for $_selectedCategory is empty!'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final randomItem = filterItems[Random().nextInt(filterItems.length)];

    showDialog(
      context: context,
      barrierDismissible: false, // Prevents closing while it's spinning!
      builder: (context) => _RouletteDialog(item: randomItem),
    );
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
          centerTitle: false, // 🆕 Ensures it stays aligned to the left
          title: const CustomHeader(title: 'My Watchlist', subtitle: 'Track your shows'), // 🆕 New Header!

          actions: [
            // ── 🆕 CONDITIONAL DICE: Only shows on the Planned tab (Index 2)
            if (_tabController.index == 2)
              IconButton(
                icon: const Icon(Icons.casino, color: Color(0xFFFFD700), size: 28),
                tooltip: 'Pick Random Show',
                onPressed: () => _pickRandomShow(context),
              ),
            const SizedBox(width: 8),
          ],

          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: Column(
              children: [
                // TABS
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

                // CATEGORY CHIPS
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
  final String selectedCategory;

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

// ── 🆕 THE ANIMATED DIALOG ──
class _RouletteDialog extends StatefulWidget {
  final WatchItem item;

  const _RouletteDialog({required this.item});

  @override
  State<_RouletteDialog> createState() => _RouletteDialogState();
}

class _RouletteDialogState extends State<_RouletteDialog> {
  bool _isSpinning = true;

  @override
  void initState() {
    super.initState();
    // Tells the app to wait 2 seconds, then swap from the spinning dice to the poster
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isSpinning = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141414) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5), width: 1),
          boxShadow: [
            BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.15), blurRadius: 24, spreadRadius: 2)
          ],
        ),
        // ── AnimatedSwitcher handles the smooth crossfade ──
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child));
          },
          child: _isSpinning ? _buildSpinningState() : _buildResultState(context),
        ),
      ),
    );
  }

  // ── THE SPINNING DICE VIEW ──
  Widget _buildSpinningState() {
    return Column(
      key: const ValueKey('spinning'), // Keys are required for AnimatedSwitcher
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 30),
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 2 * pi * 4), // Spins 4 full times
          duration: const Duration(seconds: 2),
          builder: (context, double value, child) {
            return Transform.rotate(
              angle: value,
              child: const Icon(Icons.casino, color: Color(0xFFFFD700), size: 80),
            );
          },
        ),
        const SizedBox(height: 30),
        const Text('Consulting the Watch Gods...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── THE RESULT VIEW ──
  Widget _buildResultState(BuildContext context) {
    return Column(
      key: const ValueKey('result'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: Color(0xFFFFD700), size: 40),
        const SizedBox(height: 12),
        const Text('You should watch:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: widget.item.posterPath ?? '',
            height: 220,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => Container(height: 220, color: Colors.grey.shade900, child: const Icon(Icons.movie, size: 50)),
          ),
        ),
        const SizedBox(height: 16),
        Text(widget.item.title, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, height: 1.1)),
        const SizedBox(height: 8),
        Text(widget.item.category, style: const TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(itemId: widget.item.id!)));
            },
            child: const Text('View Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}