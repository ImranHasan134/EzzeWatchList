// lib/data/database/watch_provider.dart

import 'package:flutter/foundation.dart';
import '../database/db_helper.dart';
import '../models/watch_item.dart';

// Single ChangeNotifier that drives the whole app.
// Future upgrade: swap DbHelper calls with Supabase calls here.
class WatchProvider extends ChangeNotifier {
  final DbHelper _db = DbHelper();

  // ── Per-tab lists ────────────────────────────────────────────────────────
  List<WatchItem> _watched  = [];
  List<WatchItem> _watching = [];
  List<WatchItem> _planned  = [];

  List<WatchItem> get watched  => _watched;
  List<WatchItem> get watching => _watching;
  List<WatchItem> get planned  => _planned;

  // ── Search & Filter ──────────────────────────────────────────────────────
  List<WatchItem> _searchResults = [];
  String _searchQuery    = '';
  String _filterGenre    = '';
  String _filterCategory = '';

  List<WatchItem> get searchResults  => _searchResults;
  String get searchQuery    => _searchQuery;
  String get filterGenre    => _filterGenre;
  String get filterCategory => _filterCategory;

  // ── Stats ────────────────────────────────────────────────────────────────
  int     _watchedCount = 0;
  int     _totalCount   = 0;
  double? _averageRating;
  String? _topGenre;

  int     get watchedCount  => _watchedCount;
  int     get totalCount    => _totalCount;
  double? get averageRating => _averageRating;
  String? get topGenre      => _topGenre;

  // ── Init ─────────────────────────────────────────────────────────────────
  Future<void> loadAll() async {
    await Future.wait([
      _loadTab(WatchStatus.watched),
      _loadTab(WatchStatus.watching),
      _loadTab(WatchStatus.planned),
      _loadStats(),
    ]);
    notifyListeners();
  }

  Future<void> _loadTab(String status) async {
    final items = await _db.getItemsByStatus(status);
    switch (status) {
      case WatchStatus.watched:  _watched  = items; break;
      case WatchStatus.watching: _watching = items; break;
      case WatchStatus.planned:  _planned  = items; break;
    }
  }

  Future<void> _loadStats() async {
    _watchedCount  = await _db.getWatchedCount();
    _totalCount    = await _db.getTotalCount();
    _averageRating = await _db.getAverageRating();

    final genresList = await _db.getAllWatchedGenres();
    _topGenre = _getMostFrequentGenre(genresList);
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────
  Future<void> addItem(WatchItem item) async {
    await _db.insertItem(item);
    await loadAll();
  }

  Future<void> updateItem(WatchItem item) async {
    await _db.updateItem(item);
    await loadAll();
    await refreshSearch();
  }

  Future<void> deleteItem(int id) async {
    await _db.deleteItem(id);
    await loadAll();
    await refreshSearch();
  }

  Future<WatchItem?> getItemById(int id) => _db.getItemById(id);

  // ── Search ────────────────────────────────────────────────────────────────
  Future<void> setSearchQuery(String query) async {
    _searchQuery = query;
    await refreshSearch();
  }

  Future<void> setFilterGenre(String genre) async {
    _filterGenre = genre;
    await refreshSearch();
  }

  Future<void> setFilterCategory(String category) async {
    _filterCategory = category;
    await refreshSearch();
  }

  Future<void> refreshSearch() async {
    _searchResults = await _db.searchAndFilter(
      query: _searchQuery,
      genre: _filterGenre,
      category: _filterCategory,
    );
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String? _getMostFrequentGenre(List<String> genresList) {
    final counts = <String, int>{};
    for (final genres in genresList) {
      for (final g in genres.split(',')) {
        if (g.trim().isNotEmpty) {
          counts[g.trim()] = (counts[g.trim()] ?? 0) + 1;
        }
      }
    }
    if (counts.isEmpty) return null;
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}
