import 'package:flutter/material.dart';

import 'catalog/catalog_screen.dart';
import 'catalog/dummy_json_product_repository.dart';
import 'catalog/product_repository.dart';

void main() {
  runApp(ProductCatalogApp(repository: DummyJsonProductRepository()));
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
