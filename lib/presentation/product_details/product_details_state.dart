import 'package:product_catalog/domain/models/product_details.dart';

sealed class ProductDetailsState {
  const ProductDetailsState();
}

final class ProductDetailsInitial extends ProductDetailsState {
  const ProductDetailsInitial();
}

final class ProductDetailsLoading extends ProductDetailsState {
  const ProductDetailsLoading();
}

final class ProductDetailsLoaded extends ProductDetailsState {
  const ProductDetailsLoaded(this.details);

  final ProductDetails details;
}

final class ProductDetailsLoadFailed extends ProductDetailsState {
  const ProductDetailsLoadFailed(this.error);

  final Object error;
}
