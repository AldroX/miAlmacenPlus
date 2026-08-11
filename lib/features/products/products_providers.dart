import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_almacen_plus/core/domain/entities/product.dart';
import 'package:mi_almacen_plus/core/domain/stock_status.dart';
import 'package:mi_almacen_plus/core/domain/stock_status_of.dart';
import 'package:mi_almacen_plus/core/providers/stream_providers.dart';

/// Product list filter state: free-text search, stock status chip and
/// category chip (spec 3.2, design D11).
class ProductsFilter {
  const ProductsFilter({this.search = '', this.status, this.categoryId});

  final String search;

  /// null = "Todos" (no status chip selected).
  final StockStatus? status;

  /// null = "Todas" (no category chip selected).
  final String? categoryId;

  ProductsFilter copyWith({
    String? search,
    StockStatus? status,
    String? categoryId,
    bool clearStatus = false,
    bool clearCategory = false,
  }) {
    return ProductsFilter(
      search: search ?? this.search,
      status: clearStatus ? null : (status ?? this.status),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    );
  }
}

class ProductsFilterNotifier extends Notifier<ProductsFilter> {
  @override
  ProductsFilter build() => const ProductsFilter();

  void setSearch(String value) => state = state.copyWith(search: value);

  void setStatus(StockStatus? status) => state = state.copyWith(
    status: status,
    clearStatus: status == null,
  );

  void setCategory(String? categoryId) => state = state.copyWith(
    categoryId: categoryId,
    clearCategory: categoryId == null,
  );

  void clear() => state = const ProductsFilter();
}

final productsFilterProvider =
    NotifierProvider<ProductsFilterNotifier, ProductsFilter>(
      ProductsFilterNotifier.new,
    );

/// Products stream with search + status + category filters applied in Dart
/// (design D11). Recomputes whenever the stream or the filter changes.
final filteredProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(productsStreamProvider).value ?? const <Product>[];
  final filter = ref.watch(productsFilterProvider);
  final query = filter.search.trim().toLowerCase();

  return products.where((product) {
    final matchesSearch =
        query.isEmpty || product.name.toLowerCase().contains(query);
    final status = stockStatusOf(product.currentStock, product.minimumStock);
    final matchesStatus = filter.status == null || status == filter.status;
    final matchesCategory =
        filter.categoryId == null || product.categoryId == filter.categoryId;
    return matchesSearch && matchesStatus && matchesCategory;
  }).toList();
});
