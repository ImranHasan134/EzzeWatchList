// lib/data/database/watch_provider.dart

import 'package:flutter/foundation.dart';
import '../database/db_helper.dart';
import '../models/watch_item.dart';
import '../network/sync_service.dart';

class WatchProvider extends ChangeNotifier {
  final DbHelper _db = DbHelper();

  List<WatchItem> _watched  = [];
  List<WatchItem> _watching = [];
  List<WatchItem> _planned  = [];

  List<WatchItem> get watched  => _watched;
  List<WatchItem> get watching => _watching;
  List<WatchItem> get planned  => _planned;
  List<WatchItem> get items => [..._watched, ..._watching, ..._planned];

  List<WatchItem> _searchResults = [];
  String _searchQuery    = '';
  String _filterGenre    = '';
  String _filterCategory = '';
  String _sortingOption = 'Recently Added'; // 🆕 sorting state

  List<WatchItem> get searchResults  => _searchResults;
  String get searchQuery    => _searchQuery;
  String get filterGenre    => _filterGenre;
  String get filterCategory => _filterCategory;
  String get sortingOption => _sortingOption; // expose

  int     _watchedCount = 0;
  int     _totalCount   = 0;
  double? _averageRating;
  String? _topGenre;

  int     get watchedCount  => _watchedCount;
  int     get totalCount    => _totalCount;
  double? get averageRating => _averageRating;
  String? get topGenre      => _topGenre;

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

  Future<void> addItem(WatchItem item) async {
    await _db.insertItem(item);
    await SyncService.pushItem(item); // Push to cloud
    await loadAll();
  }

  Future<void> updateItem(WatchItem item) async {
    await _db.updateItem(item);
    await SyncService.pushItem(item); // Update in cloud
    await loadAll();
    await refreshSearch();
  }

  Future<void> deleteItem(int id) async {
    final item = await _db.getItemById(id);
    if (item != null) {
      await _db.deleteItem(id);
      await SyncService.deleteItem(item.createdAt); // Delete from cloud
      await loadAll();
      await refreshSearch();
    }
  }

  Future<WatchItem?> getItemById(int id) => _db.getItemById(id);

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

  // 🆕 sorting methods
  Future<void> setSortingOption(String option) async {
    _sortingOption = option;
    await refreshSearch();
  }

  Future<void> refreshSearch() async {
    _searchResults = await _db.searchAndFilter(
      query: _searchQuery,
      genre: _filterGenre,
      category: _filterCategory,
      sorting: _sortingOption, // 🆕 Pass sorting
    );
    notifyListeners();
  }

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