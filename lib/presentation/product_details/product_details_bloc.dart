import 'package:bloc/bloc.dart';

import 'package:product_catalog/domain/repositories/product_repository.dart';
import 'package:product_catalog/presentation/product_details/product_details_state.dart';

final class ProductDetailsRequested {
  const ProductDetailsRequested();
}

class ProductDetailsBloc
    extends Bloc<ProductDetailsRequested, ProductDetailsState> {
  ProductDetailsBloc(this._repository, this._id)
    : super(const ProductDetailsInitial()) {
    on<ProductDetailsRequested>(_onRequested);
    add(const ProductDetailsRequested());
  }

  final int _id;
  final ProductRepository _repository;

  Future<void> _onRequested(
    ProductDetailsRequested event,
    Emitter<ProductDetailsState> emit,
  ) async {
    if (isClosed ||
        state is ProductDetailsLoading ||
        state is ProductDetailsLoaded) {
      return;
    }

    emit(const ProductDetailsLoading());
    try {
      final details = await _repository.fetchById(_id);
      if (!emit.isDone) emit(ProductDetailsLoaded(details));
    } catch (error) {
      if (!emit.isDone) emit(ProductDetailsLoadFailed(error));
    }
  }
}
