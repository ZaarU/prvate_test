import 'dart:async';

import 'package:bloc/bloc.dart';

import 'catalog_state.dart';
import 'product.dart';
import 'product_repository.dart';

sealed class CatalogEvent {
  const CatalogEvent();
}

final class CatalogSearchChanged extends CatalogEvent {
  const CatalogSearchChanged(this.text);

  final String text;
}

final class CatalogNextPageRequested extends CatalogEvent {
  const CatalogNextPageRequested();
}

final class CatalogRetryRequested extends CatalogEvent {
  const CatalogRetryRequested();
}

final class _FirstPageRequested extends CatalogEvent {
  const _FirstPageRequested(this.generation);

  final int generation;
}

class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  CatalogBloc(this._repository)
    : super(const CatalogState(query: '', status: CatalogStatus.loading)) {
    on<CatalogSearchChanged>(_onSearchChanged);
    on<_FirstPageRequested>(_onFirstPageRequested);
    on<CatalogNextPageRequested>(_onNextPageRequested);
    on<CatalogRetryRequested>(_onRetryRequested);
    add(const _FirstPageRequested(0));
  }

  final ProductRepository _repository;
  Timer? _searchTimer;
  int _generation = 0;

  Future<void> _onSearchChanged(
    CatalogSearchChanged event,
    Emitter<CatalogState> emit,
  ) async {
    if (isClosed) return;
    final text = event.text.trim();
    final query = text.runes.length >= 2 ? text : '';
    if (query == state.query) return;

    _searchTimer?.cancel();
    final generation = ++_generation;
    if (query.isEmpty) {
      await _fetchPage(emit, query: query);
      return;
    }
    emit(CatalogState(query: query, status: CatalogStatus.waitingForSearch));
    _searchTimer = Timer(const Duration(milliseconds: 300), () {
      if (!isClosed) add(_FirstPageRequested(generation));
    });
  }

  Future<void> _onFirstPageRequested(
    _FirstPageRequested event,
    Emitter<CatalogState> emit,
  ) async {
    if (event.generation != _generation) return;
    await _fetchPage(emit);
  }

  Future<void> _onNextPageRequested(
    CatalogNextPageRequested event,
    Emitter<CatalogState> emit,
  ) async {
    if (state.status != CatalogStatus.ready || !state.hasMore) return;
    await _fetchPage(emit, append: true);
  }

  Future<void> _onRetryRequested(
    CatalogRetryRequested event,
    Emitter<CatalogState> emit,
  ) async {
    switch (state.status) {
      case CatalogStatus.loadFailed:
        await _fetchPage(emit);
      case CatalogStatus.loadMoreFailed:
        await _fetchPage(emit, append: true);
      default:
        break;
    }
  }

  Future<void> _fetchPage(
    Emitter<CatalogState> emit, {
    bool append = false,
    String? query,
  }) async {
    if (isClosed) return;
    final generation = _generation;
    final previous = state;
    final activeQuery = query ?? previous.query;
    final products = append ? previous.products : const <Product>[];
    final skip = append ? previous.nextSkip : 0;
    emit(
      CatalogState(
        query: activeQuery,
        status: append ? CatalogStatus.loadingMore : CatalogStatus.loading,
        products: products,
        nextSkip: skip,
        hasMore: append && previous.hasMore,
      ),
    );

    final ProductPage page;
    try {
      page = await _repository.fetchPage(query: activeQuery, skip: skip);
    } catch (error) {
      if (emit.isDone || generation != _generation) return;
      emit(
        CatalogState(
          query: activeQuery,
          status: append
              ? CatalogStatus.loadMoreFailed
              : CatalogStatus.loadFailed,
          products: products,
          nextSkip: skip,
          hasMore: append && previous.hasMore,
          error: error,
        ),
      );
      return;
    }

    if (emit.isDone || generation != _generation) return;
    emit(
      CatalogState(
        query: activeQuery,
        status: CatalogStatus.ready,
        products: append
            ? List.unmodifiable([...products, ...page.products])
            : page.products,
        nextSkip: page.nextSkip,
        hasMore: page.hasMore,
      ),
    );
  }

  @override
  Future<void> close() {
    _searchTimer?.cancel();
    _generation++;
    return super.close();
  }
}
