import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_almacen_plus/core/domain/entities/product.dart';
import 'package:mi_almacen_plus/core/domain/stock_status.dart';
import 'package:mi_almacen_plus/core/domain/stock_status_of.dart';
import 'package:mi_almacen_plus/core/providers/stream_providers.dart';
import 'package:mi_almacen_plus/core/theme/app_theme.dart';

/// Dashboard aggregates (spec 5.1, design D11): totals and low/out-of-stock
/// counts derived from the products stream with [stockStatusOf]. Refreshes
/// reactively — no manual invalidation.
///
/// Minimal functional version for slice 3 (route + shell tab); phase 4 adds
/// the recent-movements tile and empty/loading polish (task 4.1).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final products =
        ref.watch(productsStreamProvider).value ?? const <Product>[];

    var low = 0;
    var out = 0;
    for (final product in products) {
      final status = stockStatusOf(product.currentStock, product.minimumStock);
      if (status == StockStatus.lowStock) low++;
      if (status == StockStatus.outOfStock) out++;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Almacén')),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.marginMobile),
        children: [
          _StatCard(
            label: 'Productos activos',
            value: '${products.length}',
            accent: theme.colorScheme.primary,
          ),
          const SizedBox(height: AppTokens.stackMd),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Stock bajo',
                  value: '$low',
                  accent: theme.colorScheme.tertiary,
                ),
              ),
              const SizedBox(width: AppTokens.gutter),
              Expanded(
                child: _StatCard(
                  label: 'Agotados',
                  value: '$out',
                  accent: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTokens.gutter),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTokens.borderRadiusXl),
        boxShadow: theme.extension<AppThemeExtra>()?.cardShadow ??
            AppThemeExtra.light.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppTokens.gutter),
          Expanded(
            child: Text(label, style: theme.textTheme.bodyLarge),
          ),
          Text(value, style: AppTheme.displayStock.copyWith(color: theme.colorScheme.onSurface)),
        ],
      ),
    );
  }
}
