import 'dart:convert';

import 'package:sqflite/sqflite.dart';

class ProductCache {
  Database? _database;

  Future<Database> _open() async {
    return _database ??= await openDatabase(
      '${await getDatabasesPath()}/product_catalog.db',
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE catalog_pages (
            query TEXT NOT NULL,
            page_limit INTEGER NOT NULL,
            page_skip INTEGER NOT NULL,
            payload TEXT NOT NULL,
            PRIMARY KEY (query, page_limit, page_skip)
          )
        ''');
        await db.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY,
            payload TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<Map<String, dynamic>?> readPage(
    String query,
    int limit,
    int skip,
  ) async {
    final db = await _open();
    final rows = await db.query(
      'catalog_pages',
      columns: ['payload'],
      where: 'query = ? AND page_limit = ? AND page_skip = ?',
      whereArgs: [query, limit, skip],
    );
    return _decode(rows);
  }

  Future<Map<String, dynamic>?> readProduct(int id) async {
    final db = await _open();
    final rows = await db.query(
      'products',
      columns: ['payload'],
      where: 'id = ?',
      whereArgs: [id],
    );
    return _decode(rows);
  }

  Future<void> savePage(
    String query,
    int limit,
    int skip,
    Map<String, dynamic> payload,
  ) async {
    final db = await _open();
    final batch = db.batch();
    batch.insert('catalog_pages', {
      'query': query,
      'page_limit': limit,
      'page_skip': skip,
      'payload': jsonEncode(payload),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    final products = (payload['products'] as List).cast<Map<String, dynamic>>();
    for (final product in products) {
      batch.insert(
        'products',
        _productRow(product),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> saveProduct(Map<String, dynamic> product) async {
    final db = await _open();
    await db.insert(
      'products',
      _productRow(product),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Map<String, Object?> _productRow(Map<String, dynamic> product) => {
    'id': product['id'] as int,
    'payload': jsonEncode(product),
  };

  Map<String, dynamic>? _decode(List<Map<String, Object?>> rows) {
    if (rows.isEmpty) return null;
    return jsonDecode(rows.single['payload'] as String) as Map<String, dynamic>;
  }
}
