/// Stock health state of a product, derived from stock and minimum stock
/// (spec requirement 2.2). Derived, never stored.
enum StockStatus { outOfStock, lowStock, normal }
