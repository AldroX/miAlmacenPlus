import 'package:flutter_test/flutter_test.dart';
import 'package:mi_almacen_plus/core/data/drift/app_database.dart';
import 'package:mi_almacen_plus/core/data/repositories/inventory_repository.dart';
import 'package:mi_almacen_plus/core/domain/seed_categories.dart';

void main() {
  group('CategoryRepository', () {
    late AppDatabase db;
    late CategoryRepository repo;

    setUp(() {
      db = AppDatabase.inMemory();
      repo = CategoryRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('getAll returns all 7 seeded categories', () async {
      final categories = await repo.getAll();
      expect(categories, hasLength(7));
      final names = categories.map((c) => c.name).toSet();
      expect(names, seedCategoryNames.toSet());
    });

    test('count returns 7', () async {
      expect(await repo.count(), 7);
    });

    test('getById returns category when it exists', () async {
      final categories = await repo.getAll();
      final first = categories.first;
      final found = await repo.getById(first.id);
      expect(found, isNotNull);
      expect(found!.id, first.id);
      expect(found.name, first.name);
    });

    test('getById returns null for non-existent id', () async {
      final category = await repo.getById('non-existent');
      expect(category, isNull);
    });

    test('categories have valid UUID ids', () async {
      final categories = await repo.getAll();
      for (final cat in categories) {
        expect(cat.id, isNotEmpty);
        // UUID v4 format check: 8-4-4-4-12 hex chars
        expect(
          cat.id,
          matches(
            RegExp(
              r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
            ),
          ),
        );
      }
    });

    group('quickCreate (spec 3.3 Sc.1)', () {
      test(
        'creates a category inline with a UUID v4 id and makes it selectable',
        () async {
          final created = await repo.quickCreate('Lácteos');

          expect(created.name, 'Lácteos');
          expect(
            created.id,
            matches(
              RegExp(
                r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
              ),
            ),
          );

          // Immediately selectable: count grew and getAll/getById find it.
          expect(await repo.count(), 8);
          final all = await repo.getAll();
          expect(
            all.map((c) => c.name),
            contains('Lácteos'),
          );
          final found = await repo.getById(created.id);
          expect(found, isNotNull);
          expect(found!.name, 'Lácteos');
        },
      );

      test('each quickCreate produces a distinct category', () async {
        final a = await repo.quickCreate('Lácteos');
        final b = await repo.quickCreate('Panadería');

        expect(a.id, isNot(b.id));
        expect(a.name, isNot(b.name));
        expect(await repo.count(), 9);
        final names = (await repo.getAll()).map((c) => c.name).toSet();
        expect(names, containsAll(['Lácteos', 'Panadería']));
      });
    });
  });
}
