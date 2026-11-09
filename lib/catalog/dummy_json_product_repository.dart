import 'package:dio/dio.dart';

import 'dummy_json_dio_config.dart';
import 'product.dart';
import 'product_repository.dart';

class DummyJsonProductRepository implements ProductRepository {
  DummyJsonProductRepository({Dio? dio})
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
    final response = await _dio.get<Map<String, dynamic>>(
      search.isEmpty ? '/products' : '/products/search',
      queryParameters: {
        if (search.isNotEmpty) 'q': search,
        'limit': limit,
        'skip': skip,
      },
    );

    final data = response.data;
    if (data == null) {
      throw const FormatException('Missing products response body');
    }

    final products = (data['products'] as List).cast<Map<String, dynamic>>();
    return ProductPage(
      products: products.map(Product.fromJson),
      total: data['total'] as int,
      skip: data['skip'] as int,
    );
  }
}
