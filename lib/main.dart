import 'package:flutter/material.dart';

import 'package:product_catalog/data/local/product_cache.dart';
import 'package:product_catalog/data/repositories/dummy_json_product_repository.dart';
import 'package:product_catalog/domain/repositories/product_repository.dart';
import 'package:product_catalog/presentation/navigation/catalog_route.dart';
import 'package:product_catalog/presentation/navigation/catalog_router_delegate.dart';

void main() {
  runApp(
    ProductCatalogApp(repository: DummyJsonProductRepository(ProductCache())),
  );
}

class ProductCatalogApp extends StatefulWidget {
  const ProductCatalogApp({required this.repository, super.key});

  final ProductRepository repository;

  @override
  State<ProductCatalogApp> createState() => _ProductCatalogAppState();
}

class _ProductCatalogAppState extends State<ProductCatalogApp> {
  late final _router = CatalogRouterDelegate(widget.repository);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Product Catalog',
      debugShowCheckedModeBanner: false,
      routeInformationParser: const CatalogRouteParser(),
      routerDelegate: _router,
    );
  }
}
