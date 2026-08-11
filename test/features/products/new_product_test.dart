import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_almacen_plus/core/domain/movement_reason.dart';
import 'package:mi_almacen_plus/features/products/new_product_screen.dart';

import 'test_helpers.dart';

/// Create flow (spec 3.1): a valid submit persists the product with initial
/// stock AND one INITIAL_STOCK movement; the inline quick-create (spec 3.3)
/// creates a category and makes it immediately selectable.
void main() {
  group('NewProductScreen create flow', () {
    testWidgets('creates product with initial stock and INITIAL_STOCK movement',
        (tester) async {
      useTallViewport(tester);
      final h = await createHarness();
      await pumpWithHarness(tester, h, const NewProductScreen());

      await tester.enterText(find.byKey(const Key('product-name')), 'Café');
      await tester.enterText(find.byKey(const Key('product-unit')), 'kg');
      await tester.enterText(
        find.byKey(const Key('product-min-stock')),
        '5',
      );
      await tester.enterText(
        find.byKey(const Key('product-initial-stock')),
        '20',
      );
      await tester.enterText(
        find.byKey(const Key('product-description')),
        'Grano tostado',
      );
      await tester.tap(find.byKey(const Key('product-form-submit')));
      await tester.pumpAndSettle();

      // Persisted through the repository → real Drift rows.
      final products = await h.products.getAll();
      expect(products, hasLength(1));
      expect(products.first.name, 'Café');
      expect(products.first.unit, 'kg');
      expect(products.first.minimumStock, 5);
      expect(products.first.description, 'Grano tostado');
      expect(products.first.currentStock, 20);

      // Spec 3.1 Sc.1: initial quantity creates an INITIAL_STOCK IN movement.
      final movements = await h.movements.getForProduct(products.first.id);
      expect(movements, hasLength(1));
      expect(movements.first.reason, MovementReason.initialStock);
      expect(movements.first.quantity, 20);
      expect(movements.first.stockBefore, 0);
      expect(movements.first.stockAfter, 20);
    });

    testWidgets('quick-create makes a new category selectable and usable',
        (tester) async {
      useTallViewport(tester);
      final h = await createHarness();
      await pumpWithHarness(tester, h, const NewProductScreen());

      // Inline quick-create (spec 3.3 Sc.1).
      await tester.enterText(
        find.byKey(const Key('quick-create-category')),
        'Verduras',
      );
      await tester.tap(find.byKey(const Key('quick-create-add')));
      await tester.pumpAndSettle();

      final categories = await h.categories.getAll();
      final verduras =
          categories.where((c) => c.name == 'Verduras').toList();
      expect(verduras, hasLength(1));

      // Select the brand-new category in the dropdown.
      await tester.tap(find.byKey(const Key('product-category')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Verduras').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('product-name')), 'Tomate');
      await tester.enterText(find.byKey(const Key('product-unit')), 'kg');
      await tester.enterText(
        find.byKey(const Key('product-initial-stock')),
        '4',
      );
      await tester.tap(find.byKey(const Key('product-form-submit')));
      await tester.pumpAndSettle();

      final products = await h.products.getAll();
      expect(products, hasLength(1));
      expect(products.first.categoryId, verduras.first.id);
    });
  });
}
