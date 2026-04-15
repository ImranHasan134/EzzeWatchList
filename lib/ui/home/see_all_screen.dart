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
      // 🆕 Fetch 60 items (3 pages) based on category
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
          : GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, childAspectRatio: 0.6, crossAxisSpacing: 10, mainAxisSpacing: 16,
        ),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GlobalDetailScreen(item: item))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(imageUrl: item['posterPath'] ?? '', fit: BoxFit.cover, width: double.infinity),
                  ),
                ),
                const SizedBox(height: 6),
                Text(item['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        },
      ),
    );
  }
}