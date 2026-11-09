import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class CatalogRoute {
  const CatalogRoute({this.productId});

  final int? productId;
}

class CatalogRouteParser extends RouteInformationParser<CatalogRoute> {
  const CatalogRouteParser();

  @override
  Future<CatalogRoute> parseRouteInformation(
    RouteInformation routeInformation,
  ) {
    final uri = routeInformation.uri;
    final isInternal = !uri.hasScheme && !uri.hasAuthority;
    final isProductLink = uri.scheme == 'productcatalog' && uri.host == 'app';
    final segments = uri.pathSegments;
    if ((isInternal || isProductLink) &&
        segments.length == 2 &&
        segments.first == 'products') {
      final id = int.tryParse(segments.last, radix: 10);
      if (id != null && id > 0) {
        return SynchronousFuture(CatalogRoute(productId: id));
      }
    }
    return SynchronousFuture(const CatalogRoute());
  }

  @override
  RouteInformation restoreRouteInformation(CatalogRoute configuration) {
    final id = configuration.productId;
    return RouteInformation(uri: Uri(path: id == null ? '/' : '/products/$id'));
  }
}
