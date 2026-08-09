import 'package:flutter_test/flutter_test.dart';
import 'package:mi_almacen_plus/core/domain/entities/category.dart';
import 'package:mi_almacen_plus/core/domain/entities/inventory_movement.dart';
import 'package:mi_almacen_plus/core/domain/entities/product.dart';
import 'package:mi_almacen_plus/core/domain/entities/user.dart';
import 'package:mi_almacen_plus/core/domain/movement_reason.dart';
import 'package:mi_almacen_plus/core/domain/movement_type.dart';

void main() {
  group('User', () {
    test('holds id and name', () {
      const user = User(id: 'user-1', name: 'Alejandro');
      expect(user.id, 'user-1');
      expect(user.name, 'Alejandro');
    });

    test('is equal to another User with the same fields', () {
      const a = User(id: 'user-1', name: 'Alejandro');
      const b = User(id: 'user-1', name: 'Alejandro');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('differs when the name differs', () {
      const a = User(id: 'user-1', name: 'Alejandro');
      const b = User(id: 'user-1', name: 'Otro');
      expect(a == b, isFalse);
    });
  });

  group('Category', () {
    test('holds id and name', () {
      const category = Category(id: 'cat-1', name: 'Bebidas');
      expect(category.id, 'cat-1');
      expect(category.name, 'Bebidas');
    });

    test('is equal to another Category with the same fields', () {
      const a = Category(id: 'cat-1', name: 'Bebidas');
      const b = Category(id: 'cat-1', name: 'Bebidas');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('Product', () {
    const product = Product(
      id: 'prod-1',
      categoryId: 'cat-1',
      userId: 'user-1',
      name: 'Café',
      unit: 'kg',
      minimumStock: 2,
      currentStock: 10,
    );

    test('holds every field with sensible defaults', () {
      expect(product.id, 'prod-1');
      expect(product.categoryId, 'cat-1');
      expect(product.userId, 'user-1');
      expect(product.name, 'Café');
      expect(product.unit, 'kg');
      expect(product.minimumStock, 2);
      expect(product.currentStock, 10);
      expect(product.description, isNull);
      expect(product.isActive, isTrue);
    });

    test('is equal to a Product with the same fields', () {
      const same = Product(
        id: 'prod-1',
        categoryId: 'cat-1',
        userId: 'user-1',
        name: 'Café',
        unit: 'kg',
        minimumStock: 2,
        currentStock: 10,
      );
      expect(product, equals(same));
      expect(product.hashCode, same.hashCode);
    });

    test('copyWith updates descriptive fields but never currentStock', () {
      final editable = product.copyWith(
        name: 'Café molido',
        unit: 'bolsa',
        minimumStock: 3,
        description: 'Granos andinos',
        isActive: false,
      );
      expect(editable.name, 'Café molido');
      expect(editable.unit, 'bolsa');
      expect(editable.minimumStock, 3);
      expect(editable.description, 'Granos andinos');
      expect(editable.isActive, isFalse);
      expect(
        editable.currentStock,
        product.currentStock,
        reason: 'copyWith must never change currentStock (spec 3.2)',
      );
      expect(editable.id, product.id);
      expect(editable.userId, product.userId);
    });
  });

  group('InventoryMovement', () {
    test('holds the full movement record including stock before/after', () {
      final movement = InventoryMovement(
        id: 'mov-1',
        productId: 'prod-1',
        userId: 'user-1',
        type: MovementType.outgoing,
        reason: MovementReason.sale,
        quantity: 5,
        stockBefore: 30,
        stockAfter: 25,
        occurredAt: DateTime(2026, 8, 9, 10, 30),
      );
      expect(movement.id, 'mov-1');
      expect(movement.productId, 'prod-1');
      expect(movement.userId, 'user-1');
      expect(movement.type, MovementType.outgoing);
      expect(movement.reason, MovementReason.sale);
      expect(movement.quantity, 5);
      expect(movement.stockBefore, 30);
      expect(movement.stockAfter, 25);
      expect(movement.occurredAt, DateTime(2026, 8, 9, 10, 30));
    });

    test('is equal to another movement with the same fields', () {
      final a = InventoryMovement(
        id: 'mov-1',
        productId: 'prod-1',
        userId: 'user-1',
        type: MovementType.outgoing,
        reason: MovementReason.sale,
        quantity: 5,
        stockBefore: 30,
        stockAfter: 25,
        occurredAt: DateTime(2026, 8, 9, 10, 30),
      );
      final b = InventoryMovement(
        id: 'mov-1',
        productId: 'prod-1',
        userId: 'user-1',
        type: MovementType.outgoing,
        reason: MovementReason.sale,
        quantity: 5,
        stockBefore: 30,
        stockAfter: 25,
        occurredAt: DateTime(2026, 8, 9, 10, 30),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });
}
