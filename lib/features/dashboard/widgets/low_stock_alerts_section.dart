import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_almacen_plus/core/domain/entities/product.dart';
import 'package:mi_almacen_plus/core/domain/stock_status.dart';
import 'package:mi_almacen_plus/core/domain/stock_status_of.dart';
import 'package:mi_almacen_plus/core/providers/stream_providers.dart';
import 'package:mi_almacen_plus/core/theme/app_theme.dart';

/// Low-stock alerts tile (figma dash 5.1 section 4) — the products whose
/// [stockStatusOf] is low or out of stock, surfaced as a card with a
/// "current/min" badge per row. Empty state shows a muted line so the surface
/// isn't blank (operate: teach, don't "nothing here").
class LowStockAlertsSection extends ConsumerWidget {
  const LowStockAlertsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final products = ref.watch(productsStreamProvider).value ?? const <Product>[];

    final alerts = <Product>[
      for (final p in products)
        if (stockStatusOf(p.currentStock, p.minimumStock) !=
            StockStatus.normal)
          p,
    ];

    final shadow = theme.extension<AppThemeExtra>()?.cardShadow ??
        AppThemeExtra.light.cardShadow;
    final radius = BorderRadius.circular(AppTokens.borderRadiusMd);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: radius,
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: shadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_outlined,
                  size: 20,
                  color: cs.tertiary,
                ),
                const SizedBox(width: AppTokens.stackSm),
                Text(
                  'Alertas de Stock',
                  style: theme.textTheme.headlineMedium,
                ),
              ],
            ),
            const SizedBox(height: AppTokens.stackMd),
            if (alerts.isEmpty) ...[
              Text(
                'Todo tu stock está en buen estado',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ] else ...[
              for (var i = 0; i < alerts.length; i++) ...[
                _AlertItem(product: alerts[i]),
                if (i != alerts.length - 1)
                  const SizedBox(height: AppTokens.stackSm),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  const _AlertItem({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final status = stockStatusOf(product.currentStock, product.minimumStock);
    // Low stock -> amber (tertiary); out of stock -> coral (error).
    final badgeColor = status == StockStatus.outOfStock
        ? cs.error
        : cs.tertiary;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTokens.borderRadiusSm),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.marginMobile,
        vertical: AppTokens.stackSm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            product.name,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 20 / 14,
            ).copyWith(color: cs.onSurface),
          ),
          Text(
            '${product.currentStock}/${product.minimumStock}',
            style: AppTheme.labelStock.copyWith(color: badgeColor),
          ),
        ],
      ),
    );
  }
}
