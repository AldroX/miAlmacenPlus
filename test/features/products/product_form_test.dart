import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_almacen_plus/features/products/new_product_screen.dart';

import 'test_helpers.dart';

/// ProductForm validation (spec 3.1): name/unit required, minimum stock and
/// initial quantity must not be negative. Errors surface in Spanish.
void main() {
  group('NewProductScreen validation (spec 3.1)', () {
    Future<void> pumpNewProduct(WidgetTester tester, TestHarness h) {
      useTallViewport(tester);
      return pumpWithHarness(tester, h, const NewProductScreen());
    }

    testWidgets('empty submit shows required-field errors', (tester) async {
      final h = await createHarness();
      await pumpNewProduct(tester, h);

      await tester.tap(find.byKey(const Key('product-form-submit')));
      await tester.pumpAndSettle();

      expect(find.text('El nombre es obligatorio'), findsOneWidget);
      expect(find.text('La unidad es obligatoria'), findsOneWidget);
    });

    testWidgets('negative minimum stock is rejected', (tester) async {
      final h = await createHarness();
      await pumpNewProduct(tester, h);

      await tester.enterText(
        find.byKey(const Key('product-name')),
        'Café',
      );
      await tester.enterText(find.byKey(const Key('product-unit')), 'kg');
      await tester.enterText(
        find.byKey(const Key('product-min-stock')),
        '-2',
      );
      await tester.tap(find.byKey(const Key('product-form-submit')));
      await tester.pumpAndSettle();

      expect(
        find.text('El stock mínimo no puede ser negativo'),
        findsOneWidget,
      );
    });

    testWidgets('negative initial stock is rejected', (tester) async {
      final h = await createHarness();
      await pumpNewProduct(tester, h);

      await tester.enterText(
        find.byKey(const Key('product-name')),
        'Café',
      );
      await tester.enterText(find.byKey(const Key('product-unit')), 'kg');
      await tester.enterText(
        find.byKey(const Key('product-initial-stock')),
        '-3',
      );
      await tester.tap(find.byKey(const Key('product-form-submit')));
      await tester.pumpAndSettle();

      expect(
        find.text('La cantidad inicial no puede ser negativa'),
        findsOneWidget,
      );
    });

    testWidgets('non-numeric quantity is rejected', (tester) async {
      final h = await createHarness();
      await pumpNewProduct(tester, h);

      await tester.enterText(
        find.byKey(const Key('product-name')),
        'Café',
      );
      await tester.enterText(find.byKey(const Key('product-unit')), 'kg');
      await tester.enterText(
        find.byKey(const Key('product-initial-stock')),
        'abc',
      );
      await tester.tap(find.byKey(const Key('product-form-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Ingrese un número válido'), findsWidgets);
    });
  });
}
