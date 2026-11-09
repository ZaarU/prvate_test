import 'package:product_catalog/domain/models/product.dart';

enum CatalogStatus {
  waitingForSearch,
  loading,
  ready,
  loadingMore,
  loadFailed,
  loadMoreFailed,
}

class CatalogState {
  const CatalogState({
    required this.query,
    required this.status,
    this.products = const [],
    this.nextSkip = 0,
    this.hasMore = false,
    this.error,
  });

  final String query;
  final CatalogStatus status;
  final List<Product> products;
  final int nextSkip;
  final bool hasMore;
  final Object? error;
}
