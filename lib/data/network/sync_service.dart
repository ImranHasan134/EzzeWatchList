// lib/data/network/sync_service.dart

import 'dart:async'; // ── 🆕 REQUIRED FOR TIMEOUTS ──
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
      final itemData = item.toMap();
      itemData.remove('id');
      // ── 🆕 FIXED: Removed the stray dot before the bracket ──
      itemData['user_id'] = user.id;

      // ── 🆕 FIXED: 15 SECOND TIMEOUT ──
      await _supabase.from('EzzeWatchList_watch_items').upsert(
          itemData,
          onConflict: '"createdAt", user_id'
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      print('Cloud Push Error: $e');
    }
  }

  // ── 2. Delete an item from the cloud ────────────────────────
  static Future<void> deleteItem(int createdAt) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // ── 🆕 FIXED: 15 SECOND TIMEOUT ──
      await _supabase.from('EzzeWatchList_watch_items')
          .delete()
          .match({'createdAt': createdAt, 'user_id': user.id})
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      print('Cloud Delete Error: $e');
    }
  }

  // ── 3. Pull cloud data & Merge on Login ─────────────────────
  static Future<void> syncCloudToLocal() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // ── 🆕 FIXED: 15 SECOND TIMEOUT ──
      final response = await _supabase
          .from('EzzeWatchList_watch_items')
          .select()
          .timeout(const Duration(seconds: 15));

      final List<dynamic> data = response;

      if (data.isEmpty) return;

      final cloudItems = data.map((row) => WatchItem.fromMap(row)).toList();
      final localItems = await _db.getAllItems();
      final localCreatedAts = localItems.map((e) => e.createdAt).toSet();

      List<WatchItem> missingLocally = [];
      for (var item in cloudItems) {
        if (!localCreatedAts.contains(item.createdAt)) {
          missingLocally.add(item);
        }
      }
      if (missingLocally.isNotEmpty) {
        await _db.insertAllItems(missingLocally);
      }

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