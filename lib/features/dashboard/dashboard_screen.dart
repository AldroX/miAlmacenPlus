import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_almacen_plus/core/domain/entities/product.dart';
import 'package:mi_almacen_plus/core/domain/stock_status.dart';
import 'package:mi_almacen_plus/core/domain/stock_status_of.dart';
import 'package:mi_almacen_plus/core/providers/stream_providers.dart';
import 'package:mi_almacen_plus/core/theme/app_theme.dart';
import 'package:mi_almacen_plus/features/dashboard/widgets/low_stock_alerts_section.dart';
import 'package:mi_almacen_plus/features/dashboard/widgets/recent_movements_section.dart';
import 'package:mi_almacen_plus/features/dashboard/widgets/summary_stat_card.dart';

/// Dashboard (figma dash 5.1, design D11): greeting, summary stat cards,
/// low-stock alerts and recent movements, all fed by reactive providers so the
/// surface refreshes live after every movement without manual invalidation.
///
/// Navigation: the FAB opens the product list so the user can pick a product to
/// record a movement against; the bottom nav is owned by [AppShell] and is not
/// duplicated here.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final products = ref.watch(productsStreamProvider).value ?? <Product>[];

    var low = 0;
    for (final product in products) {
      final status = stockStatusOf(product.currentStock, product.minimumStock);
      if (status == StockStatus.lowStock || status == StockStatus.outOfStock) {
        low++;
      }
    }

    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Icon(Icons.menu, size: 20, color: cs.primary),
        title: Text(
          'Mi Almacén',
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ).copyWith(color: cs.primary),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.notifications_outlined, size: 20, color: cs.primary),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.marginMobile),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppTokens.stackLg),
            Text(
              '¡Hola${user == null ? '!' : ', ${user.name}!'}',
              style: theme.textTheme.displayMedium,
            ),
            const SizedBox(height: AppTokens.stackSm),
            Text(
              'Aquí está el resumen de tu inventario.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTokens.stackLg),
            Row(
              children: [
                Expanded(
                  child: SummaryStatCard(
                    icon: Icons.inventory_2_outlined,
                    label: 'Total Productos',
                    value: '${products.length}',
                    accentColor: cs.primary,
                  ),
                ),
                const SizedBox(width: AppTokens.stackMd),
                Expanded(
                  child: SummaryStatCard(
                    icon: Icons.warning_amber_outlined,
                    label: 'Stock Bajo',
                    value: '$low',
                    accentColor: cs.tertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.stackLg),
            const LowStockAlertsSection(),
            const SizedBox(height: AppTokens.stackLg),
            const RecentMovementsSection(),
          ],
        ),
      ),
      floatingActionButton: _DashboardFab(),
    );
  }
}

/// 56x56, primary, 12px radius FAB (figma dash 5.1) — navigate to the product
/// list so the user picks a product before recording a movement.
class _DashboardFab extends StatelessWidget {
  const _DashboardFab();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            spreadRadius: -4,
            offset: Offset(0, 4),
            color: Color(0x1A000000), // 10% opacity
          ),
          BoxShadow(
            blurRadius: 15,
            spreadRadius: -3,
            offset: Offset(0, 10),
            color: Color(0x0D000000), // 5% opacity
          ),
        ],
      ),
        child: FloatingActionButton(
         heroTag: 'dashboard-fab',
         onPressed: () => GoRouter.of(context).go('/products'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.borderRadiusMd),
        ),
        child: const Icon(Icons.add, size: 17.5),
      ),
    );
  }
}
