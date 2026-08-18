import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_almacen_plus/core/data/drift/app_database.dart';
import 'package:mi_almacen_plus/core/domain/movement_reason.dart';
import 'package:mi_almacen_plus/core/providers/app_providers.dart';
import 'package:mi_almacen_plus/core/routing/app_router.dart';
import 'package:mi_almacen_plus/main.dart';

import '../../features/products/test_helpers.dart';

/// App shell + go_router (design D7, spec 6.1): every route is reachable —
/// /dashboard, /products, /products/new, /products/:id,
/// /products/:id/movement (modal bottom sheet), /products/:id/history —
/// through the real MaterialApp.router bootstrap in main.dart.
void main() {
  group('App shell and routes (design D7)', () {
    Future<({AppDatabase db, TestHarness harness})> pumpApp(
      WidgetTester tester,
    ) async {
      useTallViewport(tester);
      final db = AppDatabase.inMemory();
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          // Fresh router per test: the global `appRouter` singleton would
          // otherwise keep its navigator state between test cases.
          child: MiAlmacenApp(router: buildAppRouter()),
        ),
      );
      await tester.pumpAndSettle();
      return (db: db, harness: TestHarness(container, db));
    }

    testWidgets('starts at /dashboard inside the shell', (tester) async {
      await pumpApp(tester);
      expect(find.text('Mi Almacén'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Productos'), findsOneWidget);
      expect(find.text('Movimientos'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);
    });

    testWidgets('bottom navigation switches to the products branch', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Productos'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('products-search')), findsOneWidget);
      expect(find.text('No hay productos todavía'), findsOneWidget);
    });

    testWidgets('bottom navigation switches to the movements list', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Movimientos'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Movimientos'), findsOneWidget);
      expect(find.text('Aún no hay movimientos'), findsOneWidget);
    });

    testWidgets('/movements renders list with data', (tester) async {
      final app = await pumpApp(tester);
      final seeded = await seedProducts(app.harness, const [
        SeedSpec('Leche', stock: 10, min: 5),
      ]);

      // Record a movement
      await app.harness.products.recordMovement(
        productId: seeded.products.first.id,
        userId: seeded.userId,
        reason: MovementReason.purchase,
        quantity: 5,
      );

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Movimientos'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Movimientos'), findsOneWidget);
      expect(find.text('Leche'), findsWidgets);
      expect(find.text('+10'), findsOneWidget); // INITIAL_STOCK
      expect(find.text('+5'), findsOneWidget);  // purchase
      expect(find.textContaining('Hoy'), findsWidgets);
    });

    testWidgets('bottom navigation switches to the profile placeholder', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Perfil'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Perfil'), findsOneWidget);
    });

    testWidgets('/products/new shows the create form', (tester) async {
      await pumpApp(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Productos'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('products-fab')));
      await tester.pumpAndSettle();

      expect(find.text('Crear Producto'), findsOneWidget);
      expect(find.byKey(const Key('product-name')), findsOneWidget);
      expect(find.byKey(const Key('product-initial-stock')), findsOneWidget);
    });

    testWidgets('/products/:id renders the product detail', (tester) async {
      final app = await pumpApp(tester);
      final seeded = await seedProducts(app.harness, const [
        SeedSpec('Café', unit: 'kg', stock: 20, min: 5),
      ]);
      final product = seeded.products.first;

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Productos'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('product-card-${product.id}')));
      await tester.pumpAndSettle();

      expect(find.text('Café'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(find.byKey(const Key('edit-product')), findsOneWidget);
    });

    testWidgets('/products/:id/history lists the movement trail', (
      tester,
    ) async {
      final app = await pumpApp(tester);
      final seeded = await seedProducts(app.harness, const [
        SeedSpec('Café', stock: 10, min: 5),
      ]);
      final product = seeded.products.first;

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Productos'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('product-card-${product.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('open-history')));
      await tester.pumpAndSettle();

      expect(find.text('Historial'), findsOneWidget);
      // INITIAL_STOCK IN 10: stockBefore 0 → stockAfter 10.
      expect(find.text('0 → 10'), findsOneWidget);
      expect(find.text('Stock Inicial'), findsOneWidget);
    });

    testWidgets('/products/:id/movement opens a bottom sheet (design D8)', (
      tester,
    ) async {
      final app = await pumpApp(tester);
      final seeded = await seedProducts(app.harness, const [
        SeedSpec('Café', unit: 'kg', stock: 10, min: 5),
      ]);
      final product = seeded.products.first;

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Productos'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('product-card-${product.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('open-movement')));
      await tester.pumpAndSettle();

      // The sheet (modal bottom sheet page, D7) shows Entrada/Salida controls.
      expect(find.byKey(const Key('movement-quantity')), findsOneWidget);
      expect(find.text('Entrada'), findsOneWidget);
      expect(find.text('Salida'), findsOneWidget);
    });
  });
}
