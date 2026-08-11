import 'package:flutter_test/flutter_test.dart';
import 'package:mi_almacen_plus/core/domain/entities/inventory_movement.dart';
import 'package:mi_almacen_plus/core/domain/errors.dart';
import 'package:mi_almacen_plus/core/domain/movement_reason.dart';
import 'package:mi_almacen_plus/core/domain/movement_rules.dart';
import 'package:mi_almacen_plus/core/domain/movement_type.dart';

void main() {
  final occurredAt = DateTime(2026, 8, 9, 10, 30);

  group('createMovement', () {
    test('incoming movement adds quantity and records stock before/after', () {
      final movement = createMovement(
        id: 'mov-1',
        productId: 'prod-1',
        userId: 'user-1',
        reason: MovementReason.purchase,
        quantity: 5,
        currentStock: 30,
        occurredAt: occurredAt,
      );
      expect(movement.type, MovementType.incoming);
      expect(movement.reason, MovementReason.purchase);
      expect(movement.quantity, 5);
      expect(movement.stockBefore, 30);
      expect(movement.stockAfter, 35);
    });

    test(
      'outgoing movement subtracts quantity and records stock before/after',
      () {
        final movement = createMovement(
          id: 'mov-2',
          productId: 'prod-1',
          userId: 'user-1',
          reason: MovementReason.sale,
          quantity: 5,
          currentStock: 30,
          occurredAt: occurredAt,
        );
        expect(movement.type, MovementType.outgoing);
        expect(movement.stockBefore, 30);
        expect(movement.stockAfter, 25);
      },
    );

    test('outgoing movement over stock throws InsufficientStockError', () {
      expect(
        () => createMovement(
          id: 'mov-3',
          productId: 'prod-1',
          userId: 'user-1',
          reason: MovementReason.sale,
          quantity: 5,
          currentStock: 3,
          occurredAt: occurredAt,
        ),
        throwsA(isA<InsufficientStockError>()),
      );
    });

    test('rejects zero or negative quantity', () {
      expect(
        () => createMovement(
          id: 'mov-4',
          productId: 'prod-1',
          userId: 'user-1',
          reason: MovementReason.purchase,
          quantity: 0,
          currentStock: 10,
          occurredAt: occurredAt,
        ),
        throwsA(isA<ValidationError>()),
      );
      expect(
        () => createMovement(
          id: 'mov-5',
          productId: 'prod-1',
          userId: 'user-1',
          reason: MovementReason.purchase,
          quantity: -3,
          currentStock: 10,
          occurredAt: occurredAt,
        ),
        throwsA(isA<ValidationError>()),
      );
    });
  });

  group('validateOut', () {
    test('throws InsufficientStockError only when quantity exceeds stock', () {
      expect(() => validateOut(3, 5), throwsA(isA<InsufficientStockError>()));
      expect(() => validateOut(5, 5), returnsNormally);
      expect(() => validateOut(30, 5), returnsNormally);
    });
  });

  group('projectStock (invariant: currentStock = f(movements))', () {
    test('returns the initial stock for an empty trail', () {
      expect(projectStock(initialStock: 10, movements: const []), 10);
    });

    test('recomputes stock from an initial IN followed by an OUT', () {
      final movements = [
        createMovement(
          id: 'm1',
          productId: 'p1',
          userId: 'u1',
          reason: MovementReason.initialStock,
          quantity: 10,
          currentStock: 0,
          occurredAt: occurredAt,
        ),
        createMovement(
          id: 'm2',
          productId: 'p1',
          userId: 'u1',
          reason: MovementReason.sale,
          quantity: 3,
          currentStock: 10,
          occurredAt: occurredAt,
        ),
      ];
      expect(projectStock(initialStock: 0, movements: movements), 7);
    });

    test('throws StateError when the trail would project below zero', () {
      // A movement record that samples an impossible state (stockAfter -3)
      // violates the invariant: stock must never project negative.
      final movements = [
        InventoryMovement(
          id: 'm1',
          productId: 'p1',
          userId: 'u1',
          type: MovementType.incoming,
          reason: MovementReason.initialStock,
          quantity: 2,
          stockBefore: 0,
          stockAfter: 2,
          occurredAt: occurredAt,
        ),
        InventoryMovement(
          id: 'm2',
          productId: 'p1',
          userId: 'u1',
          type: MovementType.outgoing,
          reason: MovementReason.sale,
          quantity: 5,
          stockBefore: 2,
          stockAfter: -3,
          occurredAt: occurredAt,
        ),
      ];
      expect(
        () => projectStock(initialStock: 0, movements: movements),
        throwsStateError,
      );
    });
  });
}
