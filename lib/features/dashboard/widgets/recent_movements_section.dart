import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_almacen_plus/core/domain/entities/inventory_movement.dart';
import 'package:mi_almacen_plus/core/domain/entities/product.dart';
import 'package:mi_almacen_plus/core/domain/movement_type.dart';
import 'package:mi_almacen_plus/core/providers/stream_providers.dart';
import 'package:mi_almacen_plus/core/theme/app_theme.dart';

/// Recent movements tile (figma dash 5.1 section 5) — the newest movements
/// across all products, newest-first. Product names are resolved from the
/// products stream so the row shows a friendly name instead of an id. Empty
/// state shows a muted line rather than a blank surface.
class RecentMovementsSection extends ConsumerWidget {
  const RecentMovementsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final movements =
        ref.watch(recentMovementsProvider).value ?? const <InventoryMovement>[];
    final products =
        ref.watch(productsStreamProvider).value ?? const <Product>[];

    final nameOf = <String, String>{
      for (final p in products) p.id: p.name,
    };

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
            Text('Movimientos Recientes', style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppTokens.stackMd),
            if (movements.isEmpty) ...[
              Text(
                'Aún no hay movimientos',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ] else ...[
              for (var i = 0; i < movements.length; i++) ...[
                _MovementItem(
                  movement: movements[i],
                  productName: nameOf[movements[i].productId] ?? '—',
                ),
                if (i != movements.length - 1)
                  const SizedBox(height: AppTokens.stackSm),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _MovementItem extends StatelessWidget {
  const _MovementItem({required this.movement, required this.productName});

  final InventoryMovement movement;
  final String productName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isIncoming = movement.type == MovementType.incoming;
    final dotColor = isIncoming ? cs.secondaryContainer : cs.errorContainer;
    final isOutgoing = !isIncoming;
    final quantityColor = isOutgoing ? cs.error : cs.secondary;
    final prefix = isOutgoing ? '-' : '+';

    // "Hoy 10:30" / "Ayer 16:45" relative date (spec figma dash 5.1).
    final timestamp = _formatTimestamp(movement.occurredAt);

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppTokens.stackMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                productName,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 20 / 14,
                ).copyWith(color: cs.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                timestamp,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Text(
          '$prefix${movement.quantity}',
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            height: 28 / 20,
          ).copyWith(color: quantityColor),
        ),
      ],
    );
  }
}

/// Formats a movement [time] as "Hoy 10:30", "Ayer 16:45", or "dd/MM HH:mm".
String _formatTimestamp(DateTime time) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final day = DateTime(time.year, time.month, time.day);

  String dayLabel;
  if (day == today) {
    dayLabel = 'Hoy';
  } else if (day == yesterday) {
    dayLabel = 'Ayer';
  } else {
    dayLabel = '${time.day.toString().padLeft(2, '0')}/'
        '${time.month.toString().padLeft(2, '0')}';
  }
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$dayLabel $hour:$minute';
}
