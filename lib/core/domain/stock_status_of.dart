import 'stock_status.dart';

/// Derives [StockStatus] from [stock] and [minStock].
///
/// Rules (spec requirement 2.2): `stock == 0` → [StockStatus.outOfStock]
/// checked first; `0 < stock <= minStock` → [StockStatus.lowStock];
/// otherwise → [StockStatus.normal]. Negative inputs violate the domain
/// invariant (stock never negative) and are rejected.
StockStatus stockStatusOf(int stock, int minStock) {
  if (stock < 0) {
    throw ArgumentError.value(stock, 'stock', 'Stock must not be negative');
  }
  if (minStock < 0) {
    throw ArgumentError.value(
      minStock,
      'minStock',
      'Minimum stock must not be negative',
    );
  }
  if (stock == 0) {
    return StockStatus.outOfStock;
  }
  if (stock <= minStock) {
    return StockStatus.lowStock;
  }
  return StockStatus.normal;
}
