// lib/data/database/db_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/watch_item.dart';

class DbHelper {
  static final DbHelper _instance = DbHelper._internal();
  factory DbHelper() => _instance;
  DbHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'ezze_watchlist.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE watch_items (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            title      TEXT    NOT NULL,
            category   TEXT    NOT NULL,
            genres     TEXT    NOT NULL,
            releaseYear TEXT   NOT NULL,
            description TEXT   NOT NULL,
            rating     REAL    NOT NULL,
            status     TEXT    NOT NULL,
            posterPath TEXT,
            seasons    INTEGER,
            episodes   INTEGER,
            createdAt  INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  // ── CRUD ────────────────────────────────────────────────────────────────

  Future<int> insertItem(WatchItem item) async {
    final db = await database;
    return db.insert('watch_items', item.toMap());
  }

  Future<int> updateItem(WatchItem item) async {
    final db = await database;
    return db.update(
      'watch_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteItem(int id) async {
    final db = await database;
    return db.delete('watch_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<WatchItem?> getItemById(int id) async {
    final db = await database;
    final maps = await db.query('watch_items', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return WatchItem.fromMap(maps.first);
  }

  // ── Queries ─────────────────────────────────────────────────────────────

  Future<List<WatchItem>> getAllItems() async {
    final db = await database;
    final maps = await db.query('watch_items', orderBy: 'createdAt DESC');
    return maps.map(WatchItem.fromMap).toList();
  }

  Future<void> insertAllItems(List<WatchItem> items) async {
    final db = await database;
    final batch = db.batch();
    for (final item in items) {
      // Insert without id so SQLite auto-assigns new ones
      final map = item.toMap()..remove('id');
      batch.insert('watch_items', map,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> clearAllItems() async {
    final db = await database;
    await db.delete('watch_items');
  }

  Future<List<WatchItem>> getItemsByStatus(String status) async {
    final db = await database;
    final maps = await db.query(
      'watch_items',
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
    final maps = await db.query(
      'watch_items',
      where: where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'createdAt DESC',
    );
    return maps.map(WatchItem.fromMap).toList();
  }

  // ── Stats ────────────────────────────────────────────────────────────────

  Future<int> getWatchedCount() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as cnt FROM watch_items WHERE status = 'Watched'",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTotalCount() async {
    final db = await database;
    final result = await db.rawQuery("SELECT COUNT(*) as cnt FROM watch_items");
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<double?> getAverageRating() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT AVG(rating) as avg FROM watch_items WHERE status = 'Watched'",
    );
    if (result.isEmpty || result.first['avg'] == null) return null;
    return (result.first['avg'] as num).toDouble();
  }

  Future<List<String>> getAllWatchedGenres() async {
    final db = await database;
    final maps = await db.query(
      'watch_items',
      columns: ['genres'],
      where: "status = 'Watched'",
    );
    return maps.map((m) => m['genres'] as String).toList();
  }
}
