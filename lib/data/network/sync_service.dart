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
    if (user == null) return;

    try {
      // 🔴 SMART FIX: Use toMap() so you never have to manually type columns again!
      final itemData = item.toMap();

      // We remove the local SQLite 'id' because Supabase generates its own unique ID.
      itemData.remove('id');

      // Inject the user_id required for Supabase Row Level Security
      itemData['user_id'] = user.id;

      await _supabase.from('EzzeWatchList_watch_items').upsert(
          itemData,
          onConflict: '"createdAt", user_id'
      );
    } catch (e) {
      print('Cloud Push Error: $e');
    }
  }

  // ── 2. Delete an item from the cloud ────────────────────────
  static Future<void> deleteItem(int createdAt) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('EzzeWatchList_watch_items')
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
      final response = await _supabase.from('EzzeWatchList_watch_items').select();
      final List<dynamic> data = response;

      if (data.isEmpty) return;

      // 🔴 SMART FIX: Use fromMap() to automatically parse all new columns perfectly!
      final cloudItems = data.map((row) => WatchItem.fromMap(row)).toList();

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