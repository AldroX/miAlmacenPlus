import 'entities/inventory_movement.dart';
import 'errors.dart';
import 'movement_reason.dart';
import 'movement_type.dart';

/// Movement quantities must be strictly positive; zero or negative values
/// are never a valid stock change.
void validateQuantity(int quantity) {
  if (quantity <= 0) {
    throw const ValidationError('Movement quantity must be greater than zero');
  }
}

/// Rejects an OUT that would take [currentStock] below zero
/// (spec requirement 2.1: stock never negative).
void validateOut(int currentStock, int quantity) {
  validateQuantity(quantity);
  if (currentStock < 0) {
    throw const ValidationError('Current stock must not be negative');
  }
  if (quantity > currentStock) {
    throw InsufficientStockError(
      currentStock: currentStock,
      quantity: quantity,
    );
  }
}

/// Records the effect of a movement on [currentStock], deriving the movement
/// type from the reason's bucket. Stock changes ONLY through this function
/// (spec requirement 2.1).
///
/// Throws [ValidationError] for invalid quantities and, for OUT movements,
/// [InsufficientStockError] when the requested quantity exceeds the stock.
InventoryMovement createMovement({
  required String id,
  required String productId,
  required String userId,
  required MovementReason reason,
  required int quantity,
  required int currentStock,
  required DateTime occurredAt,
}) {
  validateQuantity(quantity);
  final type = reason.type;
  if (type == MovementType.outgoing) {
    validateOut(currentStock, quantity);
  }
  final delta = type == MovementType.incoming ? quantity : -quantity;
  return InventoryMovement(
    id: id,
    productId: productId,
    userId: userId,
    type: type,
    reason: reason,
    quantity: quantity,
    stockBefore: currentStock,
    stockAfter: currentStock + delta,
    occurredAt: occurredAt,
  );
}

/// Projection invariant: `currentStock == projectStock(initialStock, trail)`.
///
/// Recomputes the stock from a movement trail, proving stock is a pure
/// function of movements (spec requirement 2.1). A trail whose projection
/// drops below zero violates the invariant and throws [StateError].
int projectStock({
  required int initialStock,
  required List<InventoryMovement> movements,
}) {
  var stock = initialStock;
  for (final movement in movements) {
    final delta = movement.type == MovementType.incoming
        ? movement.quantity
        : -movement.quantity;
    stock += delta;
    if (stock < 0) {
      throw StateError(
        'Stock invariant violated: trail projects below zero at movement '
        '${movement.id}',
      );
    }
  }
  return stock;
}
