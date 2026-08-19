import 'package:flutter_test/flutter_test.dart';
import 'package:mi_almacen_plus/core/domain/movement_reason.dart';
import 'package:mi_almacen_plus/features/inventory/history_screen.dart';
import '../products/test_helpers.dart';

void main() {
  group('HistoryScreen', () {
    testWidgets('renders movement history for a product', (tester) async {
      final h = await createHarness();
      final seeded = await seedProducts(h, [
        const SeedSpec('Leche', stock: 10, min: 5),
      ]);

      // Add a movement
      await h.products.recordMovement(
        productId: seeded.products.first.id,
        userId: seeded.userId,
        reason: MovementReason.sale,
        quantity: 3,
      );

      await pumpWithHarness(tester, h, HistoryScreen(productId: seeded.products.first.id));

      // Should show the history
      expect(find.text('Historial'), findsOneWidget);
      expect(find.text('Venta Mostrador'), findsOneWidget);
      expect(find.text('-3'), findsOneWidget);
      // Two movements: INITIAL_STOCK (0→10) and sale (10→7)
      expect(find.textContaining('→'), findsNWidgets(2));
    });

    testWidgets('shows INITIAL_STOCK movement for new product', (tester) async {
      final h = await createHarness();
      final seeded = await seedProducts(h, [
        const SeedSpec('Leche', stock: 10, min: 5),
      ]);

      await pumpWithHarness(tester, h, HistoryScreen(productId: seeded.products.first.id));

      expect(find.text('Historial'), findsOneWidget);
      expect(find.text('Stock Inicial'), findsOneWidget);
      expect(find.text('+10'), findsOneWidget);
      expect(find.textContaining('→'), findsOneWidget); // 0 → 10
    });

    testWidgets('shows empty state for non-existent product', (tester) async {
      final h = await createHarness();

      await pumpWithHarness(tester, h, HistoryScreen(productId: 'non-existent-id'));

      expect(find.text('Historial'), findsOneWidget);
      expect(find.text('Sin movimientos todavía'), findsOneWidget);
    });
  });
}