import 'package:flutter/material.dart';

import 'package:product_catalog/data/local/product_cache.dart';
import 'package:product_catalog/data/repositories/dummy_json_product_repository.dart';
import 'package:product_catalog/domain/repositories/product_repository.dart';
import 'package:product_catalog/presentation/catalog/catalog_screen.dart';

void main() {
  runApp(
    ProductCatalogApp(repository: DummyJsonProductRepository(ProductCache())),
  );
}

class ProductCatalogApp extends StatelessWidget {
  const ProductCatalogApp({required this.repository, super.key});

  final ProductRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Product Catalog',
      debugShowCheckedModeBanner: false,
      home: CatalogScreen(repository: repository),
    );
  }
}
