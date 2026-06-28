import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/history_item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('qr_scanner_v2.db'); // Using v2 database name to ensure clean schema update
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Create scans table with precise fields
    await db.execute('''
      CREATE TABLE scans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        qr_content TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        scan_type TEXT NOT NULL,
        url TEXT NOT NULL,
        text TEXT NOT NULL,
        is_favorite INTEGER NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');

    // Create settings table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // Scan History CRUD Operations

  Future<int> insertScan(HistoryItem item) async {
    final db = await instance.database;
    return await db.insert('scans', item.toMap());
  }

  Future<List<HistoryItem>> getAllScans() async {
    final db = await instance.database;
    final result = await db.query('scans', orderBy: 'id DESC');
    return result.map((json) => HistoryItem.fromMap(json)).toList();
  }

  Future<List<HistoryItem>> searchScans(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'scans',
      where: 'qr_content LIKE ? OR url LIKE ? OR text LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'id DESC',
    );
    return result.map((json) => HistoryItem.fromMap(json)).toList();
  }

  Future<int> updateScan(HistoryItem item) async {
    final db = await instance.database;
    return await db.update(
      'scans',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteScan(int id) async {
    final db = await instance.database;
    return await db.delete(
      'scans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllScans() async {
    final db = await instance.database;
    return await db.delete('scans');
  }

  Future<HistoryItem?> getMostRecentScan() async {
    final db = await instance.database;
    final result = await db.query(
      'scans',
      orderBy: 'id DESC',
      limit: 1,
    );
    if (result.isNotEmpty) {
      return HistoryItem.fromMap(result.first);
    }
    return null;
  }

  // Settings Key-Value Operations

  Future<int> saveSetting(String key, String value) async {
    final db = await instance.database;
    return await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await instance.database;
    final maps = await db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  Future<void> close() async {
    final db = await _database;
    if (db != null) {
      await db.close();
    }
  }
}
