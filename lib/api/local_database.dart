import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  LocalDatabase._privateConstructor();
  static final LocalDatabase instance = LocalDatabase._privateConstructor();

  Database? _database;
  static const int _version = 2;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDir.path, 'custom.db');
    final dbFile = File(dbPath);

    if (!await dbFile.exists()) {
      final data = await rootBundle.load('assets/db/custom.db');
      await dbFile.writeAsBytes(data.buffer.asUint8List());
    }

    return openDatabase(
      dbPath,
      version: _version,
      readOnly: false,
      onCreate: (db, version) async {
        await _createStockHistoryTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createStockHistoryTable(db);
        }
      },
      onOpen: (db) async {
        await _ensureStockHistoryTable(db);
      },
    );
  }

  Future<void> _createStockHistoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stock_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ticker TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        open REAL NOT NULL,
        high REAL NOT NULL,
        low REAL NOT NULL,
        close REAL NOT NULL,
        volume INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        UNIQUE(ticker, timestamp)
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_stock_history_ticker ON stock_history(ticker)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_stock_history_timestamp ON stock_history(ticker, timestamp)',
    );
  }

  Future<void> _ensureStockHistoryTable(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='stock_history'",
    );
    if (tables.isEmpty) {
      await _createStockHistoryTable(db);
    }
  }

  Future<List<Map<String, dynamic>>> queryStocks({String search = ''}) async {
    final db = await database;
    if (search.isEmpty) {
      return db.query('stocks', orderBy: 'ticker ASC');
    }

    final query = '%${search.toLowerCase()}%';
    return db.rawQuery(
      'SELECT * FROM stocks WHERE LOWER(ticker) LIKE ? OR LOWER(name) LIKE ? OR LOWER(name_ar) LIKE ? ORDER BY ticker ASC',
      [query, query, query],
    );
  }

  Future<Map<String, dynamic>?> getStockDetail(String ticker) async {
    final db = await database;
    final rows = await db.query('stocks', where: 'LOWER(ticker) = LOWER(?)', whereArgs: [ticker], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<Map<String, dynamic>?> getStockRecommendation(String ticker) async {
    final db = await database;
    final rows = await db.query('python_recommendations', where: 'LOWER(ticker) = LOWER(?)', whereArgs: [ticker], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> getMarketIndices() async {
    final db = await database;
    return db.query('market_indices', orderBy: 'symbol ASC');
  }

  Future<List<Map<String, dynamic>>> getGoldPrices() async {
    final db = await database;
    return db.query('gold_prices', orderBy: 'karat ASC');
  }

  Future<List<Map<String, dynamic>>> getCurrencyRates() async {
    final db = await database;
    return db.query('currency_rates', orderBy: 'code ASC');
  }

  // ===========================================================================
  // Stock History - Local Historical Data
  // ===========================================================================

  Future<void> insertStockHistory(String ticker, List<Map<String, dynamic>> data) async {
    final db = await database;
    final batch = db.batch();
    for (final item in data) {
      batch.insert(
        'stock_history',
        {
          'ticker': ticker.toUpperCase(),
          'timestamp': item['timestamp'] as int,
          'open': (item['open'] as num).toDouble(),
          'high': (item['high'] as num).toDouble(),
          'low': (item['low'] as num).toDouble(),
          'close': (item['close'] as num).toDouble(),
          'volume': (item['volume'] as num?)?.toInt() ?? 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    debugPrint('[DB] Inserted ${data.length} history records for $ticker');
  }

  Future<List<Map<String, dynamic>>> getStockHistory(String ticker, {int days = 30}) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch ~/ 1000;
    return db.query(
      'stock_history',
      where: 'ticker = ? AND timestamp >= ?',
      whereArgs: [ticker.toUpperCase(), cutoff],
      orderBy: 'timestamp ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllStockHistory(String ticker) async {
    final db = await database;
    return db.query(
      'stock_history',
      where: 'ticker = ?',
      whereArgs: [ticker.toUpperCase()],
      orderBy: 'timestamp ASC',
    );
  }

  Future<DateTime?> getLastHistoryTimestamp(String ticker) async {
    final db = await database;
    final rows = await db.query(
      'stock_history',
      where: 'ticker = ?',
      whereArgs: [ticker.toUpperCase()],
      orderBy: 'timestamp DESC',
      limit: 1,
      columns: ['timestamp'],
    );
    if (rows.isEmpty) return null;
    return DateTime.fromMillisecondsSinceEpoch((rows.first['timestamp'] as int) * 1000);
  }

  Future<int> getStockHistoryCount(String ticker) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM stock_history WHERE ticker = ?',
      [ticker.toUpperCase()],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> clearStockHistory(String ticker) async {
    final db = await database;
    await db.delete('stock_history', where: 'ticker = ?', whereArgs: [ticker.toUpperCase()]);
    debugPrint('[DB] Cleared history for $ticker');
  }

  Future<void> clearAllStockHistory() async {
    final db = await database;
    await db.delete('stock_history');
    debugPrint('[DB] Cleared all stock history');
  }

  Future<bool> shouldSyncHistory(String ticker, {int maxAgeHours = 4}) async {
    final lastTs = await getLastHistoryTimestamp(ticker);
    if (lastTs == null) return true;
    final age = DateTime.now().difference(lastTs);
    return age.inHours >= maxAgeHours;
  }
}
