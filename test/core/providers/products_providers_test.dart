import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_almacen_plus/core/data/drift/app_database.dart';
import 'package:mi_almacen_plus/core/data/repositories/inventory_repository.dart';
import 'package:mi_almacen_plus/core/domain/stock_status.dart';
import 'package:mi_almacen_plus/core/providers/app_providers.dart';
import 'package:mi_almacen_plus/core/providers/stream_providers.dart';
import 'package:mi_almacen_plus/features/products/products_providers.dart';

/// Provider wiring (design D11): StreamProviders over the DAO watch() streams
/// + a filter Notifier (search / status / category chips) applied in Dart.
void main() {
  group('products providers (design D11)', () {
    late AppDatabase db;
    late ProviderContainer container;

    late CategoryRepository categoryRepo;
    late ProductRepository productRepo;
    late UserRepository userRepo;

    String userId = '';
    String categoryA = '';
    String categoryB = '';

    setUp(() async {
      db = AppDatabase.inMemory();
      container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);

      categoryRepo = container.read(categoryRepositoryProvider);
      productRepo = container.read(productRepositoryProvider);
      userRepo = container.read(userRepositoryProvider);

      final user = await userRepo.getOrCreateDefault();
      userId = user.id;
      final categories = await categoryRepo.getAll();
      categoryA = categories[0].id;
      categoryB = categories[1].id;
    });

    Future<void> seedProducts() async {
      await productRepo.create(
        categoryId: categoryA,
        userId: userId,
        name: 'Café',
        unit: 'kg',
        minimumStock: 5,
        initialStock: 10, // normal (10 > 5)
      );
      await productRepo.create(
        categoryId: categoryA,
        userId: userId,
        name: 'Azúcar',
        unit: 'kg',
        minimumStock: 5,
        initialStock: 3, // low (0 < 3 <= 5)
      );
      await productRepo.create(
        categoryId: categoryB,
        userId: userId,
        name: 'Sal',
        unit: 'g',
        minimumStock: 5,
        initialStock: 0, // out of stock (checked first)
      );
      await container.read(productsStreamProvider.future);
    }

    List<String> visibleNames() => container
        .read(filteredProductsProvider)
        .map((p) => p.name)
        .toList();

    test('currentUserProvider yields the seeded owner', () async {
      final user = await container.read(currentUserProvider.future);
      expect(user.name, 'Dueño');
      expect(user.id, isNotEmpty);
    });

    test('default filter returns every active product', () async {
      await seedProducts();
      expect(visibleNames(), containsAll(['Café', 'Azúcar', 'Sal']));
      expect(visibleNames().length, 3);
    });

    test('search filters by name, case-insensitive', () async {
      await seedProducts();
      container.read(productsFilterProvider.notifier).setSearch('café');
      expect(visibleNames(), ['Café']);
    });

    test('status chip lowStock keeps only low-stock products', () async {
      await seedProducts();
      container
          .read(productsFilterProvider.notifier)
          .setStatus(StockStatus.lowStock);
      expect(visibleNames(), ['Azúcar']);
    });

    test('status chip outOfStock keeps only out-of-stock products', () async {
      await seedProducts();
      container
          .read(productsFilterProvider.notifier)
          .setStatus(StockStatus.outOfStock);
      expect(visibleNames(), ['Sal']);
    });

    test('category chip keeps only that category', () async {
      await seedProducts();
      container.read(productsFilterProvider.notifier).setCategory(categoryB);
      expect(visibleNames(), ['Sal']);
    });

    test('search + status + category combine', () async {
      await seedProducts();
      final notifier = container.read(productsFilterProvider.notifier);
      notifier.setSearch('a');
      notifier.setStatus(StockStatus.normal);
      notifier.setCategory(categoryA);
      expect(visibleNames(), ['Café']);
    });

    test('clear() resets every filter', () async {
      await seedProducts();
      final notifier = container.read(productsFilterProvider.notifier);
      notifier.setSearch('Sal');
      notifier.setStatus(StockStatus.normal);
      notifier.setCategory(categoryA);
      notifier.clear();
      expect(visibleNames().length, 3);
    });

    test('categoriesStreamProvider exposes the 7 seeds', () async {
      final categories = await container.read(categoriesStreamProvider.future);
      expect(categories.length, 7);
      expect(categories.first.name, isNotEmpty);
    });
  });
}
