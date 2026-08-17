import 'package:drift/native.dart' show SqliteException;
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_almacen_plus/core/data/drift/app_database.dart';
import 'package:mi_almacen_plus/core/data/repositories/inventory_repository.dart';
import 'package:mi_almacen_plus/core/domain/entities/inventory_movement.dart'
    as domain;
import 'package:mi_almacen_plus/core/domain/movement_reason.dart';
import 'package:mi_almacen_plus/core/domain/movement_type.dart';

/// Polls until [condition] holds (drift streams emit asynchronously).
Future<void> _waitFor(
  bool Function() condition, {
  int timeout = 3000,
}) async {
  final deadline = DateTime.now().add(Duration(milliseconds: timeout));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for stream emission');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

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

    test('watchRecent emits newest-first domain movements capped by limit',
        () async {
      final snapshots = <List<domain.InventoryMovement>>[];
      final sub = movementRepo
          .watchRecent(limit: 2)
          .listen((rows) => snapshots.add(rows));
      await _waitFor(() => snapshots.isNotEmpty, timeout: 3000);
      await sub.cancel();

      // setUp seeds INITIAL_STOCK + purchase + sale = 3 movements; limit 2 caps.
      expect(snapshots.last, isNotEmpty);
      expect(snapshots.last.length, 2);
      // Newest-first: the sale (latest) is first, purchase second.
      expect(snapshots.last[0].reason, MovementReason.sale);
      expect(snapshots.last[1].reason, MovementReason.purchase);
    });

    test('watchRecent re-emits after a new movement is recorded', () async {
      final reasons = <List<domain.InventoryMovement>>[];
      final sub = movementRepo.watchRecent().listen((rows) => reasons.add(rows));
      await _waitFor(() => reasons.isNotEmpty, timeout: 3000);
      expect(reasons.last.length, 3);

      await productRepo.recordMovement(
        productId: productId!,
        userId: defaultUserId!,
        reason: MovementReason.purchase,
        quantity: 5,
      );
      await _waitFor(() => reasons.length > 1, timeout: 3000);
      await sub.cancel();

      // Re-emission now includes 4 movements, newest-first.
      expect(reasons.last.length, 4);
      expect(reasons.last.first.reason, MovementReason.purchase);
    });
  });

  group('transaction rollback (spec 4.1 Sc.1)', () {
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
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'mid-transaction failure rolls back the movement insert and stock write',
      () async {
        // Set up a trail so we can prove nothing extra is persisted.
        await productRepo.recordMovement(
          productId: productId!,
          userId: defaultUserId!,
          reason: MovementReason.purchase,
          quantity: 10,
        );
        expect((await productRepo.getById(productId!))!.currentStock, 30);
        expect(await movementRepo.getForProduct(productId!), hasLength(2));

        // Force a failure INSIDE the transaction: the movement insert
        // succeeds, then the stock write violates CHECK (currentStock >= 0).
        // The whole transaction must roll back both writes.
        await expectLater(
          db.transaction(() async {
            await db.inventoryMovementDao.insertMovementWithStockUpdate(
              InventoryMovementsCompanion.insert(
                id: 'mv-rollback-1',
                productId: productId!,
                userId: defaultUserId!,
                type: MovementType.incoming.index,
                reason: MovementReason.purchase.index,
                quantity: 5,
                stockBefore: 30,
                stockAfter: 35,
                occurredAt: 12345,
              ),
              -1, // invalid stock write -> CHECK violation mid-transaction
            );
          }),
          throwsA(isA<SqliteException>()),
        );

        // No movement row persisted (rollback of the first write).
        final movements = await movementRepo.getForProduct(productId!);
        expect(movements, hasLength(2));
        expect(movements.any((m) => m.id == 'mv-rollback-1'), isFalse);

        // Stock unchanged (rollback of the second write).
        final product = (await productRepo.getById(productId!))!;
        expect(product.currentStock, 30);
      },
    );

    test('failing movement insert via public API leaves no movement and stock '
        'unchanged', () async {
      await productRepo.recordMovement(
        productId: productId!,
        userId: defaultUserId!,
        reason: MovementReason.purchase,
        quantity: 10,
      );
      expect((await productRepo.getById(productId!))!.currentStock, 30);

      // An invalid user FK makes the movement insert fail inside the
      // repository's own transaction.
      await expectLater(
        productRepo.recordMovement(
          productId: productId!,
          userId: 'no-such-user',
          reason: MovementReason.purchase,
          quantity: 5,
        ),
        throwsA(isA<SqliteException>()),
      );

      final movements = await movementRepo.getForProduct(productId!);
      expect(movements, hasLength(2)); // INITIAL_STOCK + purchase
      final product = (await productRepo.getById(productId!))!;
      expect(product.currentStock, 30);
    });
  });
}
