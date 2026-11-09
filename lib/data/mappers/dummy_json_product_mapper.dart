import 'package:product_catalog/domain/models/product.dart';
import 'package:product_catalog/domain/models/product_details.dart';

Product productFromJson(Map<String, dynamic> json) => Product(
  id: json['id'] as int,
  title: json['title'] as String,
  description: json['description'] as String,
  price: (json['price'] as num).toDouble(),
  rating: (json['rating'] as num).toDouble(),
  thumbnail: json['thumbnail'] as String,
);

ProductDetails productDetailsFromJson(Map<String, dynamic> json) {
  final dimensions = json['dimensions'] as Map<String, dynamic>;
  final metadata = json['meta'] as Map<String, dynamic>;
  return ProductDetails(
    product: productFromJson(json),
    category: json['category'] as String,
    brand: json['brand'] as String?,
    sku: json['sku'] as String,
    discountPercentage: (json['discountPercentage'] as num).toDouble(),
    stock: json['stock'] as int,
    availability: json['availabilityStatus'] as String,
    weight: json['weight'] as num,
    dimensions: (
      width: dimensions['width'] as num,
      height: dimensions['height'] as num,
      depth: dimensions['depth'] as num,
    ),
    minimumOrderQuantity: json['minimumOrderQuantity'] as int,
    warranty: json['warrantyInformation'] as String,
    shipping: json['shippingInformation'] as String,
    returnPolicy: json['returnPolicy'] as String,
    tags: (json['tags'] as List).cast<String>(),
    images: (json['images'] as List).cast<String>(),
    reviews: (json['reviews'] as List).cast<Map<String, dynamic>>().map(
      _reviewFromJson,
    ),
    metadata: ProductMetadata(
      barcode: metadata['barcode'] as String,
      qrCode: metadata['qrCode'] as String,
      createdAt: DateTime.parse(metadata['createdAt'] as String),
      updatedAt: DateTime.parse(metadata['updatedAt'] as String),
    ),
  );
}

ProductReview _reviewFromJson(Map<String, dynamic> json) => ProductReview(
  rating: json['rating'] as int,
  comment: json['comment'] as String,
  date: DateTime.parse(json['date'] as String),
  reviewerName: json['reviewerName'] as String,
  reviewerEmail: json['reviewerEmail'] as String,
);
