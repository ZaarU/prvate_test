import 'package:flutter/material.dart';

import 'product.dart';
import 'product_card.dart';

class ProductTable extends StatelessWidget {
  const ProductTable({required this.products, super.key});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverList.builder(
      itemCount: products.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return ColoredBox(
            color: theme.colorScheme.surfaceContainerHigh,
            child: DefaultTextStyle.merge(
              style: theme.textTheme.labelMedium,
              child: const _TableRow(
                product: Text('Product'),
                price: Text('Price'),
                rating: Text('Rating'),
              ),
            ),
          );
        }

        final product = products[index - 1];
        final rating = product.rating.toStringAsFixed(1);
        return DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          child: _TableRow(
            product: Row(
              children: [
                SizedBox.square(
                  dimension: 40,
                  child: ProductThumbnail(url: product.thumbnail),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: theme.textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        product.description,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            price: Text(
              '\$${product.price.toStringAsFixed(2)}',
              textAlign: TextAlign.end,
            ),
            rating: Semantics(
              label: 'Rating $rating out of 5',
              excludeSemantics: true,
              child: Text(rating, textAlign: TextAlign.end),
            ),
          ),
        );
      },
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.product,
    required this.price,
    required this.rating,
  });

  final Widget product;
  final Widget price;
  final Widget rating;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 3, child: product),
          const SizedBox(width: 8),
          Expanded(
            child: Align(alignment: Alignment.centerRight, child: price),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(alignment: Alignment.centerRight, child: rating),
          ),
        ],
      ),
    );
  }
}
