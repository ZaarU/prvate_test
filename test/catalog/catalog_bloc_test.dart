import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:product_catalog/catalog/catalog_bloc.dart';
import 'package:product_catalog/catalog/catalog_state.dart';
import 'package:product_catalog/catalog/product.dart';
import 'package:product_catalog/catalog/product_repository.dart';

void main() {
  testWidgets('debounces search and discards an older response', (
    tester,
  ) async {
    final repository = _ControlledRepository();
    final bloc = CatalogBloc(repository);
    addTearDown(bloc.close);
    await tester.pump();
    expect(repository.requests.single.query, '');

    bloc.add(const CatalogSearchChanged('p'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(repository.requests, hasLength(1));

    bloc.add(const CatalogSearchChanged('ph'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    bloc.add(const CatalogSearchChanged('phone'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 299));
    expect(repository.requests, hasLength(1));
    await tester.pump(const Duration(milliseconds: 1));
    expect(repository.requests.last.query, 'phone');

    repository.requests.last.complete(2);
    await tester.pump();
    repository.requests.first.complete(1);
    await tester.pump();
    expect(bloc.state.query, 'phone');
    expect(bloc.state.products.single.id, 2);

    bloc.add(const CatalogSearchChanged('p'));
    await tester.pump();
    expect(repository.requests, hasLength(3));
    expect(repository.requests.last.query, '');
    expect(repository.requests.last.skip, 0);
    repository.requests.last.complete(1);
    await tester.pump();
    expect(bloc.state.products.single.id, 1);
  });

  testWidgets('retries the failed page and stops at the end', (tester) async {
    final repository = _ControlledRepository();
    final bloc = CatalogBloc(repository);
    addTearDown(bloc.close);
    await tester.pump();
    repository.requests.single.complete(1, total: 2);
    await tester.pump();

    bloc
      ..add(const CatalogNextPageRequested())
      ..add(const CatalogNextPageRequested());
    await tester.pump();
    expect(repository.requests, hasLength(2));
    expect(repository.requests.last.skip, 1);
    repository.requests.last.result.completeError(Exception('network error'));
    await tester.pump();
    expect(bloc.state.status, CatalogStatus.loadMoreFailed);
    expect(bloc.state.products.single.id, 1);

    bloc.add(const CatalogRetryRequested());
    await tester.pump();
    expect(repository.requests, hasLength(3));
    expect(repository.requests.last.skip, 1);
    repository.requests.last.complete(2, total: 2);
    await tester.pump();
    expect(bloc.state.products.map((product) => product.id), [1, 2]);
    expect(bloc.state.hasMore, isFalse);

    bloc.add(const CatalogNextPageRequested());
    await tester.pump();
    expect(repository.requests, hasLength(3));
  });
}

class _ControlledRepository implements ProductRepository {
  final requests = <_Request>[];

  @override
  Future<ProductPage> fetchPage({
    String query = '',
    int limit = 20,
    int skip = 0,
  }) {
    final request = _Request(query, skip);
    requests.add(request);
    return request.result.future;
  }
}

class _Request {
  _Request(this.query, this.skip);

  final String query;
  final int skip;
  final result = Completer<ProductPage>();

  void complete(int id, {int total = 1}) {
    result.complete(
      ProductPage(
        products: [
          Product(
            id: id,
            title: 'Product $id',
            description: '',
            price: 1,
            rating: 5,
            thumbnail: '',
          ),
        ],
        total: total,
        skip: skip,
      ),
    );
  }
}
