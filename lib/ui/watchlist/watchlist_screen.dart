// lib/ui/watchlist/watchlist_screen.dart

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/database/watch_provider.dart';
import '../../data/models/watch_item.dart';
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

  final goldGradient = const LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WatchProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── 🆕 FIXED: USES NATIVE MATERIAL ROUTE FOR FLAWLESS HERO & SWIPE-BACK ──
  void _navigateToDetail(BuildContext context, int itemId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(itemId: itemId)),
    );
  }

  void _pickRandomShow(BuildContext context) {
    final provider = context.read<WatchProvider>();
    final plannedItems = provider.planned;

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
      barrierDismissible: false,
      builder: (context) => _RouletteDialog(item: randomItem),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF5F5F5);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
          centerTitle: false,
          title: const CustomHeader(title: 'My Library', subtitle: 'Track your cinema journey'),

          actions: [
            if (_tabController.index == 2)
              IconButton(
                icon: const Icon(Icons.casino_rounded, color: Color(0xFFFFD700), size: 28),
                onPressed: () => _pickRandomShow(context),
              ),
            const SizedBox(width: 8),
          ],

          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: Column(
              children: [
                Container(
                  height: 44,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      gradient: goldGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: 'Watched'),
                      Tab(text: 'Watching'),
                      Tab(text: 'Planned'),
                    ],
                  ),
                ),

                Container(
                  height: 56,
                  padding: const EdgeInsets.only(top: 10, bottom: 6),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedCategory = category);
                          },
                          selectedColor: const Color(0xFFFFD700),
                          backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          showCheckmark: false,
                          labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.grey),
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
            _WatchListTab(status: WatchStatus.watched, selectedCategory: _selectedCategory, onNavigate: _navigateToDetail),
            _WatchListTab(status: WatchStatus.watching, selectedCategory: _selectedCategory, onNavigate: _navigateToDetail),
            _WatchListTab(status: WatchStatus.planned, selectedCategory: _selectedCategory, onNavigate: _navigateToDetail),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 80.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: goldGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))
              ],
            ),
            child: FloatingActionButton(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditScreen()));
                if (context.mounted) context.read<WatchProvider>().loadAll();
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              highlightElevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.add_rounded, color: Colors.black, size: 32),
            ),
          ),
        ),
      ),
    );
  }
}

class _WatchListTab extends StatelessWidget {
  final String status;
  final String selectedCategory;
  final Function(BuildContext, int) onNavigate;

  const _WatchListTab({required this.status, required this.selectedCategory, required this.onNavigate});

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_filter_rounded, size: 80, color: isDark ? Colors.white10 : Colors.black12),
            const SizedBox(height: 16),
            Text('No $selectedCategory items here.', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.58,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () => onNavigate(context, item.id!),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                // ── 🆕 FLAWLESS HERO TAG ──
                child: Hero(
                  tag: 'hero_poster_${item.tmdbId ?? item.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                      child: item.posterPath != null && item.posterPath!.isNotEmpty
                          ? (item.posterPath!.startsWith('http')
                          ? CachedNetworkImage(imageUrl: item.posterPath!, fit: BoxFit.cover)
                          : Image.file(File(item.posterPath!), fit: BoxFit.cover))
                          : const Center(child: Icon(Icons.movie_rounded, color: Colors.white24)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(
                item.category,
                style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      },
    );
  }
}

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
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isSpinning = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141414) : Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 5
                )
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child: _isSpinning ? _buildSpinningState() : _buildResultState(context),
            ),
          ),

          Positioned(
            top: 12,
            right: 12,
            child: IconButton(
              icon: Icon(
                  Icons.close_rounded,
                  color: isDark ? Colors.white38 : Colors.black26,
                  size: 26
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpinningState() {
    return Column(
      key: const ValueKey('spinning'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 2 * pi * 5),
          duration: const Duration(seconds: 2),
          builder: (context, double value, child) => Transform.rotate(
            angle: value,
            child: const Icon(Icons.casino_rounded, color: Color(0xFFFFD700), size: 100),
          ),
        ),
        const SizedBox(height: 30),
        const Text(
            'DECIDING YOUR FATE...',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.grey)
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildResultState(BuildContext context) {
    return Column(
      key: const ValueKey('result'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
            'DESTINY CALLS',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 3, color: Color(0xFFFFD700))
        ),
        const SizedBox(height: 20),
        Hero(
          tag: 'hero_poster_${widget.item.tmdbId ?? widget.item.id}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 250,
              decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
                  ]
              ),
              child: widget.item.posterPath != null && widget.item.posterPath!.startsWith('http')
                  ? CachedNetworkImage(imageUrl: widget.item.posterPath!, fit: BoxFit.cover)
                  : Image.file(File(widget.item.posterPath!), fit: BoxFit.cover),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
            widget.item.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, height: 1.1)
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16)
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(itemId: widget.item.id!)));
            },
            child: const Text(
                'WATCH NOW',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black)
            ),
          ),
        ),
      ],
    );
  }
}