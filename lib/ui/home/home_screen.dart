// lib/ui/home/home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/network/tmdb_service.dart';
import '../detail/global_detail_screen.dart';
import 'see_all_screen.dart';
import '../../widgets/custom_header.dart';

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

  final PageController _pageController = PageController();
  Timer? _carouselTimer;
  int _currentCarouselIndex = 0;

  final goldGradient = const LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  void initState() {
    super.initState();
    _loadFeeds();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadFeeds() async {
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
      _startCarousel();
    }
  }

  void _startCarousel() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (_pageController.hasClients && _trending.isNotEmpty) {
        int nextIndex = _currentCarouselIndex + 1;
        if (nextIndex >= 10 || nextIndex >= _trending.length) {
          nextIndex = 0;
        }
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 900),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  // ── 🆕 FIXED: USES NATIVE MATERIAL ROUTE FOR FLAWLESS HERO & SWIPE-BACK ──
  void _navigateToDetail(BuildContext context, Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GlobalDetailScreen(item: item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF5F5F5);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFFD700)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(0.8), Colors.transparent],
            ),
          ),
        ),
        centerTitle: false,
        title: const CustomHeader(title: 'Home', subtitle: 'What to watch today'),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        // ── 🆕 FIXED: ADDED 100px BOTTOM PADDING FOR THE DOCK ──
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroCarousel(isDark),
            const SizedBox(height: 24),
            _buildCarousel('Trending Now', _trending.skip(10).toList(), isDark, 'trending'),
            _buildCarousel('Popular Movies', _popularMovies, isDark, 'popular'),
            _buildCarousel('Top Rated TV Shows', _topRatedShows, isDark, 'top_rated'),
            _buildCarousel('Trending Anime', _animeList, isDark, 'anime'),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCarousel(bool isDark) {
    final topItems = _trending.take(10).toList();
    if (topItems.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 550,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) => setState(() => _currentCarouselIndex = index),
            itemCount: topItems.length,
            itemBuilder: (context, index) {
              final item = topItems[index];
              final imagePath = item['backdropPath'] ?? item['posterPath'];
              final genres = (item['genres'] as List<String>).take(3).join(' • ');

              return GestureDetector(
                onTap: () => _navigateToDetail(context, item),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // ── 🆕 FLAWLESS HERO TAG ──
                    Hero(
                      tag: 'hero_poster_${item['tmdbId'] ?? item['id']}',
                      child: Container(
                        height: 550,
                        width: double.infinity,
                        foregroundDecoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              isDark ? const Color(0xFF0E0E0E).withOpacity(0.5) : const Color(0xFFF5F5F5).withOpacity(0.5),
                              isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF5F5F5),
                            ],
                            stops: const [0.4, 0.8, 1.0],
                          ),
                        ),
                        child: imagePath != null
                            ? CachedNetworkImage(
                          imageUrl: imagePath,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 400),
                        )
                            : Container(color: Colors.grey.shade900),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 50),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                            ),
                            child: Text(
                              (item['category'] ?? 'Movie').toUpperCase(),
                              style: const TextStyle(color: Color(0xFFFFD700), fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            item['title'] ?? '',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            genres,
                            style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(topItems.length, (dotIndex) {
                final isActive = _currentCarouselIndex == dotIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: isActive ? goldGradient : null,
                    color: isActive ? null : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel(String title, List<Map<String, dynamic>> items, bool isDark, String categoryType) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => SeeAllScreen(title: title, categoryType: categoryType),
                  ));
                },
                style: TextButton.styleFrom(splashFactory: NoSplash.splashFactory),
                child: const Text('See all', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                width: 130,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _navigateToDetail(context, item),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── 🆕 FLAWLESS HERO TAG ──
                        Hero(
                          tag: 'hero_poster_${item['tmdbId'] ?? item['id']}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AspectRatio(
                              aspectRatio: 2 / 3,
                              child: item['posterPath'] != null
                                  ? CachedNetworkImage(
                                imageUrl: item['posterPath'],
                                fit: BoxFit.cover,
                                fadeInDuration: const Duration(milliseconds: 300),
                              )
                                  : Container(color: Colors.grey.shade900, child: const Icon(Icons.movie, color: Colors.white54)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            item['title'] ?? 'Unknown',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, height: 1.2),
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ],
                    ),
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