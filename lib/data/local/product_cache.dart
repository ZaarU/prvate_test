import 'dart:convert';

import 'package:sqflite/sqflite.dart';

class ProductCache {
  Database? _database;

  Future<Database> _open() async {
    return _database ??= await openDatabase(
      '${await getDatabasesPath()}/product_catalog.db',
      version: 2,
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
            title TEXT NOT NULL DEFAULT '',
            description TEXT NOT NULL DEFAULT '',
            price REAL NOT NULL DEFAULT 0,
            rating REAL NOT NULL DEFAULT 0,
            thumbnail TEXT NOT NULL DEFAULT '',
            payload TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _migrateProductColumns(db);
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
    final cached = _decode(rows);
    if (cached != null || query.isEmpty) return cached;
    return db.transaction((txn) => _searchProducts(txn, query, limit, skip));
  }

  Future<Map<String, dynamic>> _searchProducts(
    Transaction txn,
    String query,
    int limit,
    int skip,
  ) async {
    final cachedPages = await txn.query(
      'catalog_pages',
      columns: ['page_skip', 'payload'],
      where: 'query = ? AND page_limit = ? AND page_skip < ?',
      whereArgs: [query, limit, skip],
      orderBy: 'page_skip ASC',
    );
    final seenIds = <int>{};
    var cachedCount = 0;
    for (final page in cachedPages) {
      if (page['page_skip'] != cachedCount) break;
      final products = _decodePayload(page['payload'])['products'] as List;
      final precedingProducts = products.take(skip - cachedCount);
      cachedCount += precedingProducts.length;
      seenIds.addAll(precedingProducts.map((product) => product['id'] as int));
    }

    // Continue after the exact cached pages without returning their IDs again.
    final exclusions = seenIds.isEmpty
        ? ''
        : " AND id NOT IN (${seenIds.map((_) => '?').join(', ')})";
    final where = "title LIKE ? ESCAPE '\\'$exclusions";
    var args = <Object>[_containsPattern(query), ...seenIds];
    var total = await _countProducts(txn, where, args);
    if (total == 0 && RegExp(r'^[a-z]{3,}[^s]s$').hasMatch(query)) {
      final singular = query.substring(0, query.length - 1);
      args = [_containsPattern(singular), ...seenIds];
      total = await _countProducts(txn, where, args);
    }

    final rows = await txn.query(
      'products',
      columns: ['id', 'title', 'description', 'price', 'rating', 'thumbnail'],
      where: where,
      whereArgs: args,
      orderBy: 'id ASC',
      limit: limit,
      offset: skip - cachedCount,
    );
    return {'products': rows, 'total': cachedCount + total, 'skip': skip};
  }

  Future<int> _countProducts(
    Transaction txn,
    String where,
    List<Object> args,
  ) async {
    final rows = await txn.rawQuery(
      'SELECT COUNT(*) FROM products WHERE $where',
      args,
    );
    return Sqflite.firstIntValue(rows)!;
  }

  String _containsPattern(String value) {
    final escaped = value.replaceAllMapped(
      RegExp(r'[\\%_]'),
      (match) => '\\${match[0]}',
    );
    return '%$escaped%';
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
    ..._productColumns(product),
    'payload': jsonEncode(product),
  };

  Map<String, Object?> _productColumns(Map<String, dynamic> product) => {
    'title': product['title'] as String,
    'description': product['description'] as String,
    'price': product['price'] as num,
    'rating': product['rating'] as num,
    'thumbnail': product['thumbnail'] as String,
  };

  Future<void> _migrateProductColumns(Database db) async {
    await db.execute(
      "ALTER TABLE products ADD COLUMN title TEXT NOT NULL DEFAULT ''",
    );
    await db.execute(
      "ALTER TABLE products ADD COLUMN description TEXT NOT NULL DEFAULT ''",
    );
    await db.execute(
      'ALTER TABLE products ADD COLUMN price REAL NOT NULL DEFAULT 0',
    );
    await db.execute(
      'ALTER TABLE products ADD COLUMN rating REAL NOT NULL DEFAULT 0',
    );
    await db.execute(
      "ALTER TABLE products ADD COLUMN thumbnail TEXT NOT NULL DEFAULT ''",
    );
    final rows = await db.query('products', columns: ['id', 'payload']);
    final batch = db.batch();
    for (final row in rows) {
      batch.update(
        'products',
        _productColumns(_decodePayload(row['payload'])),
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
    await batch.commit(noResult: true);
  }

  Map<String, dynamic>? _decode(List<Map<String, Object?>> rows) {
    if (rows.isEmpty) return null;
    return _decodePayload(rows.single['payload']);
  }

  Map<String, dynamic> _decodePayload(Object? payload) =>
      jsonDecode(payload as String) as Map<String, dynamic>;
}
