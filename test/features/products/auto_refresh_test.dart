import 'package:flutter_test/flutter_test.dart';
import 'package:mi_almacen_plus/core/domain/movement_reason.dart';
import 'package:mi_almacen_plus/features/products/products_screen.dart';

import 'test_helpers.dart';

/// Spec 6.3: GIVEN the products list is open; WHEN a movement is registered
/// elsewhere (another screen, another device sync, a background task); THEN
/// the list updates automatically — no manual refresh, no invalidation.
/// Proves the Riverpod-over-Drift stream wiring (design D11).
void main() {
  group('ProductsScreen auto-refresh (spec 6.3)', () {
    testWidgets('list reflects a movement registered elsewhere',
        (tester) async {
      final h = await createHarness();
      final seeded = await seedProducts(h, const [
        SeedSpec('Café', unit: 'kg', stock: 10, min: 5),
      ]);
      final product = seeded.products.first;

      await pumpWithHarness(tester, h, const ProductsScreen());
      expect(find.text('10'), findsOneWidget);

      // Movement registered OUTSIDE the UI — straight through the repository,
      // as the movement sheet would do (spec 6.3 "movement registered
      // elsewhere").
      await h.products.recordMovement(
        productId: product.id,
        userId: seeded.userId,
        reason: MovementReason.sale,
        quantity: 3,
      );
      await tester.pumpAndSettle();

      // The card now shows 10 - 3 = 7, with no manual refresh.
      expect(find.text('7'), findsOneWidget);
      expect(find.text('10'), findsNothing);

      // An IN movement bumps it back up — second emission, same stream.
      await h.products.recordMovement(
        productId: product.id,
        userId: seeded.userId,
        reason: MovementReason.purchase,
        quantity: 5,
      );
      await tester.pumpAndSettle();
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('soft delete removes the card live', (tester) async {
      final h = await createHarness();
      final seeded = await seedProducts(h, const [
        SeedSpec('Café', stock: 10, min: 5),
        SeedSpec('Sal', stock: 3, min: 5),
      ]);

      await pumpWithHarness(tester, h, const ProductsScreen());
      expect(find.text('Café'), findsOneWidget);

      await h.products.softDelete(seeded.products[0].id);
      await tester.pumpAndSettle();

      expect(find.text('Café'), findsNothing);
      expect(find.text('Sal'), findsOneWidget);
    });
  });
}
