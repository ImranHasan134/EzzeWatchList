// lib/ui/explore/explore_screen.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/network/tmdb_service.dart';
import '../detail/global_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TmdbService _tmdbService = TmdbService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _results = [];

  // Sorting Options
  final Map<String, String> _sortOptions = {
    'Most Popular': 'popularity.desc',
    'Highest Rated': 'vote_average.desc',
    'Newest First': 'primary_release_date.desc',
    'Revenue': 'revenue.desc',
  };
  String _selectedSortName = 'Most Popular';

  // Genre Options (Mapped to TMDB IDs)
  final Map<String, int?> _genreOptions = {
    'All Genres': null,
    'Action': 28,
    'Adventure': 12,
    'Animation': 16,
    'Comedy': 35,
    'Horror': 27,
    'Romance': 10749,
    'Sci-Fi': 878,
    'Thriller': 53,
  };
  String _selectedGenreName = 'All Genres';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    final genreId = _genreOptions[_selectedGenreName];
    final sortBy = _sortOptions[_selectedSortName]!;

    final results = await _tmdbService.discoverMovies(genreId: genreId, sortBy: sortBy);

    if (mounted) {
      setState(() {
        _results = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF5F5F5),
        title: const Text('Explore', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // ── SORTING PILLS ──
              _buildFilterRow(_sortOptions.keys.toList(), _selectedSortName, (selected) {
                setState(() => _selectedSortName = selected);
                _fetchData();
              }, isDark),

              // ── GENRE PILLS ──
              _buildFilterRow(_genreOptions.keys.toList(), _selectedGenreName, (selected) {
                setState(() => _selectedGenreName = selected);
                _fetchData();
              }, isDark),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
          : _results.isEmpty
          ? const Center(child: Text('No results found.'))
          : GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.65, // Taller posters
          crossAxisSpacing: 10,
          mainAxisSpacing: 16,
        ),
        itemCount: _results.length,
        itemBuilder: (context, index) {
          final item = _results[index];
          return _buildPosterCard(item, isDark);
        },
      ),
    );
  }

  // ── HELPER: FILTER ROW ──
  Widget _buildFilterRow(List<String> options, String selectedValue, Function(String) onSelect, bool isDark) {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: options.length,
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = option == selectedValue;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(option, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
              selected: isSelected,
              onSelected: (_) => onSelect(option),
              selectedColor: const Color(0xFFFFD700).withOpacity(0.2),
              checkmarkColor: const Color(0xFFFFD700),
              backgroundColor: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
              side: BorderSide(color: isSelected ? const Color(0xFFFFD700) : Colors.transparent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  // ── HELPER: POSTER CARD ──
  Widget _buildPosterCard(Map<String, dynamic> item, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => GlobalDetailScreen(item: item)));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade300,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: item['posterPath'] != null
                    ? CachedNetworkImage(imageUrl: item['posterPath'], fit: BoxFit.cover)
                    : const Center(child: Icon(Icons.movie, color: Colors.white54)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item['title'] ?? 'Unknown',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              const Icon(Icons.star, color: Color(0xFFFFD700), size: 12),
              const SizedBox(width: 4),
              Text(
                (item['rating'] as num).toStringAsFixed(1),
                style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black54),
              ),
            ],
          )
        ],
      ),
    );
  }
}