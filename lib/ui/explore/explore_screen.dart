// lib/ui/explore/explore_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // ── SEARCH STATE ──
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;
  bool _isSearchLoading = false;
  List<Map<String, dynamic>> _searchResults = [];
  List<String> _recentSearches = [];

  // ── EXPLORE STATE ──
  bool _isExploreLoading = true;
  List<Map<String, dynamic>> _exploreResults = [];

  final Map<String, String> _sortOptions = {
    'Most Popular': 'popularity.desc',
    'Highest Rated': 'vote_average.desc',
    'Newest First': 'primary_release_date.desc',
    'Top Revenue': 'revenue.desc',
  };
  String? _selectedSortName;

  // ── 🆕 YOUR FULL GENRE LIST ──
  final Map<String, int?> _genreOptions = {
    'Action': 28,
    'Action & Adventure': 10759,
    'Adventure': 12,
    'Animation': 16,
    'Avant Garde': null,
    'Award Winning': null,
    'Boys Love': null,
    'Comedy': 35,
    'Crime': 80,
    'Documentary': 99,
    'Drama': 18,
    'Ecchi': null,
    'Family': 10751,
    'Fantasy': 14,
    'Girls Love': null,
    'Gourmet': null,
    'History': 36,
    'Horror': 27,
    'Isekai': null,
    'Kids': 10762,
    'Magic': null,
    'Martial Arts': null,
    'Mecha': null,
    'Music': 10402,
    'Mystery': 9648,
    'News': 10763,
    'Psychological': null,
    'Reality': 10764,
    'Romance': 10749,
    'Sci-Fi': 878,
    'Sci-Fi & Fantasy': 10765,
    'Slice of Life': null,
    'Soap': 10766,
    'Sports': null,
    'Supernatural': null,
    'Suspense': null,
    'Talk': 10767,
    'Thriller': 53,
    'TV Movie': 10770,
    'War': 10752,
    'War & Politics': 10768,
    'Western': 37,
  };
  String? _selectedGenreName;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _fetchInitialData();
    _searchFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── 🔍 SEARCH LOGIC ──────────────────────────────────────────

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _recentSearches = prefs.getStringList('recent_searches') ?? []);
  }

  Future<void> _saveSearch(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
    if (_recentSearches.length > 10) _recentSearches.removeLast();
    await prefs.setStringList('recent_searches', _recentSearches);
    if (mounted) setState(() {});
  }

  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    if (mounted) setState(() => _recentSearches.clear());
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearchLoading = false;
      });
      return;
    }

    setState(() => _isSearchLoading = true);

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      _saveSearch(query.trim());
      final results = await _tmdbService.searchContent(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearchLoading = false;
        });
      }
    });
  }

  // ── 🧭 EXPLORE LOGIC ─────────────────────────────────────────

  Future<void> _fetchInitialData() async {
    setState(() => _isExploreLoading = true);
    final results = await _tmdbService.getTrending();
    if (mounted) {
      setState(() {
        _exploreResults = results;
        _isExploreLoading = false;
      });
    }
  }

  Future<void> _fetchFilteredData() async {
    if (_selectedGenreName == null && _selectedSortName == null) {
      _fetchInitialData();
      return;
    }
    setState(() => _isExploreLoading = true);
    final results = await _tmdbService.discoverMovies(
      genreId: _genreOptions[_selectedGenreName],
      sortBy: _sortOptions[_selectedSortName] ?? 'popularity.desc',
    );
    if (mounted) {
      setState(() {
        _exploreResults = results;
        _isExploreLoading = false;
      });
    }
  }

  // ── 📱 UI RENDERING ──────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchCtrl,
            focusNode: _searchFocus,
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Search or explore...',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  _searchCtrl.clear();
                  _onSearchChanged('');
                  _searchFocus.unfocus();
                },
              )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
      ),
      body: _buildDynamicBody(isDark),
    );
  }

  Widget _buildDynamicBody(bool isDark) {
    if (_searchCtrl.text.isNotEmpty) {
      return _buildSearchResults(isDark);
    }
    else if (_searchFocus.hasFocus) {
      return _buildRecentSearches(isDark);
    }
    else {
      return _buildExploreView(isDark);
    }
  }

  Widget _buildExploreView(bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 12),
        _buildFilterRow(_sortOptions.keys.toList(), _selectedSortName, (selected) {
          setState(() => _selectedSortName = (_selectedSortName == selected) ? null : selected);
          _fetchFilteredData();
        }, isDark),
        _buildFilterRow(_genreOptions.keys.toList(), _selectedGenreName, (selected) {
          setState(() => _selectedGenreName = (_selectedGenreName == selected) ? null : selected);
          _fetchFilteredData();
        }, isDark),
        const SizedBox(height: 12),
        Expanded(
          child: _isExploreLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
              : GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, childAspectRatio: 0.6, crossAxisSpacing: 10, mainAxisSpacing: 16,
            ),
            itemCount: _exploreResults.length,
            itemBuilder: (context, index) => _buildPosterCard(_exploreResults[index], isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSearches(bool isDark) {
    if (_recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.manage_search, size: 80, color: isDark ? Colors.white12 : Colors.black12),
            const SizedBox(height: 16),
            Text('Type to search for movies or anime', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Searches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(onPressed: _clearRecentSearches, child: const Text('Clear All', style: TextStyle(color: Colors.redAccent))),
          ],
        ),
        const SizedBox(height: 8),
        ..._recentSearches.map((query) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.history, color: Colors.grey),
          title: Text(query, style: const TextStyle(fontSize: 16)),
          trailing: const Icon(Icons.north_west, size: 16, color: Colors.grey),
          onTap: () {
            _searchCtrl.text = query;
            _searchCtrl.selection = TextSelection.fromPosition(TextPosition(offset: query.length));
            _onSearchChanged(query);
          },
        )),
      ],
    );
  }

  Widget _buildSearchResults(bool isDark) {
    if (_isSearchLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
    if (_searchResults.isEmpty) return const Center(child: Text('No results found.'));

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, childAspectRatio: 0.55, crossAxisSpacing: 10, mainAxisSpacing: 16,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) => _buildPosterCard(_searchResults[index], isDark),
    );
  }

  Widget _buildFilterRow(List<String> options, String? selectedValue, Function(String) onSelect, bool isDark) {
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
              label: Text(option, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.black : (isDark ? Colors.white70 : Colors.black87))),
              selected: isSelected,
              onSelected: (_) => onSelect(option),
              selectedColor: const Color(0xFFFFD700),
              backgroundColor: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
              side: BorderSide(color: isSelected ? const Color(0xFFFFD700) : Colors.transparent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPosterCard(Map<String, dynamic> item, bool isDark) {
    return GestureDetector(
      onTap: () {
        _searchFocus.unfocus();
        Navigator.push(context, MaterialPageRoute(builder: (_) => GlobalDetailScreen(item: item)));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: isDark ? Colors.grey.shade900 : Colors.grey.shade300),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: item['posterPath'] != null
                    ? CachedNetworkImage(imageUrl: item['posterPath'], fit: BoxFit.cover)
                    : const Center(child: Icon(Icons.movie, color: Colors.white54)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(item['title'] ?? 'Unknown', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          Row(
            children: [
              const Icon(Icons.star, color: Color(0xFFFFD700), size: 12),
              const SizedBox(width: 4),
              Text((item['rating'] as num?)?.toStringAsFixed(1) ?? '0.0', style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black54)),
            ],
          )
        ],
      ),
    );
  }
}