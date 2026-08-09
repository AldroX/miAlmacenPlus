import '../movement_reason.dart';
import '../movement_type.dart';

/// Immutable record of a stock movement, including the stock before and
/// after it was applied (spec requirement 4.2).
class InventoryMovement {
  const InventoryMovement({
    required this.id,
    required this.productId,
    required this.userId,
    required this.type,
    required this.reason,
    required this.quantity,
    required this.stockBefore,
    required this.stockAfter,
    required this.occurredAt,
  });

  final String id;
  final String productId;

  /// Actor of this movement (spec requirement 2.4).
  final String userId;
  final MovementType type;
  final MovementReason reason;

  /// Always strictly positive (domain rule).
  final int quantity;
  final int stockBefore;
  final int stockAfter;
  final DateTime occurredAt;

  @override
  bool operator ==(Object other) =>
      other is InventoryMovement &&
      other.id == id &&
      other.productId == productId &&
      other.userId == userId &&
      other.type == type &&
      other.reason == reason &&
      other.quantity == quantity &&
      other.stockBefore == stockBefore &&
      other.stockAfter == stockAfter &&
      other.occurredAt == occurredAt;

  @override
  int get hashCode => Object.hash(
    id,
    productId,
    userId,
    type,
    reason,
    quantity,
    stockBefore,
    stockAfter,
    occurredAt,
  );
}
