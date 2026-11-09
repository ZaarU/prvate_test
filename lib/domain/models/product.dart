class Product {
  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.rating,
    required this.thumbnail,
  });

  final int id;
  final String title;
  final String description;
  final double price;
  final double rating;
  final String thumbnail;
}

class ProductPage {
  ProductPage({
    required Iterable<Product> products,
    required this.total,
    required this.skip,
  }) : products = List.unmodifiable(products);

  final List<Product> products;
  final int total;
  final int skip;

  int get nextSkip => skip + products.length;
  bool get hasMore => products.isNotEmpty && nextSkip < total;
}
