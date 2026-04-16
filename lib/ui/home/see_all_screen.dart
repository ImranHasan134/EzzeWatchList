// lib/ui/home/see_all_screen.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/network/tmdb_service.dart';
import '../detail/global_detail_screen.dart';

class SeeAllScreen extends StatefulWidget {
  final String title;
  final String categoryType; // 'trending', 'popular', 'top_rated', 'anime'

  const SeeAllScreen({super.key, required this.title, required this.categoryType});

  @override
  State<SeeAllScreen> createState() => _SeeAllScreenState();
}

class _SeeAllScreenState extends State<SeeAllScreen> {
  final TmdbService _tmdbService = TmdbService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch 60 items (3 pages) based on category
      final results = await Future.wait([
        _getFetchFunction(1),
        _getFetchFunction(2),
        _getFetchFunction(3),
      ]);

      final allItems = results.expand((page) => page).toList();
      if (mounted) setState(() { _items = allItems; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _getFetchFunction(int page) {
    return switch (widget.categoryType) {
      'trending'  => _tmdbService.getTrending(page: page),
      'popular'   => _tmdbService.getPopularMovies(page: page),
      'top_rated' => _tmdbService.getTopRatedShows(page: page),
      _           => _tmdbService.getAnime(page: page),
    };
  }

  // ── 🆕 FIXED ROUTING: Passes Unique Tag and Uses MaterialPageRoute ──
  void _navigateToDetail(BuildContext context, Map<String, dynamic> item, String heroTag) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GlobalDetailScreen(item: item, heroTag: heroTag)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
          : GridView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.58,
          crossAxisSpacing: 12,
          mainAxisSpacing: 20,
        ),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];

          // ── 🆕 UNIQUE HERO TAG (Matches HomeScreen logic) ──
          final uniqueTag = 'home_${widget.categoryType}_${item['tmdbId'] ?? item['id']}';

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _navigateToDetail(context, item, uniqueTag),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 🆕 SYNCHRONIZED HERO WIDGET ──
                  Expanded(
                    child: Hero(
                      tag: uniqueTag,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: item['posterPath'] != null && item['posterPath'].toString().isNotEmpty
                            ? CachedNetworkImage(
                          imageUrl: item['posterPath'],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          fadeInDuration: const Duration(milliseconds: 300),
                        )
                            : Container(
                          width: double.infinity,
                          color: Colors.grey.shade900,
                          child: const Icon(Icons.movie, color: Colors.white54),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      item['title'] ?? 'Unknown',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, height: 1.2),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}