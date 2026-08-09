/// Base class for domain rule violations.
sealed class DomainException implements Exception {
  const DomainException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// A command payload violates domain constraints (e.g. empty name,
/// negative quantity, minimum stock below zero).
class ValidationError extends DomainException {
  const ValidationError(super.message);
}

/// An OUT movement exceeds the product's current stock.
///
/// Carries the offending values so the UI layer can offer feedback
/// (spec requirement 2.1: stock must never go negative).
class InsufficientStockError extends DomainException {
  const InsufficientStockError({
    required this.currentStock,
    required this.quantity,
  }) : super(
         'Insufficient stock: current $currentStock, requested OUT $quantity',
       );

  final int currentStock;
  final int quantity;
}
