import 'dart:async';

import 'package:flutter/material.dart';

import 'package:product_catalog/domain/models/product_details.dart';
import 'package:product_catalog/domain/repositories/product_repository.dart';
import 'package:product_catalog/presentation/product_details/product_details_bloc.dart';
import 'package:product_catalog/presentation/product_details/product_details_state.dart';
import 'package:product_catalog/presentation/widgets/product_thumbnail.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({
    required this.id,
    required this.repository,
    super.key,
  });

  final int id;
  final ProductRepository repository;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late final ProductDetailsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = ProductDetailsBloc(widget.repository, widget.id);
  }

  @override
  void dispose() {
    unawaited(_bloc.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product details')),
      body: SafeArea(
        top: false,
        child: StreamBuilder<ProductDetailsState>(
          stream: _bloc.stream,
          initialData: _bloc.state,
          builder: (context, snapshot) => switch (snapshot.requireData) {
            ProductDetailsInitial() || ProductDetailsLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            ProductDetailsLoadFailed() => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not load product details.'),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => _bloc.add(const ProductDetailsRequested()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            ProductDetailsLoaded(:final details) => _ProductDetailsContent(
              details: details,
            ),
          },
        ),
      ),
    );
  }
}

class _ProductDetailsContent extends StatelessWidget {
  const _ProductDetailsContent({required this.details});

  final ProductDetails details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    final product = details.product;
    final dimensions = details.dimensions;
    final metadata = details.metadata;
    final images = details.images.isEmpty
        ? [product.thumbnail]
        : details.images;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (images.length == 1)
                SizedBox(
                  height: 220,
                  child: ProductThumbnail(url: images.first),
                )
              else
                SizedBox(
                  height: 220,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) => SizedBox(
                      width: 220,
                      child: ProductThumbnail(url: images[index]),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(product.title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(product.description),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium,
                  ),
                  Text('Rating ${product.rating.toStringAsFixed(2)} / 5'),
                  if (details.discountPercentage > 0)
                    Text('${details.discountPercentage}% off'),
                ],
              ),
              _DetailsSection(
                title: 'Specifications',
                entries: [
                  ('Product ID', '${product.id}'),
                  ('Category', details.category),
                  if (details.brand case final brand?) ('Brand', brand),
                  ('SKU', details.sku),
                  ('Weight', '${details.weight}'),
                  (
                    'Dimensions (W × H × D)',
                    '${dimensions.width} × ${dimensions.height} × ${dimensions.depth}',
                  ),
                  if (details.tags.isNotEmpty)
                    ('Tags', details.tags.join(', ')),
                ],
              ),
              _DetailsSection(
                title: 'Availability and policies',
                entries: [
                  ('Availability', details.availability),
                  ('In stock', '${details.stock}'),
                  ('Minimum order', '${details.minimumOrderQuantity}'),
                  ('Shipping', details.shipping),
                  ('Warranty', details.warranty),
                  ('Returns', details.returnPolicy),
                ],
              ),
              const SizedBox(height: 24),
              Text('Reviews', style: theme.textTheme.titleLarge),
              if (details.reviews.isEmpty) const Text('No reviews yet.'),
              for (final review in details.reviews)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${review.reviewerName} · ${review.rating}/5',
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        '${localizations.formatMediumDate(review.date.toLocal())}'
                        ' · ${review.reviewerEmail}',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(review.comment),
                    ],
                  ),
                ),
              _DetailsSection(
                title: 'Product identifiers',
                entries: [
                  ('Barcode', metadata.barcode),
                  (
                    'Created',
                    localizations.formatMediumDate(metadata.createdAt),
                  ),
                  (
                    'Updated',
                    localizations.formatMediumDate(metadata.updatedAt),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Semantics(
                  image: true,
                  label: 'Product QR code',
                  child: SizedBox.square(
                    dimension: 88,
                    child: ProductThumbnail(url: metadata.qrCode),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({required this.title, required this.entries});

  final String title;
  final List<(String, String)> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          for (final (label, value) in entries)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$label: ',
                      style: theme.textTheme.titleSmall,
                    ),
                    TextSpan(text: value),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
