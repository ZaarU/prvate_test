import 'package:flutter/material.dart';

import 'package:product_catalog/domain/repositories/product_repository.dart';
import 'package:product_catalog/presentation/catalog/catalog_screen.dart';
import 'package:product_catalog/presentation/navigation/catalog_route.dart';
import 'package:product_catalog/presentation/product_details/product_details_screen.dart';

class CatalogRouterDelegate extends RouterDelegate<CatalogRoute>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<CatalogRoute> {
  CatalogRouterDelegate(this._repository);

  final ProductRepository _repository;
  CatalogRoute _route = const CatalogRoute();

  @override
  final navigatorKey = GlobalKey<NavigatorState>();

  @override
  CatalogRoute get currentConfiguration => _route;

  @override
  Future<void> setNewRoutePath(CatalogRoute configuration) async {
    _route = configuration;
  }

  void _openProduct(int id) {
    if (_route.productId == id) return;
    _route = CatalogRoute(productId: id);
    notifyListeners();
  }

  void _onPageRemoved(Page<Object?> page) {
    final id = _route.productId;
    if (id != null && page.key == ValueKey(id)) {
      _route = const CatalogRoute();
      notifyListeners();
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = _route.productId;
    return Navigator(
      key: navigatorKey,
      pages: [
        MaterialPage<void>(
          key: const ValueKey('catalog'),
          name: '/',
          child: CatalogScreen(
            repository: _repository,
            onProductTap: _openProduct,
          ),
        ),
        if (id != null)
          MaterialPage<void>(
            key: ValueKey(id),
            name: '/products/$id',
            child: ProductDetailsScreen(id: id, repository: _repository),
          ),
      ],
      onDidRemovePage: _onPageRemoved,
    );
  }
}
