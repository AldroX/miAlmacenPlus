import 'package:flutter_test/flutter_test.dart';
import 'package:mi_almacen_plus/core/data/drift/app_database.dart';
import 'package:mi_almacen_plus/core/data/repositories/inventory_repository.dart';
import 'package:mi_almacen_plus/core/domain/movement_reason.dart';

/// Reactive streams on the DAOs (design D11): providers watch these so the UI
/// auto-refreshes after every movement (spec 6.3).
///
/// Each test asserts the stream re-emits with a NEW payload after a write —
/// an emission that never arrives means the watch() method is not wired.
void main() {
  group('DAO watch() streams (design D11)', () {
    late AppDatabase db;
    late UserRepository userRepo;
    late CategoryRepository categoryRepo;
    late ProductRepository productRepo;

    String defaultUserId = '';
    String categoryId = '';

    setUp(() async {
      db = AppDatabase.inMemory();
      userRepo = UserRepository(db);
      categoryRepo = CategoryRepository(db);
      productRepo = ProductRepository(db);
      final user = await userRepo.getOrCreateDefault();
      defaultUserId = user.id;
      final categories = await categoryRepo.getAll();
      categoryId = categories.first.id;
    });

    tearDown(() async {
      await db.close();
    });

    /// Polls until [condition] holds (drift streams emit asynchronously).
    Future<void> waitFor(
      bool Function() condition, {
      Duration timeout = const Duration(seconds: 3),
    }) async {
      final deadline = DateTime.now().add(timeout);
      while (!condition()) {
        if (DateTime.now().isAfter(deadline)) {
          fail('Timed out waiting for stream emission');
        }
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    }

    test('categoryDao.watchAll emits the 7 seeded categories', () async {
      final lengths = <int>[];
      final sub = db.categoryDao.watchAll().listen((rows) {
        lengths.add(rows.length);
      });
      await waitFor(() => lengths.isNotEmpty);
      await sub.cancel();

      expect(lengths.last, 7);
    });

    test('categoryDao.watchAll re-emits after a quick-create', () async {
      final lengths = <int>[];
      final sub = db.categoryDao.watchAll().listen((rows) {
        lengths.add(rows.length);
      });
      await waitFor(() => lengths.isNotEmpty);
      expect(lengths.first, 7); // 7 seeds on first emission

      await categoryRepo.quickCreate('Verduras');
      await waitFor(() => lengths.last == 8);
      await sub.cancel();

      expect(lengths.last, 8);
    });

    test('productDao.watchAll drops soft-deleted products reactively',
        () async {
      final product = await productRepo.create(
        categoryId: categoryId,
        userId: defaultUserId,
        name: 'Café',
        unit: 'kg',
        minimumStock: 5,
        initialStock: 10,
      );
      final lengths = <int>[];
      final sub = db.productDao.watchAll().listen((rows) {
        lengths.add(rows.length);
      });
      await waitFor(() => lengths.isNotEmpty && lengths.last == 1);
      expect(lengths.last, 1);

      await productRepo.softDelete(product.id);
      await waitFor(() => lengths.last == 0);
      await sub.cancel();

      expect(lengths.last, 0);
    });

    test('productDao.watchById re-emits the updated row on edit', () async {
      final product = await productRepo.create(
        categoryId: categoryId,
        userId: defaultUserId,
        name: 'Café',
        unit: 'kg',
        minimumStock: 5,
        initialStock: 10,
      );
      final names = <String?>[];
      final sub = db.productDao.watchById(product.id).listen((row) {
        names.add(row?.name);
      });
      await waitFor(() => names.isNotEmpty);
      expect(names.first, 'Café');

      await productRepo.update(id: product.id, name: 'Café molido');
      await waitFor(() => names.contains('Café molido'));
      await sub.cancel();

      expect(names.last, 'Café molido');
    });

    test('inventoryMovementDao.watchForProduct emits newest-first trail',
        () async {
      final product = await productRepo.create(
        categoryId: categoryId,
        userId: defaultUserId,
        name: 'Café',
        unit: 'kg',
        minimumStock: 5,
        initialStock: 10,
      );
      await productRepo.recordMovement(
        productId: product.id,
        userId: defaultUserId,
        reason: MovementReason.sale,
        quantity: 3,
      );

      final firstReasons = <int?>[];
      final sub = db.inventoryMovementDao
          .watchForProduct(product.id)
          .listen((rows) => firstReasons.add(rows.isEmpty ? null : rows.first.reason));
      await waitFor(() => firstReasons.isNotEmpty);
      await sub.cancel();

      // Newest-first: the OUT (sale) must be the first row of the trail.
      expect(firstReasons.last, MovementReason.sale.index);
    });
  });
}
