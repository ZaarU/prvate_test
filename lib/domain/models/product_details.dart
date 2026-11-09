import 'package:product_catalog/domain/models/product.dart';

class ProductDetails {
  ProductDetails({
    required this.product,
    required this.category,
    this.brand,
    required this.sku,
    required this.discountPercentage,
    required this.stock,
    required this.availability,
    required this.weight,
    required this.dimensions,
    required this.minimumOrderQuantity,
    required this.warranty,
    required this.shipping,
    required this.returnPolicy,
    required Iterable<String> tags,
    required Iterable<String> images,
    required Iterable<ProductReview> reviews,
    required this.metadata,
  }) : tags = List.unmodifiable(tags),
       images = List.unmodifiable(images),
       reviews = List.unmodifiable(reviews);

  final Product product;
  final String category;
  final String? brand;
  final String sku;
  final double discountPercentage;
  final int stock;
  final String availability;
  final num weight;
  final ({num width, num height, num depth}) dimensions;
  final int minimumOrderQuantity;
  final String warranty;
  final String shipping;
  final String returnPolicy;
  final List<String> tags;
  final List<String> images;
  final List<ProductReview> reviews;
  final ProductMetadata metadata;
}

class ProductReview {
  const ProductReview({
    required this.rating,
    required this.comment,
    required this.date,
    required this.reviewerName,
    required this.reviewerEmail,
  });

  final int rating;
  final String comment;
  final DateTime date;
  final String reviewerName;
  final String reviewerEmail;
}

class ProductMetadata {
  const ProductMetadata({
    required this.barcode,
    required this.qrCode,
    required this.createdAt,
    required this.updatedAt,
  });

  final String barcode;
  final String qrCode;
  final DateTime createdAt;
  final DateTime updatedAt;
}
