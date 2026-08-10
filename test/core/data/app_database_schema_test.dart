import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart' show SqliteException;
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_almacen_plus/core/data/drift/app_database.dart';
import 'package:mi_almacen_plus/core/data/repositories/inventory_repository.dart';

void main() {
  group('AppDatabase schema defenses', () {
    late AppDatabase db;
    late CategoryRepository categoryRepo;
    late UserRepository userRepo;

    String? userId;
    String? categoryId;

    setUp(() async {
      db = AppDatabase.inMemory();
      categoryRepo = CategoryRepository(db);
      userRepo = UserRepository(db);

      final user = await userRepo.getOrCreateDefault();
      userId = user.id;
      final categories = await categoryRepo.getAll();
      categoryId = categories.first.id;
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'CHECK (currentStock >= 0) rejects a negative stock at DB level',
      () async {
        await expectLater(
          db.productDao.insertProduct(
            ProductsCompanion.insert(
              id: 'prod-bad',
              categoryId: categoryId!,
              userId: userId!,
              name: 'Producto inválido',
              unit: 'u',
              minimumStock: 0,
              currentStock: const Value(-1),
            ),
          ),
          throwsA(isA<SqliteException>()),
        );

        // The rejected row must not persist.
        expect(await db.productDao.getById('prod-bad'), isNull);
      },
    );

    test('CHECK boundary: currentStock 0 is accepted', () async {
      await db.productDao.insertProduct(
        ProductsCompanion.insert(
          id: 'prod-zero',
          categoryId: categoryId!,
          userId: userId!,
          name: 'Stock cero',
          unit: 'u',
          minimumStock: 0,
          currentStock: const Value(0),
        ),
      );

      final row = await db.productDao.getById('prod-zero');
      expect(row, isNotNull);
      expect(row!.currentStock, 0);
    });

    test(
      'foreign keys are enforced for products (invalid category rejected)',
      () async {
        await expectLater(
          db.productDao.insertProduct(
            ProductsCompanion.insert(
              id: 'prod-fk',
              categoryId: 'no-such-category',
              userId: userId!,
              name: 'FK inválido',
              unit: 'u',
              minimumStock: 0,
            ),
          ),
          throwsA(isA<SqliteException>()),
        );

        expect(await db.productDao.getById('prod-fk'), isNull);
      },
    );
  });
}
