// lib/ui/explore/explore_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/network/tmdb_service.dart';
import '../detail/global_detail_screen.dart';
import '../../widgets/custom_header.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TmdbService _tmdbService = TmdbService();

  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;
  bool _isSearchLoading = false;
  List<Map<String, dynamic>> _searchResults = [];
  List<String> _recentSearches = [];

  bool _isExploreLoading = true;
  List<Map<String, dynamic>> _exploreResults = [];

  final Map<String, String> _sortOptions = {
    'Most Popular': 'popularity.desc',
    'Highest Rated': 'vote_average.desc',
    'Newest First': 'primary_release_date.desc',
    'Top Revenue': 'revenue.desc',
  };
  String? _selectedSortName;

  final Map<String, int?> _genreOptions = {
    'Action': 28, 'Action & Adventure': 10759, 'Adventure': 12, 'Animation': 16,
    'Comedy': 35, 'Crime': 80, 'Documentary': 99, 'Drama': 18, 'Family': 10751,
    'Fantasy': 14, 'History': 36, 'Horror': 27, 'Kids': 10762, 'Music': 10402,
    'Mystery': 9648, 'News': 10763, 'Reality': 10764, 'Romance': 10749,
    'Sci-Fi': 878, 'Sci-Fi & Fantasy': 10765, 'Soap': 10766, 'Talk': 10767,
    'Thriller': 53, 'TV Movie': 10770, 'War': 10752, 'War & Politics': 10768, 'Western': 37,
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

  // ── 🆕 FIXED: NATIVE MATERIAL ROUTE FOR HERO AND SWIPE-BACK ──
  void _navigateToDetail(BuildContext context, Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GlobalDetailScreen(item: item)),
    );
  }

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

  Future<void> _fetchInitialData() async {
    setState(() => _isExploreLoading = true);
    try {
      final results = await Future.wait([
        _tmdbService.getTrending(page: 1),
        _tmdbService.getTrending(page: 2),
        _tmdbService.getTrending(page: 3),
      ]);
      final allItems = results.expand((page) => page).toList();
      if (mounted) {
        setState(() {
          _exploreResults = allItems;
          _isExploreLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isExploreLoading = false);
    }
  }

  Future<void> _fetchFilteredData() async {
    if (_selectedGenreName == null && _selectedSortName == null) {
      _fetchInitialData();
      return;
    }
    setState(() => _isExploreLoading = true);
    try {
      final genreId = _genreOptions[_selectedGenreName];
      final sortBy = _sortOptions[_selectedSortName] ?? 'popularity.desc';
      final results = await Future.wait([
        _tmdbService.discoverMovies(genreId: genreId, sortBy: sortBy, page: 1),
        _tmdbService.discoverMovies(genreId: genreId, sortBy: sortBy, page: 2),
        _tmdbService.discoverMovies(genreId: genreId, sortBy: sortBy, page: 3),
      ]);
      final allItems = results.expand((page) => page).toList();
      if (mounted) {
        setState(() {
          _exploreResults = allItems;
          _isExploreLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isExploreLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
        centerTitle: false,
        title: const CustomHeader(title: 'Explore', subtitle: 'Discover new favorites'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: TextField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Movies, shows or anime...',
                  hintStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w400),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFFFD700), size: 22),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.cancel_rounded, size: 20, color: Colors.grey),
                    onPressed: () {
                      _searchCtrl.clear();
                      _onSearchChanged('');
                      _searchFocus.unfocus();
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
          ),
        ),
      ),
      body: _buildDynamicBody(isDark),
    );
  }

  Widget _buildDynamicBody(bool isDark) {
    if (_searchCtrl.text.isNotEmpty) {
      return _buildSearchResults(isDark);
    } else if (_searchFocus.hasFocus) {
      return _buildRecentSearches(isDark);
    } else {
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
        const SizedBox(height: 8),
        _buildFilterRow(_genreOptions.keys.toList(), _selectedGenreName, (selected) {
          setState(() => _selectedGenreName = (_selectedGenreName == selected) ? null : selected);
          _fetchFilteredData();
        }, isDark),
        const SizedBox(height: 12),
        Expanded(
          child: _isExploreLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
              : GridView.builder(
            physics: const BouncingScrollPhysics(),
            // ── 🆕 FIXED: 100px PADDING FOR THE BOTTOM DOCK ──
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.58,
              crossAxisSpacing: 12,
              mainAxisSpacing: 20,
            ),
            itemCount: _exploreResults.length,
            itemBuilder: (context, index) => _buildPosterCard(_exploreResults[index], isDark, 'explore'),
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
            Icon(Icons.search_off_rounded, size: 80, color: isDark ? Colors.white12 : Colors.black12),
            const SizedBox(height: 16),
            Text('Looking for something specific?', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Searches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
            TextButton(
                onPressed: _clearRecentSearches,
                child: const Text('Clear All', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._recentSearches.map((query) => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: const Icon(Icons.history_rounded, color: Colors.grey, size: 22),
          title: Text(query, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          trailing: const Icon(Icons.north_west_rounded, size: 18, color: Colors.grey),
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
    if (_searchResults.isEmpty) return const Center(child: Text('No results found.', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)));

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      // ── 🆕 FIXED: 100px PADDING FOR THE BOTTOM DOCK ──
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.58,
        crossAxisSpacing: 12,
        mainAxisSpacing: 20,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) => _buildPosterCard(_searchResults[index], isDark, 'search'),
    );
  }

  Widget _buildFilterRow(List<String> options, String? selectedValue, Function(String) onSelect, bool isDark) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: options.length,
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = option == selectedValue;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(option, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? Colors.black : (isDark ? Colors.white70 : Colors.black87))),
              selected: isSelected,
              onSelected: (_) => onSelect(option),
              selectedColor: const Color(0xFFFFD700),
              backgroundColor: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
              side: BorderSide(color: isSelected ? const Color(0xFFFFD700) : Colors.transparent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPosterCard(Map<String, dynamic> item, bool isDark, String tag) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _searchFocus.unfocus();
          _navigateToDetail(context, item);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              // ── 🆕 FLAWLESS HERO TAG ──
              child: Hero(
                tag: 'hero_poster_${item['tmdbId'] ?? item['id']}',
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: item['posterPath'] != null
                        ? CachedNetworkImage(
                      imageUrl: item['posterPath'],
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 300),
                    )
                        : const Center(child: Icon(Icons.movie_filter_rounded, color: Colors.white24, size: 30)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] ?? 'Unknown',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.2),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        (item['rating'] as num?)?.toStringAsFixed(1) ?? '0.0',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}