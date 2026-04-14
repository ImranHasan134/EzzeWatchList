// lib/data/network/sync_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/watch_item.dart';
import '../database/db_helper.dart';

class SyncService {
  static final _supabase = Supabase.instance.client;
  static final _db = DbHelper();

  // ── 1. Push a single item to the cloud ──────────────────────
  static Future<void> pushItem(WatchItem item) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return; // If logged out, stay local-only

    try {
      await _supabase.from('watch_items').upsert({
        'user_id': user.id,
        'title': item.title,
        'category': item.category,
        'genres': item.genres,
        'releaseYear': item.releaseYear,
        'description': item.description,
        'rating': item.rating,
        'status': item.status,
        'posterPath': item.posterPath,
        'seasons': item.seasons,
        'episodes': item.episodes,
        'createdAt': item.createdAt, // This acts as our unique sync ID
        'hindiAvailable': item.hindiAvailable,
        'watchSource': item.watchSource,
      }, onConflict: '"createdAt", user_id');
    } catch (e) {
      print('Cloud Push Error: $e');
    }
  }

  // ── 2. Delete an item from the cloud ────────────────────────
  static Future<void> deleteItem(int createdAt) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('watch_items')
          .delete()
          .match({'createdAt': createdAt, 'user_id': user.id});
    } catch (e) {
      print('Cloud Delete Error: $e');
    }
  }

  // ── 3. Pull cloud data & Merge on Login ─────────────────────
  static Future<void> syncCloudToLocal() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Fetch all items from Supabase
      final response = await _supabase.from('watch_items').select();
      final List<dynamic> data = response;

      if (data.isEmpty) return;

      // Convert Supabase rows to Local WatchItem objects
      final cloudItems = data.map((row) => WatchItem(
        title: row['title'],
        category: row['category'],
        genres: row['genres'],
        releaseYear: row['releaseYear'] ?? '',
        description: row['description'] ?? '',
        rating: (row['rating'] as num).toDouble(),
        status: row['status'],
        posterPath: row['posterPath'],
        seasons: row['seasons'],
        episodes: row['episodes'],
        createdAt: row['createdAt'],
        hindiAvailable: row['hindiAvailable'],
        watchSource: row['watchSource'],
      )).toList();

      // Get local items to figure out what is missing
      final localItems = await _db.getAllItems();
      final localCreatedAts = localItems.map((e) => e.createdAt).toSet();

      // Insert items from the cloud that aren't on this phone yet
      List<WatchItem> missingLocally = [];
      for (var item in cloudItems) {
        if (!localCreatedAts.contains(item.createdAt)) {
          missingLocally.add(item);
        }
      }
      if (missingLocally.isNotEmpty) {
        await _db.insertAllItems(missingLocally);
      }

      // Push local items that aren't in the cloud yet (Two-way sync!)
      final cloudCreatedAts = cloudItems.map((e) => e.createdAt).toSet();
      for (var item in localItems) {
        if (!cloudCreatedAts.contains(item.createdAt)) {
          await pushItem(item);
        }
      }
    } catch (e) {
      print('Cloud Sync Error: $e');
    }
  }
}