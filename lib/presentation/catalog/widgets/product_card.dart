import 'package:flutter/material.dart';

import 'package:product_catalog/domain/models/product.dart';
import 'package:product_catalog/presentation/widgets/product_thumbnail.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({required this.product, required this.onTap, super.key});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rating = product.rating.toStringAsFixed(1);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ColoredBox(
                color: theme.colorScheme.surfaceContainerLow,
                child: ProductThumbnail(url: product.thumbnail),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: theme.textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: theme.textTheme.titleSmall,
                      ),
                      Semantics(
                        label: 'Rating $rating out of 5',
                        excludeSemantics: true,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 16),
                            const SizedBox(width: 2),
                            Text(rating, style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
