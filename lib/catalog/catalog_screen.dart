import 'dart:async';

import 'package:flutter/material.dart';

import 'catalog_bloc.dart';
import 'catalog_state.dart';
import 'product_card.dart';
import 'product_repository.dart';
import 'product_table.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({required this.repository, super.key});

  final ProductRepository repository;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late final CatalogBloc _bloc;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController(keepScrollOffset: false);
  bool _showTable = false;

  @override
  void initState() {
    super.initState();
    _bloc = CatalogBloc(widget.repository);
    _scrollController.addListener(_requestNextPageIfNeeded);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    unawaited(_bloc.close());
    super.dispose();
  }

  void _search(String text) => _bloc.add(CatalogSearchChanged(text));

  void _retry() => _bloc.add(const CatalogRetryRequested());

  void _requestNextPageIfNeeded() {
    if (_scrollController.hasClients &&
        _scrollController.position.hasContentDimensions &&
        _scrollController.position.extentAfter < 300 &&
        _bloc.state.status == CatalogStatus.ready &&
        _bloc.state.hasMore) {
      _bloc.add(const CatalogNextPageRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Catalog'),
        actions: [
          IconButton(
            tooltip: _showTable ? 'Show grid' : 'Show table',
            icon: Icon(_showTable ? Icons.grid_view : Icons.table_rows),
            onPressed: () => setState(() => _showTable = !_showTable),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SearchBar(
                controller: _searchController,
                hintText: 'Search products',
                leading: const Icon(Icons.search),
                textInputAction: TextInputAction.search,
                onChanged: _search,
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
                trailing: [
                  ValueListenableBuilder(
                    valueListenable: _searchController,
                    builder: (context, value, child) {
                      if (value.text.isEmpty) return const SizedBox.shrink();
                      return IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          _search('');
                        },
                        icon: const Icon(Icons.clear),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<CatalogState>(
                stream: _bloc.stream,
                initialData: _bloc.state,
                builder: (context, snapshot) => _buildResults(snapshot.data!),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(CatalogState state) {
    switch (state.status) {
      case CatalogStatus.waitingForSearch:
      case CatalogStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case CatalogStatus.loadFailed:
        return Center(child: _retryMessage('Could not load products.'));
      case CatalogStatus.ready:
        if (state.products.isEmpty) {
          return const Center(child: Text('No products found.'));
        }
        if (state.hasMore) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _requestNextPageIfNeeded();
          });
        }
      case CatalogStatus.loadingMore:
      case CatalogStatus.loadMoreFailed:
        break;
    }

    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return CustomScrollView(
      key: ValueKey((state.query, _showTable)),
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          sliver: _showTable
              ? ProductTable(products: state.products)
              : SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 240 * textScale.clamp(1, 1.5),
                    mainAxisExtent:
                        140 + 134 * textScale.clamp(1, double.infinity),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: state.products.length,
                  itemBuilder: (context, index) =>
                      ProductCard(product: state.products[index]),
                ),
        ),
        if (state.status == CatalogStatus.loadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        if (state.status == CatalogStatus.loadMoreFailed)
          SliverToBoxAdapter(
            child: _retryMessage('Could not load more products.'),
          ),
      ],
    );
  }

  Widget _retryMessage(String message) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _retry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
