// lib/data/database/db_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/watch_item.dart';

class DbHelper {
  // ── Singleton ──────────────────────────────────────────────
  static final DbHelper _instance = DbHelper._internal();
  factory DbHelper() => _instance;
  DbHelper._internal();

  // ── Database ───────────────────────────────────────────────
  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  // ── Table name ─────────────────────────────────────────────
  static const String tableWatch = 'watch_items';

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'ezze_watchlist.db');

    return await openDatabase(
      path,
      version: 2, // 🆕 Incremented version to apply the new column safely
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableWatch(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            category TEXT,
            genres TEXT,
            releaseYear TEXT,
            description TEXT,
            rating REAL,
            status TEXT,
            posterPath TEXT,
            seasons INTEGER,
            episodes INTEGER,
            createdAt INTEGER,
            hindiAvailable TEXT DEFAULT 'No',
            watchSource TEXT DEFAULT '',
            tmdbId INTEGER 
          )
        '''); // 🆕 tmdbId added to creation script
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // 🆕 This safely updates existing users' databases without wiping their data
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE $tableWatch ADD COLUMN tmdbId INTEGER;');
        }
      },
    );
  }

  // ── CRUD METHODS ───────────────────────────────────────────

  Future<int> insertItem(WatchItem item) async {
    final db = await database;
    return db.insert(
      tableWatch,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateItem(WatchItem item) async {
    final db = await database;
    return db.update(
      tableWatch,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteItem(int id) async {
    final db = await database;
    return db.delete(tableWatch, where: 'id = ?', whereArgs: [id]);
  }

  Future<WatchItem?> getItemById(int id) async {
    final db = await database;
    final maps = await db.query(tableWatch, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return WatchItem.fromMap(maps.first);
  }

  Future<List<WatchItem>> getAllItems() async {
    final db = await database;
    final maps = await db.query(tableWatch, orderBy: 'createdAt DESC');
    return maps.map(WatchItem.fromMap).toList();
  }

  Future<void> insertAllItems(List<WatchItem> items) async {
    final db = await database;
    final batch = db.batch();
    for (final item in items) {
      final map = item.toMap()..remove('id');
      batch.insert(tableWatch, map, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> clearAllItems() async {
    final db = await database;
    await db.delete(tableWatch);
  }

  Future<List<WatchItem>> getItemsByStatus(String status) async {
    final db = await database;
    final maps = await db.query(
      tableWatch,
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'createdAt DESC',
    );
    return maps.map(WatchItem.fromMap).toList();
  }

  Future<List<WatchItem>> searchAndFilter({
    String query = '',
    String genre = '',
    String category = '',
    String sorting = 'Recently Added',
  }) async {
    final db = await database;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (query.isNotEmpty) {
      conditions.add("title LIKE ?");
      args.add('%$query%');
    }
    if (genre.isNotEmpty) {
      conditions.add("genres LIKE ?");
      args.add('%$genre%');
    }
    if (category.isNotEmpty) {
      conditions.add("category = ?");
      args.add(category);
    }

    final where = conditions.isEmpty ? null : conditions.join(' AND ');

    // 🆕 Dynamic Sorting Logic Applied Here
    String orderBy;
    switch (sorting) {
      case 'Highest Rated':
        orderBy = 'rating DESC';
        break;
      case 'Newest Release':
        orderBy = 'releaseYear DESC, title ASC';
        break;
      case 'Recently Added':
      default:
        orderBy = 'createdAt DESC';
        break;
    }

    final maps = await db.query(
      tableWatch,
      where: where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: orderBy, // 🆕 Ordering is now dynamic!
    );
    return maps.map(WatchItem.fromMap).toList();
  }

  // ── STATS ────────────────────────────────────────────────

  Future<int> getWatchedCount() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as cnt FROM $tableWatch WHERE status = 'Watched'",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTotalCount() async {
    final db = await database;
    final result = await db.rawQuery("SELECT COUNT(*) as cnt FROM $tableWatch");
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<double?> getAverageRating() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT AVG(rating) as avg FROM $tableWatch WHERE status = 'Watched'",
    );
    if (result.isEmpty || result.first['avg'] == null) return null;
    return (result.first['avg'] as num).toDouble();
  }

  Future<List<String>> getAllWatchedGenres() async {
    final db = await database;
    final maps = await db.query(
      tableWatch,
      columns: ['genres'],
      where: "status = 'Watched'",
    );
    return maps.map((m) => m['genres'] as String).toList();
  }
}