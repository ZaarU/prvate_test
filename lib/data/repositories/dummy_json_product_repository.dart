import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';

import 'package:product_catalog/data/local/product_cache.dart';
import 'package:product_catalog/data/mappers/dummy_json_product_mapper.dart';
import 'package:product_catalog/data/network/dummy_json_dio_config.dart';
import 'package:product_catalog/domain/models/product.dart';
import 'package:product_catalog/domain/models/product_details.dart';
import 'package:product_catalog/domain/repositories/product_repository.dart';

class DummyJsonProductRepository implements ProductRepository {
  DummyJsonProductRepository(this._cache, {Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: dummyJsonBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
            ),
          );

  final Dio _dio;
  final ProductCache _cache;

  @override
  Future<ProductDetails> fetchById(int id) => _fetch(
    path: '/products/$id',
    parse: productDetailsFromJson,
    readCache: () => _cache.readProduct(id),
    writeCache: _cache.saveProduct,
  );

  @override
  Future<ProductPage> fetchPage({
    String query = '',
    int limit = 20,
    int skip = 0,
  }) async {
    if (limit < 1) {
      throw RangeError.range(limit, 1, null, 'limit');
    }
    RangeError.checkNotNegative(skip, 'skip');

    final search = query.trim();
    final cacheQuery = search.toLowerCase();
    return _fetch(
      path: search.isEmpty ? '/products' : '/products/search',
      queryParameters: {
        if (search.isNotEmpty) 'q': search,
        'limit': limit,
        'skip': skip,
      },
      parse: _parsePage,
      readCache: () => _cache.readPage(cacheQuery, limit, skip),
      writeCache: (data) => _cache.savePage(cacheQuery, limit, skip, data),
    );
  }

  Future<T> _fetch<T>({
    required String path,
    Map<String, Object>? queryParameters,
    required T Function(Map<String, dynamic>) parse,
    required Future<Map<String, dynamic>?> Function() readCache,
    required Future<void> Function(Map<String, dynamic>) writeCache,
  }) async {
    final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
      );
    } on DioException catch (error) {
      if (!_canUseCache(error)) rethrow;
      final cached = await _tryCache(readCache);
      if (cached == null) rethrow;
      return parse(cached);
    }

    final data = response.data;
    if (data == null) {
      throw const FormatException('Missing DummyJSON response body');
    }
    final result = parse(data);
    await _tryCache(() => writeCache(data));
    return result;
  }

  ProductPage _parsePage(Map<String, dynamic> data) {
    final products = (data['products'] as List).cast<Map<String, dynamic>>();
    return ProductPage(
      products: products.map(productFromJson),
      total: data['total'] as int,
      skip: data['skip'] as int,
    );
  }

  bool _canUseCache(DioException error) => switch (error.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => true,
    DioExceptionType.badResponse => (error.response?.statusCode ?? 0) >= 500,
    DioExceptionType.unknown => error.error is SocketException,
    _ => false,
  };

  Future<T?> _tryCache<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on DatabaseException catch (error, stackTrace) {
      developer.log(
        'Product cache operation failed',
        name: 'ProductCache',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
