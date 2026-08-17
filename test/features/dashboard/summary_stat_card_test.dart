import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_almacen_plus/features/dashboard/widgets/summary_stat_card.dart';

void main() {
  testWidgets('SummaryStatCard renders label and value', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SummaryStatCard(
            icon: Icons.inventory_2_outlined,
            label: 'Total Productos',
            value: '12',
            accentColor: Colors.blue,
          ),
        ),
      ),
    );

    expect(find.text('Total Productos'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('SummaryStatCard fires onTap when tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SummaryStatCard(
            icon: Icons.warning_amber_outlined,
            label: 'Stock Bajo',
            value: '3',
            accentColor: Colors.amber,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Stock Bajo'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });

  testWidgets('SummaryStatCard renders value bound to input (not hardcoded)',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SummaryStatCard(
            icon: Icons.inventory_2_outlined,
            label: 'Total Productos',
            value: '127',
            accentColor: Colors.blue,
          ),
        ),
      ),
    );

    expect(find.text('127'), findsOneWidget);
    expect(find.text('Total Productos'), findsOneWidget);
    // No onTap → card renders inert (no gesture recognizer attached).
    expect(find.byType(InkWell), findsNothing);
  });
}
