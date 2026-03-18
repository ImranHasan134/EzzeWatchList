// lib/ui/search/search_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/database/watch_provider.dart';
import '../../data/models/watch_item.dart';
import '../../widgets/poster_card.dart';
import '../detail/detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WatchProvider>().refreshSearch();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WatchProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
    isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF5F5F5);
    final surfaceColor =
    isDark ? const Color(0xFF141414) : Colors.white;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          automaticallyImplyLeading: false, // ✅ back button removed
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: surfaceColor,
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
                    'Search',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF1A1A1A),
                      letterSpacing: 0.3,
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ).createShader(bounds),
                    child: const Text(
                      'Find anything instantly',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Search bar ──────────────────────────────────────────────
            Container(
              color: surfaceColor,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.07)
                      : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.07),
                  ),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: TextStyle(
                    color:
                    isDark ? Colors.white : const Color(0xFF1A1A1A),
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search by title...',
                    hintStyle: TextStyle(
                      color:
                      isDark ? Colors.white38 : Colors.black38,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: const Color(0xFFFFD700),
                      size: 20,
                    ),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        provider.setSearchQuery('');
                      },
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.06),
                          borderRadius:
                          BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: isDark
                              ? Colors.white60
                              : Colors.black45,
                        ),
                      ),
                    )
                        : null,
                    border: InputBorder.none,
                    contentPadding:
                    const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                  ),
                  onChanged: provider.setSearchQuery,
                ),
              ),
            ),

            const SizedBox(height: 4),

            // ── Genre filter ────────────────────────────────────────────
            Padding(
              padding:
              const EdgeInsets.fromLTRB(14, 4, 14, 6),
              child: Text(
                'GENRE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color:
                  isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _GoldFilterChip(
                    label: 'All',
                    selected: provider.filterGenre.isEmpty,
                    isDark: isDark,
                    onTap: () =>
                        provider.setFilterGenre(''),
                  ),
                  ...Genre.all.map((g) => _GoldFilterChip(
                    label: g,
                    selected:
                    provider.filterGenre == g,
                    isDark: isDark,
                    onTap: () => provider
                        .setFilterGenre(
                        provider.filterGenre == g
                            ? ''
                            : g),
                  )),
                ],
              ),
            ),

            // ── Category filter ─────────────────────────────────────────
            Padding(
              padding:
              const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: Text(
                'CATEGORY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color:
                  isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _GoldFilterChip(
                    label: 'All',
                    selected:
                    provider.filterCategory.isEmpty,
                    isDark: isDark,
                    onTap: () =>
                        provider.setFilterCategory(''),
                  ),
                  ...Category.all.map((c) =>
                      _GoldFilterChip(
                        label: c,
                        selected:
                        provider.filterCategory == c,
                        isDark: isDark,
                        onTap: () => provider
                            .setFilterCategory(
                            provider.filterCategory ==
                                c
                                ? ''
                                : c),
                      )),
                ],
              ),
            ),

            // ── Results grid ────────────────────────────────────────────
            Expanded(
              child: provider.searchResults.isEmpty
                  ? Center(
                child: Text(
                  'No results found',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white54
                        : Colors.black45,
                  ),
                ),
              )
                  : GridView.builder(
                padding: const EdgeInsets.fromLTRB(
                    12, 8, 12, 24),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.55,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount:
                provider.searchResults.length,
                itemBuilder: (context, index) {
                  final item =
                  provider.searchResults[index];
                  return PosterCard(
                    item: item,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              DetailScreen(
                                  itemId: item.id!),
                        ),
                      );
                      if (context.mounted) {
                        provider.refreshSearch();
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Gold Filter Chip ──────────────────────────────────────────────────────────

class _GoldFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _GoldFilterChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
            colors: [
              Color(0xFFFFD700),
              Color(0xFFFFA500)
            ],
          )
              : null,
          color: selected
              ? null
              : isDark
              ? Colors.white.withOpacity(0.07)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected
                ? FontWeight.w700
                : FontWeight.w500,
            color: selected
                ? const Color(0xFF1A1A1A)
                : isDark
                ? Colors.white60
                : Colors.black54,
          ),
        ),
      ),
    );
  }
}
