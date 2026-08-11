import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_almacen_plus/core/domain/movement_type.dart';
import 'package:mi_almacen_plus/core/providers/stream_providers.dart';
import 'package:mi_almacen_plus/core/theme/app_theme.dart';

/// Movement history for a product — full screen (design D8). Lists the trail
/// newest-first: reason, quantity, date and stockBefore → stockAfter
/// (spec 4.2).
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncMovements = ref.watch(movementsForProductProvider(productId));

    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: asyncMovements.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Error al cargar el historial')),
        data: (movements) {
          if (movements.isEmpty) {
            return const Center(child: Text('Sin movimientos todavía'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppTokens.marginMobile),
            itemCount: movements.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final movement = movements[index];
              final isIncoming = movement.type == MovementType.incoming;
              final accent = isIncoming
                  ? theme.colorScheme.secondary
                  : theme.colorScheme.error;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: accent.withValues(alpha: 0.12),
                  child: Icon(
                    isIncoming
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: accent,
                  ),
                ),
                title: Text(
                  movement.reason.label,
                  style: theme.textTheme.titleSmall,
                ),
                subtitle: Text('${movement.stockBefore} → ${movement.stockAfter}'),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${isIncoming ? '+' : '-'}${movement.quantity}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatDate(movement.occurredAt),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} '
        '${two(date.hour)}:${two(date.minute)}';
  }
}
