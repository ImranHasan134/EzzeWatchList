// lib/ui/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/network/tmdb_service.dart';
import '../detail/global_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TmdbService _tmdbService = TmdbService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _trending = [];
  List<Map<String, dynamic>> _popularMovies = [];
  List<Map<String, dynamic>> _topRatedShows = [];
  List<Map<String, dynamic>> _animeList = [];

  @override
  void initState() {
    super.initState();
    _loadFeeds();
  }

  Future<void> _loadFeeds() async {
    // Fetch all categories simultaneously for maximum speed
    final results = await Future.wait([
      _tmdbService.getTrending(),
      _tmdbService.getPopularMovies(),
      _tmdbService.getTopRatedShows(),
      _tmdbService.getAnime(),
    ]);

    if (mounted) {
      setState(() {
        _trending = results[0];
        _popularMovies = results[1];
        _topRatedShows = results[2];
        _animeList = results[3];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF5F5F5),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700))),
      );
    }

    final featuredItem = _trending.isNotEmpty ? _trending.first : null;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── HERO BANNER (Featured Item) ──
            if (featuredItem != null) _buildHeroBanner(featuredItem, isDark),

            const SizedBox(height: 24),

            // ── HORIZONTAL CAROUSELS ──
            _buildCarousel('Trending Now', _trending.skip(1).toList(), isDark),
            _buildCarousel('Popular Movies', _popularMovies, isDark),
            _buildCarousel('Top Rated TV Shows', _topRatedShows, isDark),
            _buildCarousel('Trending Anime', _animeList, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner(Map<String, dynamic> item, bool isDark) {
    // Prefer backdrop for wide images, fallback to poster
    final imagePath = item['backdropPath'] ?? item['posterPath'];
    final genres = (item['genres'] as List<String>).take(3).join(' • ');

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Background Image
        Container(
          height: 450,
          width: double.infinity,
          foregroundDecoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                isDark ? const Color(0xFF0E0E0E).withOpacity(0.8) : const Color(0xFFF5F5F5).withOpacity(0.8),
                isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF5F5F5),
              ],
              stops: const [0.4, 0.8, 1.0],
            ),
          ),
          child: imagePath != null
              ? CachedNetworkImage(imageUrl: imagePath, fit: BoxFit.cover)
              : Container(color: Colors.grey.shade900),
        ),

        // Text & Buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Category badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFFFD700).withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFFD700))),
                child: Text(item['category'] ?? 'Movie', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),

              Text(item['title'] ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 1.1)),
              const SizedBox(height: 8),

              Text(genres, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Global Detail Screen Coming in Phase 4!')));
                    },
                    icon: const Icon(Icons.play_arrow_rounded, color: Colors.black),
                    label: const Text('Details', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFD700), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                  ),
                  const SizedBox(width: 16),
                  IconButton.filledTonal(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Save to Watchlist coming soon!')));
                    },
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(backgroundColor: isDark ? Colors.white24 : Colors.black12, padding: const EdgeInsets.all(12)),
                  )
                ],
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildCarousel(String title, List<Map<String, dynamic>> items, bool isDark) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => GlobalDetailScreen(item: item)));
                },
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: isDark ? Colors.grey.shade900 : Colors.grey.shade300),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: item['posterPath'] != null
                        ? CachedNetworkImage(imageUrl: item['posterPath'], fit: BoxFit.cover)
                        : const Center(child: Icon(Icons.movie, color: Colors.white54)),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}