import 'package:flutter_test/flutter_test.dart';
import 'package:mi_almacen_plus/core/data/drift/app_database.dart';
import 'package:mi_almacen_plus/core/data/repositories/inventory_repository.dart';
import 'package:mi_almacen_plus/core/domain/errors.dart';
import 'package:mi_almacen_plus/core/domain/movement_reason.dart';
import 'package:mi_almacen_plus/core/domain/movement_type.dart';
import 'package:mi_almacen_plus/core/domain/stock_status.dart';
import 'package:mi_almacen_plus/core/domain/stock_status_of.dart';

void main() {
  group('ProductRepository', () {
    late AppDatabase db;
    late ProductRepository productRepo;
    late CategoryRepository categoryRepo;
    late UserRepository userRepo;

    String? defaultUserId;
    String? categoryId;

    setUp(() async {
      db = AppDatabase.inMemory();
      productRepo = ProductRepository(db);
      categoryRepo = CategoryRepository(db);
      userRepo = UserRepository(db);

      final user = await userRepo.getOrCreateDefault();
      defaultUserId = user.id;

      final categories = await categoryRepo.getAll();
      categoryId = categories.first.id;
    });

    tearDown(() async {
      await db.close();
    });

    group('create', () {
      test(
        'creates a product with initial stock and records INITIAL_STOCK movement',
        () async {
          final product = await productRepo.create(
            categoryId: categoryId!,
            userId: defaultUserId!,
            name: 'Café',
            unit: 'kg',
            minimumStock: 5,
            initialStock: 20,
          );

          expect(product.id, isNotEmpty);
          expect(product.name, 'Café');
          expect(product.unit, 'kg');
          expect(product.minimumStock, 5);
          expect(product.currentStock, 20);
          expect(product.categoryId, categoryId);
          expect(product.userId, defaultUserId);
          expect(product.isActive, isTrue);
        },
      );

      test('created product has correct stock status', () async {
        final product = await productRepo.create(
          categoryId: categoryId!,
          userId: defaultUserId!,
          name: 'Café',
          unit: 'kg',
          minimumStock: 5,
          initialStock: 20,
        );

        final status = stockStatusOf(
          product.currentStock,
          product.minimumStock,
        );
        expect(status, StockStatus.normal);
      });

      test('rejects empty name', () async {
        expect(
          () => productRepo.create(
            categoryId: categoryId!,
            userId: defaultUserId!,
            name: '',
            unit: 'kg',
            minimumStock: 5,
            initialStock: 10,
          ),
          throwsA(isA<ValidationError>()),
        );
      });

      test('rejects whitespace-only name', () async {
        expect(
          () => productRepo.create(
            categoryId: categoryId!,
            userId: defaultUserId!,
            name: '   ',
            unit: 'kg',
            minimumStock: 5,
            initialStock: 10,
          ),
          throwsA(isA<ValidationError>()),
        );
      });

      test('rejects empty unit', () async {
        expect(
          () => productRepo.create(
            categoryId: categoryId!,
            userId: defaultUserId!,
            name: 'Café',
            unit: '',
            minimumStock: 5,
            initialStock: 10,
          ),
          throwsA(isA<ValidationError>()),
        );
      });

      test('rejects negative minimumStock', () async {
        expect(
          () => productRepo.create(
            categoryId: categoryId!,
            userId: defaultUserId!,
            name: 'Café',
            unit: 'kg',
            minimumStock: -1,
            initialStock: 10,
          ),
          throwsA(isA<ValidationError>()),
        );
      });

      test('rejects negative initialStock', () async {
        expect(
          () => productRepo.create(
            categoryId: categoryId!,
            userId: defaultUserId!,
            name: 'Café',
            unit: 'kg',
            minimumStock: 5,
            initialStock: -1,
          ),
          throwsA(isA<ValidationError>()),
        );
      });
    });

    group('getById / getAll / getByCategory / count', () {
      test('getById returns product after create', () async {
        final created = await productRepo.create(
          categoryId: categoryId!,
          userId: defaultUserId!,
          name: 'Café',
          unit: 'kg',
          minimumStock: 5,
          initialStock: 20,
        );

        final found = await productRepo.getById(created.id);
        expect(found, isNotNull);
        expect(found!.name, 'Café');
        expect(found.currentStock, 20);
      });

      test('getById returns null for non-existent id', () async {
        final product = await productRepo.getById('non-existent');
        expect(product, isNull);
      });

      test('getAll returns all active products', () async {
        await productRepo.create(
          categoryId: categoryId!,
          userId: defaultUserId!,
          name: 'Café',
          unit: 'kg',
          minimumStock: 5,
          initialStock: 20,
        );
        await productRepo.create(
          categoryId: categoryId!,
          userId: defaultUserId!,
          name: 'Azúcar',
          unit: 'kg',
          minimumStock: 10,
          initialStock: 50,
        );

        final products = await productRepo.getAll();
        expect(products, hasLength(2));
      });

      test('getAll with onlyActive=false includes soft-deleted', () async {
        final p1 = await productRepo.create(
          categoryId: categoryId!,
          userId: defaultUserId!,
          name: 'Café',
          unit: 'kg',
          minimumStock: 5,
          initialStock: 20,
        );
        await productRepo.softDelete(p1.id);

        final active = await productRepo.getAll(onlyActive: true);
        final all = await productRepo.getAll(onlyActive: false);

        expect(active, isEmpty);
        expect(all, hasLength(1));
      });

      test('getByCategory filters by category', () async {
        final cat2 = (await categoryRepo.getAll())[1].id;

        await productRepo.create(
          categoryId: categoryId!,
          userId: defaultUserId!,
          name: 'Café',
          unit: 'kg',
          minimumStock: 5,
          initialStock: 20,
        );
        await productRepo.create(
          categoryId: cat2,
          userId: defaultUserId!,
          name: 'Detergente',
          unit: 'L',
          minimumStock: 3,
          initialStock: 15,
        );

        final cat1Products = await productRepo.getByCategory(categoryId!);
        expect(cat1Products, hasLength(1));
        expect(cat1Products.first.name, 'Café');
      });

      test('count returns correct number', () async {
        expect(await productRepo.count(), 0);

        await productRepo.create(
          categoryId: categoryId!,
          userId: defaultUserId!,
          name: 'Café',
          unit: 'kg',
          minimumStock: 5,
          initialStock: 20,
        );
        expect(await productRepo.count(), 1);
      });
    });

    group('update', () {
      test('updates descriptive fields but NOT currentStock', () async {
        final created = await productRepo.create(
          categoryId: categoryId!,
          userId: defaultUserId!,
          name: 'Café',
          unit: 'kg',
          minimumStock: 5,
          initialStock: 20,
        );

        final updated = await productRepo.update(
          id: created.id,
          name: 'Café Premium',
          unit: 'bolsa',
          minimumStock: 10,
          description: 'Granos seleccionados',
          isActive: true,
        );

        expect(updated.name, 'Café Premium');
        expect(updated.unit, 'bolsa');
        expect(updated.minimumStock, 10);
        expect(updated.description, 'Granos seleccionados');
        expect(
          updated.currentStock,
          20,
          reason: 'currentStock must never change via update',
        );
      });

      test('rejects update of non-existent product', () async {
        expect(
          () => productRepo.update(id: 'non-existent', name: 'X'),
          throwsA(isA<ValidationError>()),
        );
      });

      test('validates name and unit on update', () async {
        final created = await productRepo.create(
          categoryId: categoryId!,
          userId: defaultUserId!,
          name: 'Café',
          unit: 'kg',
          minimumStock: 5,
          initialStock: 20,
        );

        expect(
          () => productRepo.update(id: created.id, name: ''),
          throwsA(isA<ValidationError>()),
        );
        expect(
          () => productRepo.update(id: created.id, unit: ''),
          throwsA(isA<ValidationError>()),
        );
        expect(
          () => productRepo.update(id: created.id, minimumStock: -1),
          throwsA(isA<ValidationError>()),
        );
      });
    });

    group('softDelete', () {
      test('marks product as inactive but preserves it', () async {
        final created = await productRepo.create(
          categoryId: categoryId!,
          userId: defaultUserId!,
          name: 'Café',
          unit: 'kg',
          minimumStock: 5,
          initialStock: 20,
        );

        await productRepo.softDelete(created.id);

        final active = await productRepo.getAll(onlyActive: true);
        final all = await productRepo.getAll(onlyActive: false);

        expect(active, isEmpty);
        expect(all, hasLength(1));
        expect(all.first.isActive, isFalse);
      });
    });

    group('recordMovement', () {
      test('records incoming movement and increases stock', () async {
        final product = await productRepo.create(
          categoryId: categoryId!,
          userId: defaultUserId!,
          name: 'Café',
          unit: 'kg',
          minimumStock: 5,
          initialStock: 20,
        );

        final movement = await productRepo.recordMovement(
          productId: product.id,
          userId: defaultUserId!,
          reason: MovementReason.purchase,
          quantity: 10,
        );

        expect(movement.type, MovementType.incoming);
        expect(movement.reason, MovementReason.purchase);
        expect(movement.quantity, 10);
        expect(movement.stockBefore, 20);
        expect(movement.stockAfter, 30);

        final updated = await productRepo.getById(product.id);
        expect(updated!.currentStock, 30);
      });

      test('records outgoing movement and decreases stock', () async {
        final product = await productRepo.create(
          categoryId: categoryId!,
          userId: defaultUserId!,
          name: 'Café',
          unit: 'kg',
          minimumStock: 5,
          initialStock: 20,
        );

        final movement = await productRepo.recordMovement(
          productId: product.id,
          userId: defaultUserId!,
          reason: MovementReason.sale,
          quantity: 8,
        );

        expect(movement.type, MovementType.outgoing);
        expect(movement.stockBefore, 20);
        expect(movement.stockAfter, 12);

        final updated = await productRepo.getById(product.id);
        expect(updated!.currentStock, 12);
      });

      test('rejects outgoing movement exceeding stock', () async {
        final product = await productRepo.create(
          categoryId: categoryId!,
          userId: defaultUserId!,
          name: 'Café',
          unit: 'kg',
          minimumStock: 5,
          initialStock: 10,
        );

        expect(
          () => productRepo.recordMovement(
            productId: product.id,
            userId: defaultUserId!,
            reason: MovementReason.sale,
            quantity: 15,
          ),
          throwsA(isA<InsufficientStockError>()),
        );

        // Stock should remain unchanged
        final unchanged = await productRepo.getById(product.id);
        expect(unchanged!.currentStock, 10);
      });

      test('rejects zero or negative quantity', () async {
        final product = await productRepo.create(
          categoryId: categoryId!,
          userId: defaultUserId!,
          name: 'Café',
          unit: 'kg',
          minimumStock: 5,
          initialStock: 20,
        );

        expect(
          () => productRepo.recordMovement(
            productId: product.id,
            userId: defaultUserId!,
            reason: MovementReason.purchase,
            quantity: 0,
          ),
          throwsA(isA<ValidationError>()),
        );
        expect(
          () => productRepo.recordMovement(
            productId: product.id,
            userId: defaultUserId!,
            reason: MovementReason.purchase,
            quantity: -5,
          ),
          throwsA(isA<ValidationError>()),
        );
      });

      test('rejects movement for non-existent product', () async {
        expect(
          () => productRepo.recordMovement(
            productId: 'non-existent',
            userId: defaultUserId!,
            reason: MovementReason.purchase,
            quantity: 10,
          ),
          throwsA(isA<ValidationError>()),
        );
      });

      test('all movement reasons work correctly', () async {
        final product = await productRepo.create(
          categoryId: categoryId!,
          userId: defaultUserId!,
          name: 'Test',
          unit: 'u',
          minimumStock: 0,
          initialStock: 100,
        );

        // INCOMING reasons
        for (final reason in [
          MovementReason.purchase,
          MovementReason.return_,
          MovementReason.initialStock,
        ]) {
          final m = await productRepo.recordMovement(
            productId: product.id,
            userId: defaultUserId!,
            reason: reason,
            quantity: 10,
          );
          expect(m.type, MovementType.incoming);
          expect(m.stockAfter, m.stockBefore + 10);
        }

        // OUTGOING reasons
        for (final reason in [
          MovementReason.sale,
          MovementReason.consumption,
          MovementReason.loss,
          MovementReason.online,
        ]) {
          final m = await productRepo.recordMovement(
            productId: product.id,
            userId: defaultUserId!,
            reason: reason,
            quantity: 5,
          );
          expect(m.type, MovementType.outgoing);
          expect(m.stockAfter, m.stockBefore - 5);
        }
      });
    });

    group('recomputeStock (projection invariant)', () {
      test('recomputes stock from movement trail', () async {
        final product = await productRepo.create(
          categoryId: categoryId!,
          userId: defaultUserId!,
          name: 'Café',
          unit: 'kg',
          minimumStock: 5,
          initialStock: 10,
        );

        await productRepo.recordMovement(
          productId: product.id,
          userId: defaultUserId!,
          reason: MovementReason.purchase,
          quantity: 20,
        );
        await productRepo.recordMovement(
          productId: product.id,
          userId: defaultUserId!,
          reason: MovementReason.sale,
          quantity: 5,
        );

        final recomputed = await productRepo.recomputeStock(product.id);
        expect(recomputed, 25); // 10 + 20 - 5
      });

      test('recompute is invariant to occurredAt ties (spec 2.1)', () async {
        final product = await productRepo.create(
          categoryId: categoryId!,
          userId: defaultUserId!,
          name: 'Café',
          unit: 'kg',
          minimumStock: 5,
          initialStock: 10,
        );

        // Two movements sharing the exact same timestamp must not corrupt the
        // projection: the invariant is a pure sum over the trail.
        final sameTimestamp = DateTime(2026, 1, 1, 12);
        await productRepo.recordMovement(
          productId: product.id,
          userId: defaultUserId!,
          reason: MovementReason.purchase,
          quantity: 20,
          occurredAt: sameTimestamp,
        );
        await productRepo.recordMovement(
          productId: product.id,
          userId: defaultUserId!,
          reason: MovementReason.sale,
          quantity: 5,
          occurredAt: sameTimestamp,
        );

        final stored = (await productRepo.getById(product.id))!.currentStock;
        expect(stored, 25);

        // Recompute must match the stored stock AND the domain projection.
        final recomputed = await productRepo.recomputeStock(product.id);
        expect(
          recomputed,
          stored,
          reason: 'recompute must equal currentStock (spec 2.1)',
        );
      });
    });
  });
}
