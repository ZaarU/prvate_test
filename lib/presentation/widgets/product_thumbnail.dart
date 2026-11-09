import 'package:flutter/material.dart';

class ProductThumbnail extends StatelessWidget {
  const ProductThumbnail({required this.url, super.key});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.image_not_supported_outlined),
    );
  }
}
