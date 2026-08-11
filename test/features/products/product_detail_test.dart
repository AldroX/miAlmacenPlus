import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_almacen_plus/features/products/product_detail_screen.dart';

import 'test_helpers.dart';

/// ProductDetail (design D8): full screen with inline edit. Edits touch
/// descriptive fields ONLY — currentStock is read-only (spec 3.2).
void main() {
  group('ProductDetailScreen', () {
    testWidgets('renders stock, status chip and descriptive fields', (
      tester,
    ) async {
      useTallViewport(tester);
      final h = await createHarness();
      final seeded = await seedProducts(h, const [
        SeedSpec('Café', unit: 'kg', stock: 20, min: 5),
      ]);
      final product = seeded.products.first;

      await pumpWithHarness(
        tester,
        h,
        ProductDetailScreen(productId: product.id),
      );

      expect(find.text('Café'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(find.text('Unidades'), findsOneWidget);
      expect(find.text('STOCK SALUDABLE'), findsOneWidget);
      expect(find.text('Categoría: Alimentos'), findsOneWidget);
      expect(find.textContaining('SKU: PROD-'), findsOneWidget);
      // Recent history card shows the INITIAL_STOCK IN 20 movement.
      expect(find.text('Historial Reciente'), findsOneWidget);
      expect(find.text('Stock Inicial'), findsOneWidget);
      expect(find.text('+20'), findsOneWidget);
    });

    testWidgets('inline edit changes descriptive fields, stock stays', (
      tester,
    ) async {
      useTallViewport(tester);
      final h = await createHarness();
      final seeded = await seedProducts(h, const [
        SeedSpec('Café', unit: 'kg', stock: 20, min: 5),
      ]);
      final product = seeded.products.first;

      await pumpWithHarness(
        tester,
        h,
        ProductDetailScreen(productId: product.id),
      );

      // Enter edit mode.
      await tester.tap(find.byKey(const Key('edit-product')));
      await tester.pumpAndSettle();

      // currentStock is presented read-only, never editable.
      expect(find.byKey(const Key('current-stock-readonly')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('current-stock-readonly')),
          matching: find.text('20'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('product-initial-stock')), findsNothing);

      await tester.enterText(
        find.byKey(const Key('product-name')),
        'Café molido',
      );
      await tester.tap(find.byKey(const Key('product-form-submit')));
      await tester.pumpAndSettle();

      // Name changed, stock untouched (repo.update never writes currentStock).
      expect(find.text('Café molido'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      final updated = await h.products.getById(product.id);
      expect(updated!.name, 'Café molido');
      expect(updated.currentStock, 20);
    });

    testWidgets('validation blocks an empty name during inline edit', (
      tester,
    ) async {
      useTallViewport(tester);
      final h = await createHarness();
      final seeded = await seedProducts(h, const [
        SeedSpec('Café', stock: 20, min: 5),
      ]);
      final product = seeded.products.first;

      await pumpWithHarness(
        tester,
        h,
        ProductDetailScreen(productId: product.id),
      );
      await tester.tap(find.byKey(const Key('edit-product')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('product-name')), '');
      await tester.tap(find.byKey(const Key('product-form-submit')));
      await tester.pumpAndSettle();

      expect(find.text('El nombre es obligatorio'), findsOneWidget);
      // Still in edit mode, nothing persisted.
      final updated = await h.products.getById(product.id);
      expect(updated!.name, 'Café');
    });
  });
}
