import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:product_catalog/catalog/catalog_screen.dart';
import 'package:product_catalog/catalog/product.dart';
import 'package:product_catalog/catalog/product_repository.dart';

void main() {
  testWidgets('switches layouts and paginates the same search in table mode', (
    tester,
  ) async {
    final repository = _CatalogRepository();
    await tester.pumpWidget(
      MaterialApp(home: CatalogScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText), 'phone');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('phone 1'), findsOneWidget);
    expect(repository.requests, [('', 0), ('phone', 0)]);

    await tester.tap(find.byTooltip('Show table'));
    await tester.pumpAndSettle();
    expect(find.text('Price'), findsOneWidget);
    expect(find.text('Rating'), findsOneWidget);
    expect(find.text('phone 1'), findsOneWidget);
    expect(repository.requests, [('', 0), ('phone', 0)]);

    await tester.scrollUntilVisible(
      find.text('phone 21'),
      300,
      scrollable: find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(Scrollable),
      ),
    );
    expect(repository.requests, [('', 0), ('phone', 0), ('phone', 20)]);

    await tester.tap(find.byTooltip('Show grid'));
    await tester.pumpAndSettle();
    expect(find.text('Rating'), findsNothing);
    expect(find.text('phone 1'), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'phone',
    );
    expect(repository.requests, [('', 0), ('phone', 0), ('phone', 20)]);
  });
}

class _CatalogRepository implements ProductRepository {
  final requests = <(String, int)>[];

  @override
  Future<ProductPage> fetchPage({
    String query = '',
    int limit = 20,
    int skip = 0,
  }) async {
    requests.add((query, skip));
    return ProductPage(
      products: List.generate(skip == 0 ? 20 : 1, (index) {
        final id = skip + index + 1;
        return Product(
          id: id,
          title: '$query $id',
          description: 'Product description',
          price: 12,
          rating: 4.5,
          thumbnail: 'https://example.invalid/product.png',
        );
      }),
      total: 21,
      skip: skip,
    );
  }
}
