import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_almacen_plus/features/products/products_screen.dart';

import 'test_helpers.dart';

/// Products list behaviors (spec 3.2): render cards with stock + status chip,
/// free-text search, status chips and category chips filtering, empty state.
void main() {
  group('ProductsScreen', () {
    testWidgets('renders product cards with stock number and status chip', (
      tester,
    ) async {
      final h = await createHarness();
      final seeded = await seedProducts(h, const [
        SeedSpec('Café', unit: 'kg', stock: 10, min: 5), // normal
        SeedSpec('Sal', unit: 'g', stock: 0, min: 5), // out of stock
      ]);

      await pumpWithHarness(tester, h, const ProductsScreen());

      expect(find.text('Café'), findsOneWidget);
      expect(find.text('kg'), findsOneWidget);
      expect(find.text('g'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      // Status chips: emerald for normal, coral for out-of-stock.
      expect(
        find.descendant(
          of: find.byKey(Key('product-card-${seeded.products[0].id}')),
          matching: find.text('En stock'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(Key('product-card-${seeded.products[1].id}')),
          matching: find.text('Agotado'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('search field filters the list by name', (tester) async {
      final h = await createHarness();
      await seedProducts(h, const [
        SeedSpec('Café', stock: 10, min: 5),
        SeedSpec('Azúcar', stock: 3, min: 5),
      ]);

      await pumpWithHarness(tester, h, const ProductsScreen());
      expect(find.text('Café'), findsOneWidget);
      expect(find.text('Azúcar'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('products-search')), 'café');
      await tester.pumpAndSettle();

      expect(find.text('Café'), findsOneWidget);
      expect(find.text('Azúcar'), findsNothing);
    });

    testWidgets('category chip filters to that category only', (tester) async {
      final h = await createHarness();
      final seeded = await seedProducts(h, const [
        SeedSpec('Café', stock: 10, min: 5), // category A
        SeedSpec('Sal', stock: 5, min: 5), // category B
      ]);

      await pumpWithHarness(tester, h, const ProductsScreen());
      expect(find.text('Café'), findsOneWidget);
      expect(find.text('Sal'), findsOneWidget);

      await tester.tap(find.byKey(Key('categoryFilter-${seeded.categoryB}')));
      await tester.pumpAndSettle();

      expect(find.text('Sal'), findsOneWidget);
      expect(find.text('Café'), findsNothing);
    });

    testWidgets('"Todas" chip restores every category', (tester) async {
      final h = await createHarness();
      final seeded = await seedProducts(h, const [
        SeedSpec('Café', stock: 10, min: 5),
        SeedSpec('Sal', stock: 5, min: 5),
      ]);

      await pumpWithHarness(tester, h, const ProductsScreen());
      await tester.tap(find.byKey(Key('categoryFilter-${seeded.categoryB}')));
      await tester.pumpAndSettle();
      expect(find.text('Café'), findsNothing);

      await tester.tap(find.byKey(const Key('categoryFilter-all')));
      await tester.pumpAndSettle();
      expect(find.text('Café'), findsOneWidget);
      expect(find.text('Sal'), findsOneWidget);
    });

    testWidgets('empty state shows a friendly message', (tester) async {
      final h = await createHarness();
      await pumpWithHarness(tester, h, const ProductsScreen());
      expect(find.text('No hay productos todavía'), findsOneWidget);
    });
  });
}
