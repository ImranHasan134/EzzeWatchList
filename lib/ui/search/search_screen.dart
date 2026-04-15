// lib/ui/search/search_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/network/tmdb_service.dart';
import '../detail/global_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TmdbService _tmdbService = TmdbService();

  Timer? _debounce;
  bool _isLoading = false;

  List<Map<String, dynamic>> _searchResults = [];
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── RECENT SEARCHES LOGIC (Shared Preferences) ──
  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _recentSearches = prefs.getStringList('recent_searches') ?? [];
      });
    }
  }

  Future<void> _saveSearch(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();

    // Remove if it already exists to avoid duplicates, then add to top
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);

    // Keep only the last 10 searches to save space
    if (_recentSearches.length > 10) _recentSearches.removeLast();

    await prefs.setStringList('recent_searches', _recentSearches);
    if (mounted) setState(() {});
  }

  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    if (mounted) setState(() => _recentSearches.clear());
  }

  // ── REAL-TIME DEBOUNCE SEARCH LOGIC ──
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    // Wait 500ms after the user stops typing before hitting the API
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      _saveSearch(query.trim());

      final results = await _tmdbService.searchContent(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTyping = _searchCtrl.text.isNotEmpty;

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
            autofocus: true,
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Search movies, anime, series...',
              hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
              prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.black54),
              suffixIcon: isTyping
                  ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  _searchCtrl.clear();
                  _onSearchChanged('');
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
      body: isTyping
          ? _buildSearchResults(isDark)
          : _buildRecentSearches(isDark),
    );
  }

  // ── UI: RECENT SEARCHES ──
  Widget _buildRecentSearches(bool isDark) {
    if (_recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.manage_search, size: 80, color: isDark ? Colors.white12 : Colors.black12),
            const SizedBox(height: 16),
            Text('Search for a movie or series', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 16)),
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
            TextButton(
              onPressed: _clearRecentSearches,
              child: const Text('Clear All', style: TextStyle(color: Colors.redAccent)),
            ),
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

  // ── UI: TMDB GRID RESULTS ──
  Widget _buildSearchResults(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
    }

    if (_searchResults.isEmpty) {
      return const Center(child: Text('No results found.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.55,
        crossAxisSpacing: 10,
        mainAxisSpacing: 16,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final item = _searchResults[index];
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
      },
    );
  }
}