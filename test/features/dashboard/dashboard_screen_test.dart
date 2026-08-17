import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_almacen_plus/core/domain/movement_reason.dart';
import 'package:mi_almacen_plus/features/dashboard/dashboard_screen.dart';
import '../products/test_helpers.dart';

void main() {
  group('DashboardScreen (figma dash 5.1)', () {
    testWidgets('renders the greeting and summary subtitle', (tester) async {
      final h = await createHarness();
      await seedProducts(h, [
        const SeedSpec('Leche', stock: 10, min: 5),
      ]);
      await pumpWithHarness(tester, h, const DashboardScreen());

      expect(find.textContaining('¡Hola'), findsOneWidget);
      expect(find.textContaining('Aquí está el resumen'), findsOneWidget);
    });

    testWidgets('renders the two summary stat cards with counts', (tester) async {
      final h = await createHarness();
      await seedProducts(h, [
        const SeedSpec('Leche', stock: 10, min: 5),
        const SeedSpec('Azúcar', stock: 3, min: 5),
        const SeedSpec('Café', stock: 0, min: 5),
        const SeedSpec('Pan', stock: 8, min: 5),
      ]);
      await pumpWithHarness(tester, h, const DashboardScreen());

      expect(find.text('Total Productos'), findsOneWidget);
      expect(find.text('Stock Bajo'), findsOneWidget);
      // 4 products seeded -> "Total Productos" value is 4.
      expect(find.text('4'), findsOneWidget);
      // 2 low/out (Azúcar low + Café out) -> "Stock Bajo" value is 2.
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('renders low-stock alerts for low and out-of-stock products',
        (tester) async {
      final h = await createHarness();
      await seedProducts(h, [
        const SeedSpec('Azúcar', stock: 3, min: 5),
        const SeedSpec('Café', stock: 0, min: 5),
        const SeedSpec('Pan', stock: 8, min: 5),
      ]);
      await pumpWithHarness(tester, h, const DashboardScreen());

      expect(find.text('Alertas de Stock'), findsOneWidget);
      // Badges are unique to the alerts section and bound to current/min stock.
      expect(find.text('3/5'), findsOneWidget); // Azúcar low: 3/5
      expect(find.text('0/5'), findsOneWidget); // Café out: 0/5
      // Normal-stock Pan has NO alert badge -> excluded (only 2 alerts exist).
      expect(find.text('8/5'), findsNothing);
    });

    testWidgets('renders recent movements with +/- quantity prefixes',
        (tester) async {
      final h = await createHarness();
      final seeded = await seedProducts(h, [
        const SeedSpec('Leche', stock: 10, min: 5),
        const SeedSpec('Pan', stock: 8, min: 5),
      ]);
      // Outgoing movement on Leche -> "-2" badge.
      await h.products.recordMovement(
        productId: seeded.products.first.id,
        userId: seeded.userId,
        reason: MovementReason.sale,
        quantity: 2,
      );
      await pumpWithHarness(tester, h, const DashboardScreen());

      expect(find.text('Movimientos Recientes'), findsOneWidget);
      // Leche has INITIAL_STOCK(incoming, +10) + sale(outgoing, -2).
      expect(find.text('Leche'), findsWidgets);
      expect(find.text('+10'), findsOneWidget);
      expect(find.text('-2'), findsOneWidget);
    });

    testWidgets(
      'renders incoming (+) quantity for an added stock movement',
      (tester) async {
        final h = await createHarness();
        final seeded = await seedProducts(h, [
          const SeedSpec('Arroz', stock: 10, min: 5),
        ]);
        // Record an additional IN (purchase) movement of 5 units after seeding.
        await h.products.recordMovement(
          productId: seeded.products.first.id,
          userId: seeded.userId,
          reason: MovementReason.purchase,
          quantity: 5,
        );
        await pumpWithHarness(tester, h, const DashboardScreen());

        // Incoming movements show the "+" prefix with the quantity.
        expect(find.text('+5'), findsOneWidget);
      },
    );

    testWidgets(
      'quantity (+) stays visible with a long product name (no overflow clip)',
      (tester) async {
        final h = await createHarness();
        // Long name that used to push the quantity text off-screen.
        final seeded = await seedProducts(h, [
          const SeedSpec(
            'Arroz Grano Largo Tipo 1 Premium Especialidad Primera',
            stock: 10,
            min: 5,
          ),
        ]);
        await h.products.recordMovement(
          productId: seeded.products.first.id,
          userId: seeded.userId,
          reason: MovementReason.purchase,
          quantity: 7,
        );
        await pumpWithHarness(tester, h, const DashboardScreen());

        // Both the long name and the incoming quantity must be visible.
        expect(find.text('+7'), findsOneWidget);
      },
    );

    testWidgets('renders the 56x56 12px-radius FAB', (tester) async {
      final h = await createHarness();
      await seedProducts(h, [const SeedSpec('Leche', stock: 1, min: 5)]);
      await pumpWithHarness(tester, h, const DashboardScreen());

      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);

      final box = tester.renderObject<RenderBox>(fab.first);
      expect(box.size.width, 56);
      expect(box.size.height, 56);
    });

    testWidgets('shows empty states when there are no products or movements',
        (tester) async {
      final h = await createHarness();
      await pumpWithHarness(tester, h, const DashboardScreen());

      // Greeting still resolves to the seeded owner.
      expect(find.textContaining('¡Hola'), findsOneWidget);
      // Summary cards render zero counts.
      expect(find.text('0'), findsWidgets); // "Total Productos" + "Stock Bajo"
      // Empty-state copy for both reactive sections.
      expect(
        find.text('Todo tu stock está en buen estado'),
        findsOneWidget,
      );
      expect(find.text('Aún no hay movimientos'), findsOneWidget);
    });

    testWidgets('boundary: stock == min counts as low (amber) not normal',
        (tester) async {
      final h = await createHarness();
      await seedProducts(h, [
        const SeedSpec('Leche', stock: 5, min: 5), // exactly at minimum
      ]);
      await pumpWithHarness(tester, h, const DashboardScreen());

      expect(find.text('Stock Bajo'), findsOneWidget);
      // "5/5" proves the at-minimum product is flagged as low-stock.
      expect(find.text('5/5'), findsOneWidget);
    });
  });
}
