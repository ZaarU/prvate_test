import 'package:product_catalog/domain/models/product.dart';
import 'package:product_catalog/domain/models/product_details.dart';

abstract interface class ProductRepository {
  Future<ProductPage> fetchPage({
    String query = '',
    int limit = 20,
    int skip = 0,
  });

  Future<ProductDetails> fetchById(int id);
}
