import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_almacen_plus/core/data/drift/app_database.dart' as db;
import 'package:mi_almacen_plus/core/domain/entities/inventory_movement.dart';
import 'package:mi_almacen_plus/core/domain/movement_reason.dart';
import 'package:mi_almacen_plus/core/providers/app_providers.dart';
import 'package:mi_almacen_plus/core/providers/stream_providers.dart';
import 'package:mi_almacen_plus/features/inventory/movements_screen.dart';
import '../products/test_helpers.dart';

void main() {
  group('MovementsScreen (global movements list)', () {
    testWidgets('renders empty state when no movements exist', (tester) async {
      final h = await createHarness();
      await pumpWithHarness(tester, h, const MovementsScreen());

      expect(find.text('Aún no hay movimientos'), findsOneWidget);
      expect(find.byType(CustomScrollView), findsNothing);
    });

    testWidgets('renders list with product names, timestamps, and signed quantities', (
      tester,
    ) async {
      final h = await createHarness();
      final seeded = await seedProducts(h, [
        const SeedSpec('Leche', stock: 10, min: 5),
        const SeedSpec('Pan', stock: 8, min: 5),
      ]);

      // Record an incoming movement (purchase) on Leche
      await h.products.recordMovement(
        productId: seeded.products[0].id,
        userId: seeded.userId,
        reason: MovementReason.purchase,
        quantity: 5,
      );

      // Record an outgoing movement (sale) on Pan
      await h.products.recordMovement(
        productId: seeded.products[1].id,
        userId: seeded.userId,
        reason: MovementReason.sale,
        quantity: 3,
      );

      await pumpWithHarness(tester, h, const MovementsScreen());

      // Verify list renders (CustomScrollView with SliverList)
      expect(find.byType(CustomScrollView), findsOneWidget);
      // Product names - each product appears once per movement
      // Leche has INITIAL_STOCK (+10) + purchase (+5) = 2 movements
      // Pan has INITIAL_STOCK (+8) + sale (-3) = 2 movements
      expect(find.text('Leche'), findsNWidgets(2));
      expect(find.text('Pan'), findsNWidgets(2));
      // Quantities with signs
      expect(find.text('+10'), findsOneWidget); // INITIAL_STOCK Leche
      expect(find.text('+5'), findsOneWidget); // purchase Leche
      expect(find.text('+8'), findsOneWidget); // INITIAL_STOCK Pan
      expect(find.text('-3'), findsOneWidget); // sale Pan
      // Date group header
      expect(find.text('Hoy'), findsOneWidget);
    });

    testWidgets('renders error state when stream fails', (tester) async {
      // Create a container with an error override
      final database = db.AppDatabase.inMemory();
      addTearDown(database.close);

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
          allMovementsProvider.overrideWith(
            (ref) => Stream<List<InventoryMovement>>.error(Exception('stream failed')),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: const MovementsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Error al cargar el historial'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('reactive update: new movement appears at top of list', (
      tester,
    ) async {
      final h = await createHarness();
      final seeded = await seedProducts(h, [
        const SeedSpec('Leche', stock: 10, min: 5),
      ]);

      // Initial movement (purchase)
      await h.products.recordMovement(
        productId: seeded.products.first.id,
        userId: seeded.userId,
        reason: MovementReason.purchase,
        quantity: 5,
      );
      await pumpWithHarness(tester, h, const MovementsScreen());

      // Verify initial movements render (INITIAL_STOCK + purchase = 2 items)
      expect(find.text('+10'), findsOneWidget); // INITIAL_STOCK
      expect(find.text('+5'), findsOneWidget); // purchase

      // Add a new movement (sale)
      await h.products.recordMovement(
        productId: seeded.products.first.id,
        userId: seeded.userId,
        reason: MovementReason.sale,
        quantity: 2,
      );
      await tester.pumpAndSettle();

      // New movement (sale, -2) should appear at top (newest first)
      expect(find.text('-2'), findsOneWidget);
      // All three movements visible
      expect(find.text('+10'), findsOneWidget);
      expect(find.text('+5'), findsOneWidget);
    });
  });
}
