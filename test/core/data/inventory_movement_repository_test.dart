import 'package:flutter_test/flutter_test.dart';
import 'package:mi_almacen_plus/core/data/drift/app_database.dart';
import 'package:mi_almacen_plus/core/data/repositories/inventory_repository.dart';
import 'package:mi_almacen_plus/core/domain/movement_reason.dart';

void main() {
  group('InventoryMovementRepository', () {
    late AppDatabase db;
    late ProductRepository productRepo;
    late CategoryRepository categoryRepo;
    late UserRepository userRepo;
    late InventoryMovementRepository movementRepo;

    String? defaultUserId;
    String? categoryId;
    String? productId;

    setUp(() async {
      db = AppDatabase.inMemory();
      productRepo = ProductRepository(db);
      categoryRepo = CategoryRepository(db);
      userRepo = UserRepository(db);
      movementRepo = InventoryMovementRepository(db);

      final user = await userRepo.getOrCreateDefault();
      defaultUserId = user.id;

      final categories = await categoryRepo.getAll();
      categoryId = categories.first.id;

      final product = await productRepo.create(
        categoryId: categoryId!,
        userId: defaultUserId!,
        name: 'Café',
        unit: 'kg',
        minimumStock: 5,
        initialStock: 20,
      );
      productId = product.id;

      // Add some movements
      await productRepo.recordMovement(
        productId: productId!,
        userId: defaultUserId!,
        reason: MovementReason.purchase,
        quantity: 10,
      );
      await productRepo.recordMovement(
        productId: productId!,
        userId: defaultUserId!,
        reason: MovementReason.sale,
        quantity: 5,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'getForProduct returns movements in descending order (newest first)',
      () async {
        final movements = await movementRepo.getForProduct(productId!);
        expect(movements, hasLength(3)); // INITIAL_STOCK + purchase + sale

        // Should be ordered by occurredAt DESC
        expect(movements[0].reason, MovementReason.sale);
        expect(movements[1].reason, MovementReason.purchase);
        expect(movements[2].reason, MovementReason.initialStock);
      },
    );

    test('getForProduct returns correct stock before/after', () async {
      final movements = await movementRepo.getForProduct(productId!);

      // INITIAL_STOCK: 0 -> 20
      final initial = movements
          .where((m) => m.reason == MovementReason.initialStock)
          .first;
      expect(initial.stockBefore, 0);
      expect(initial.stockAfter, 20);

      // Purchase: 20 -> 30
      final purchase = movements
          .where((m) => m.reason == MovementReason.purchase)
          .first;
      expect(purchase.stockBefore, 20);
      expect(purchase.stockAfter, 30);

      // Sale: 30 -> 25
      final sale = movements
          .where((m) => m.reason == MovementReason.sale)
          .first;
      expect(sale.stockBefore, 30);
      expect(sale.stockAfter, 25);
    });

    test('getForProduct supports pagination', () async {
      final page1 = await movementRepo.getForProduct(
        productId!,
        limit: 2,
        offset: 0,
      );
      final page2 = await movementRepo.getForProduct(
        productId!,
        limit: 2,
        offset: 2,
      );

      expect(page1, hasLength(2));
      expect(page2, hasLength(1));
      expect(page1[0].id, isNot(equals(page2[0].id)));
    });

    test('getById returns movement when it exists', () async {
      final movements = await movementRepo.getForProduct(productId!);
      final first = movements.first;

      final found = await movementRepo.getById(first.id);
      expect(found, isNotNull);
      expect(found!.id, first.id);
      expect(found.reason, first.reason);
    });

    test('getById returns null for non-existent id', () async {
      final movement = await movementRepo.getById('non-existent');
      expect(movement, isNull);
    });

    test('count returns total movements', () async {
      expect(await movementRepo.count(), 3);
    });

    test('movements for different products are isolated', () async {
      // Create another product
      final product2 = await productRepo.create(
        categoryId: categoryId!,
        userId: defaultUserId!,
        name: 'Azúcar',
        unit: 'kg',
        minimumStock: 10,
        initialStock: 50,
      );

      await productRepo.recordMovement(
        productId: product2.id,
        userId: defaultUserId!,
        reason: MovementReason.purchase,
        quantity: 20,
      );

      final movements1 = await movementRepo.getForProduct(productId!);
      final movements2 = await movementRepo.getForProduct(product2.id);

      expect(movements1, hasLength(3));
      expect(movements2, hasLength(2)); // INITIAL_STOCK + purchase
    });
  });
}
