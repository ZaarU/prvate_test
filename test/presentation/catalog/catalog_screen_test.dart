import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:product_catalog/domain/models/product.dart';
import 'package:product_catalog/domain/models/product_details.dart';
import 'package:product_catalog/domain/repositories/product_repository.dart';
import 'package:product_catalog/main.dart';

void main() {
  testWidgets('opens cold and warm deep links and returns to the catalog', (
    tester,
  ) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue =
        'productcatalog://app/products/42';
    addTearDown(
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
    );
    final repository = _CatalogRepository();
    await tester.pumpWidget(ProductCatalogApp(repository: repository));
    await tester.pumpAndSettle();
    expect(repository.detailRequests, [42]);
    expect(find.text('Detailed product 42'), findsOneWidget);

    final router = tester.widget<Router<Object>>(find.byType(Router<Object>));
    final provider =
        router.routeInformationProvider! as PlatformRouteInformationProvider;
    await provider.didPushRouteInformation(
      RouteInformation(uri: Uri.parse('productcatalog://app/products/7')),
    );
    await tester.pumpAndSettle();
    expect(repository.detailRequests, [42, 7]);
    expect(find.text('Detailed product 7'), findsOneWidget);
    expect(find.text('Detailed product 42'), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Product Catalog'), findsOneWidget);

    await provider.didPushRouteInformation(
      RouteInformation(uri: Uri.parse('productcatalog://app/products/invalid')),
    );
    await tester.pumpAndSettle();
    expect(repository.detailRequests, [42, 7]);
    expect(find.text('Product Catalog'), findsOneWidget);
  });

  testWidgets('opens details from both layouts and retries a failed load', (
    tester,
  ) async {
    final repository = _CatalogRepository()..failNextDetails = true;
    await tester.pumpWidget(ProductCatalogApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Product 2'));
    await tester.pumpAndSettle();
    expect(repository.detailRequests, [2]);
    expect(find.text('Could not load product details.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(repository.detailRequests, [2, 2]);
    expect(find.text('Detailed product 2'), findsOneWidget);
    expect(find.text('Full product description'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Show table'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Product 3'));
    await tester.pumpAndSettle();
    expect(repository.detailRequests, [2, 2, 3]);
    expect(find.text('Detailed product 3'), findsOneWidget);
    expect(repository.requests, [('', 0)]);
  });

  testWidgets('switches layouts and paginates the same search in table mode', (
    tester,
  ) async {
    final repository = _CatalogRepository();
    await tester.pumpWidget(ProductCatalogApp(repository: repository));
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
  final detailRequests = <int>[];
  bool failNextDetails = false;

  @override
  Future<ProductDetails> fetchById(int id) async {
    detailRequests.add(id);
    if (failNextDetails) {
      failNextDetails = false;
      throw Exception('Network error');
    }
    return ProductDetails(
      product: Product(
        id: id,
        title: 'Detailed product $id',
        description: 'Full product description',
        price: 12,
        rating: 4.5,
        thumbnail: 'https://example.invalid/product.png',
      ),
      category: 'electronics',
      sku: 'TEST-123',
      discountPercentage: 10,
      stock: 15,
      availability: 'In stock',
      weight: 1,
      dimensions: (width: 1, height: 2, depth: 3),
      minimumOrderQuantity: 1,
      warranty: '1 year warranty',
      shipping: 'Ships in 1 day',
      returnPolicy: '30 days return policy',
      tags: const ['electronics'],
      images: const [],
      reviews: const [],
      metadata: ProductMetadata(
        barcode: '123456789',
        qrCode: 'https://example.invalid/qr.png',
        createdAt: DateTime.utc(2025),
        updatedAt: DateTime.utc(2025),
      ),
    );
  }

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
          title: query.isEmpty ? 'Product $id' : '$query $id',
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
