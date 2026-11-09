import 'product.dart';

abstract interface class ProductRepository {
  Future<ProductPage> fetchPage({
    String query = '',
    int limit = 20,
    int skip = 0,
  });
}
