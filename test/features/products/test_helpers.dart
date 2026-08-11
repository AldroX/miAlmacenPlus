import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_almacen_plus/core/data/drift/app_database.dart' as db;
import 'package:mi_almacen_plus/core/data/repositories/inventory_repository.dart';
import 'package:mi_almacen_plus/core/domain/entities/product.dart';
import 'package:mi_almacen_plus/core/providers/app_providers.dart';

/// Shared harness for products widget tests: an in-memory Drift database
/// injected through [databaseProvider] so streams and repositories are real
/// (no mocks), matching the tasks.md unit 3 runtime harness.
class TestHarness {
  TestHarness(this.container, this.database);

  final ProviderContainer container;
  final db.AppDatabase database;

  ProductRepository get products => container.read(productRepositoryProvider);
  CategoryRepository get categories => container.read(
    categoryRepositoryProvider,
  );
  UserRepository get users => container.read(userRepositoryProvider);
  InventoryMovementRepository get movements => container.read(
    movementRepositoryProvider,
  );
}

/// Creates the harness and registers teardown for this test.
Future<TestHarness> createHarness({db.AppDatabase? database}) async {
  final dbInstance = database ?? db.AppDatabase.inMemory();
  final container = ProviderContainer(
    overrides: [databaseProvider.overrideWithValue(dbInstance)],
  );
  addTearDown(container.dispose);
  addTearDown(dbInstance.close);
  return TestHarness(container, dbInstance);
}
/// Pumps [child] under the harness scope inside a plain [MaterialApp].
Future<void> pumpWithHarness(
  WidgetTester tester,
  TestHarness harness,
  Widget child,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: harness.container,
      child: MaterialApp(home: child),
    ),
  );
  await tester.pumpAndSettle();
}

/// Enlarges the test viewport so full-screen forms (ProductForm, detail) fit
/// without scrolling; resets automatically at the end of the test.
void useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Seed descriptor for [seedProduct].
class SeedSpec {
  const SeedSpec(this.name, {this.unit = 'u', this.stock = 0, this.min = 5});

  final String name;
  final String unit;
  final int stock;
  final int min;
}

/// Creates [specs] spread across [categoryA] and [categoryB] (alternating)
/// and returns the created products plus the owner/category ids.
Future<
  ({
    String userId,
    String categoryA,
    String categoryB,
    List<Product> products,
  })
> seedProducts(
  TestHarness h,
  List<SeedSpec> specs,
) async {
  final user = await h.users.getOrCreateDefault();
  final categories = await h.categories.getAll();
  final categoryA = categories[0].id;
  final categoryB = categories[1].id;

  final products = <Product>[];
  for (var i = 0; i < specs.length; i++) {
    final spec = specs[i];
    final categoryId = i.isEven ? categoryA : categoryB;
    products.add(
      await h.products.create(
        categoryId: categoryId,
        userId: user.id,
        name: spec.name,
        unit: spec.unit,
        minimumStock: spec.min,
        initialStock: spec.stock,
      ),
    );
  }
  return (
    userId: user.id,
    categoryA: categoryA,
    categoryB: categoryB,
    products: products,
  );
}
