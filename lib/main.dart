import 'package:flutter/material.dart';

void main() {
  runApp(const ProductCatalogApp());
}

class ProductCatalogApp extends StatelessWidget {
  const ProductCatalogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Product Catalog',
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: Text('Product Catalog'))),
    );
  }
}
