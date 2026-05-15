import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  LocalDatabase._privateConstructor();
  static final LocalDatabase instance = LocalDatabase._privateConstructor();

  Database? _database;

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

    return openDatabase(dbPath, readOnly: true);
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
}
