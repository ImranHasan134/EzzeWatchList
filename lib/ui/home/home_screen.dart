// lib/ui/home/home_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/database/watch_provider.dart';
import '../../data/models/watch_item.dart';
import '../../widgets/poster_card.dart';
import '../add_edit/add_edit_screen.dart';
import '../detail/detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
          title: Row(
            children: [
              Container(
                width: 3,
                height: 22,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EzzeWatchList',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      letterSpacing: 0.3,
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ).createShader(bounds),
                    child: const Text(
                      'Your Personal Watchlist',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // 🆕 Removed Search Action from here
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Container(
              color: isDark ? const Color(0xFF141414) : Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.07)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
                  labelColor: const Color(0xFF1A1A1A),
                  unselectedLabelColor: isDark ? Colors.white54 : Colors.black45,
                  tabs: const [
                    Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_circle_rounded, size: 13), SizedBox(width: 4), Text('Watched')])),
                    Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.play_circle_rounded, size: 13), SizedBox(width: 4), Text('Watching')])),
                    Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.bookmark_rounded, size: 13), SizedBox(width: 4), Text('Planned')])),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _WatchListTab(status: WatchStatus.watched),
            _WatchListTab(status: WatchStatus.watching),
            _WatchListTab(status: WatchStatus.planned),
          ],
        ),
      ),
    );
  }
}

// ── Per-tab grid ──────────────────────────────────────────────────────────────

class _WatchListTab extends StatelessWidget {
  final String status;
  const _WatchListTab({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<WatchProvider>();

    final List<WatchItem> items = switch (status) {
      WatchStatus.watched  => provider.watched,
      WatchStatus.watching => provider.watching,
      _                    => provider.planned,
    };

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [const Color(0xFFFFD700).withOpacity(0.15), const Color(0xFFFFA500).withOpacity(0.08)]),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3), width: 1.5),
              ),
              child: const Icon(Icons.movie_creation_outlined, size: 34, color: Color(0xFFFFD700)),
            ),
            const SizedBox(height: 16),
            Text('Nothing here yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF444444))),
            const SizedBox(height: 5),
            Text('Tap + to add something', style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38)),
          ],
        ),
      );
    }

    return CustomScrollView(
      // 🆕 Removed the invalid padding line from here
      slivers: [
        // Shuffle Banner explicitly injected at the top of the Planned tab
        if (status == WatchStatus.planned && items.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              child: _buildShuffleBanner(context, items),
            ),
          ),

        // 🆕 The Grid of Posters wrapped in a SliverPadding
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.55,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final item = items[index];
                return PosterCard(
                  item: item,
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(itemId: item.id!)));
                    if (context.mounted) context.read<WatchProvider>().loadAll();
                  },
                );
              },
              childCount: items.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShuffleBanner(BuildContext context, List<WatchItem> plannedItems) {
    return InkWell(
      onTap: () {
        final randomIndex = Random().nextInt(plannedItems.length);
        final randomItem = plannedItems[randomIndex];
        Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(itemId: randomItem.id!)));
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shuffle, size: 28, color: Colors.black87),
            SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shuffle Planned List', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                Text('Tap to pick a random title', style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}