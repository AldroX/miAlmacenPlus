import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_almacen_plus/core/domain/entities/inventory_movement.dart';
import 'package:mi_almacen_plus/core/domain/entities/product.dart';
import 'package:mi_almacen_plus/core/domain/movement_type.dart';
import 'package:mi_almacen_plus/core/providers/stream_providers.dart';
import 'package:mi_almacen_plus/core/theme/app_theme.dart';

/// Global movements tab (bottom-nav branch) — full-screen reactive list of
/// all inventory movements across products, newest-first, grouped by date
/// (Hoy / Ayer / Semana Pasada / Más antiguas), with product names, signed
/// quantities, reason descriptions, and stock before/after.
///
/// Header and bottom nav are provided by AppShell; this screen focuses on the
/// movement cards and date grouping (design D11 / global movements list).
class MovementsScreen extends ConsumerWidget {
  const MovementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final asyncMovements = ref.watch(allMovementsProvider);
    final products =
        ref.watch(productsStreamProvider).value ?? const <Product>[];
    final nameOf = <String, String>{
      for (final p in products) p.id: p.name,
    };

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Icon(Icons.menu, size: 20, color: cs.primary),
        title: Text(
          'Movimientos',
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
      backgroundColor: cs.surfaceContainerLowest ?? cs.surface,
      body: asyncMovements.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Error al cargar el historial')),
        data: (movements) {
          if (movements.isEmpty) {
            return const Center(child: Text('Aún no hay movimientos'));
          }

          final groups = _groupByDate(movements);

          return CustomScrollView(
            slivers: [
              // --- Search + filter chips ---
              SliverToBoxAdapter(
                child: _SearchAndFilters(
                  onFilterChanged: (filter) {
                    // TODO: wire up filter logic (todos/entradas/salidas)
                  },
                ),
              ),
              // --- Date-grouped movement sections ---
              for (final group in groups) ...[
                SliverToBoxAdapter(child: _DateSectionHeader(group.dateLabel)),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    childCount: group.movements.length,
                    (context, index) {
                      final movement = group.movements[index];
                      final isLastInSection =
                          index == group.movements.length - 1;
                      final isLastOverall =
                          group == groups.last && isLastInSection;
                      return _MovementItem(
                        movement: movement,
                        productName:
                            nameOf[movement.productId] ?? '—',
                        isLastInSection: isLastInSection,
                        isLastOverall: isLastOverall,
                      );
                    },
                  ),
                ),
              ],
              // bottom safe area
              const SliverToBoxAdapter(child: SizedBox(height: 72)),
            ],
          );
        },
      ),
    );
  }
}

/// Filter enum for the movements list.
enum MovementFilter { all, incoming, outgoing }

/// Search bar + filter chips (Figma movimientos 5.x).
class _SearchAndFilters extends StatelessWidget {
  const _SearchAndFilters({super.key, required this.onFilterChanged});

  final ValueChanged<MovementFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    MovementFilter activeFilter = MovementFilter.all;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.marginMobile,
        AppTokens.stackMd,
        AppTokens.marginMobile,
        AppTokens.stackSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search box
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0x80 / 255),
              borderRadius: BorderRadius.circular(AppTokens.borderRadiusFull),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  size: 18,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar movimientos...',
                      hintStyle: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: theme.textTheme.bodySmall,
                    onChanged: (value) {
                      // TODO: wire up search (by product name or reason)
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.stackMd),
          // Filter chips
          Row(
            children: [
              _FilterChip(
                label: 'Todos',
                selected: activeFilter == MovementFilter.all,
                onSelected: (sel) {
                  activeFilter = MovementFilter.all;
                  onFilterChanged(MovementFilter.all);
                },
              ),
              const SizedBox(width: AppTokens.stackSm),
              _FilterChip(
                label: 'Entradas',
                selected: activeFilter == MovementFilter.incoming,
                onSelected: (sel) {
                  activeFilter = MovementFilter.incoming;
                  onFilterChanged(MovementFilter.incoming);
                },
              ),
              const SizedBox(width: AppTokens.stackSm),
              _FilterChip(
                label: 'Salidas',
                selected: activeFilter == MovementFilter.outgoing,
                onSelected: (sel) {
                  activeFilter = MovementFilter.outgoing;
                  onFilterChanged(MovementFilter.outgoing);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Filter chip styled like Figma pills.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.05,
          height: 16 / 11,
          color: selected ? cs.onPrimary : cs.onSurfaceVariant,
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      selectedColor: cs.primary,
      backgroundColor: cs.surfaceContainerHigh,
      side: BorderSide.none,
      showCheckmark: false,
      labelPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.borderRadiusFull),
      ),
    );
  }
}

/// Date header for a group of movements (Hoy, Ayer, Semana Pasada, etc.).
class _DateSectionHeader extends StatelessWidget {
  const _DateSectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isToday = label == 'Hoy';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.marginMobile,
        AppTokens.stackSm,
        AppTokens.marginMobile,
        AppTokens.stackSm,
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isToday ? cs.primary : cs.outline,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isToday ? cs.onSurface : cs.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

/// A single movement row matching the Figma design:
/// - 3px vertical line on the left (green for incoming, red for outgoing)
/// - 34px circle icon with +/−
/// - Time below icon
/// - Product name + reason description + stock before→after
/// - Signed quantity on the right
class _MovementItem extends StatelessWidget {
  const _MovementItem({
    required this.movement,
    required this.productName,
    required this.isLastInSection,
    required this.isLastOverall,
  });

  final InventoryMovement movement;
  final String productName;
  final bool isLastInSection;
  final bool isLastOverall;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isIncoming = movement.type == MovementType.incoming;
    final accent = isIncoming ? cs.secondary : cs.error;
    final quantityPrefix = isIncoming ? '+' : '-';

    // Time-only format (HH:MM) since we group by date
    final time = _formatTimeOnly(movement.occurredAt);

    return Container(
      margin: EdgeInsets.only(
        left: 18,
        right: AppTokens.marginMobile,
        bottom: isLastOverall ? AppTokens.stackLg : 0,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: isLastInSection
              ? const BorderSide(color: Color(0x0D000000), width: 1)
              : BorderSide.none,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vertical line indicator on the left
          Container(
            width: 3,
            margin: EdgeInsets.only(
              top: 8,
              bottom: isLastInSection ? 0 : 8,
            ),
            decoration: BoxDecoration(
              color: isIncoming ? const Color(0xFF7cdbc3) : const Color(0xFFe7a2a2),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 12),
          // Icon + time column
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isIncoming
                      ? const Color(0xFFe3f4ef)
                      : const Color(0xFFf9eeee),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isIncoming ? Icons.add : Icons.remove,
                  size: 12,
                  color: isIncoming ? const Color(0xFF3b987f) : const Color(0xFFd35a5a),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                time,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: cs.onSurfaceVariant,
                  height: 1,
                ),
              ),
            ],
          ),
          // Info column
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: AppTokens.gutter,
                top: isLastInSection ? 0 : 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                      height: 20 / 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    movement.reason.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                      height: 16 / 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  // Stock before → after
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0xFFd6dde2), width: 1),
                      ),
                    ),
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Stock Actualizado',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: const Color(0xFF6d7880),
                            letterSpacing: 0.2,
                          ),
                        ),
                        Text(
                          '${movement.stockBefore} → ${movement.stockAfter}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: const Color(0xFF6d7880),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Quantity on the right
          Container(
            margin: const EdgeInsets.only(left: 12),
            child: Text(
              '$quantityPrefix${movement.quantity}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isIncoming
                    ? const Color(0xFF367b6a)
                    : const Color(0xFFc95252),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Groups movements by date label (Hoy, Ayer, Semana Pasada, Más antiguas).
class _MovementGroup {
  const _MovementGroup(this.dateLabel, this.movements);

  final String dateLabel;
  final List<InventoryMovement> movements;
}

/// Groups movements newest-first, bucketing by Hoy / Ayer / Semana Pasada / Más antiguas.
List<_MovementGroup> _groupByDate(List<InventoryMovement> movements) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final weekAgo = today.subtract(const Duration(days: 7));

  final hoy = <InventoryMovement>[];
  final ayer = <InventoryMovement>[];
  final semanaPasada = <InventoryMovement>[];
  final masAntiguas = <InventoryMovement>[];

  for (final m in movements) {
    final day = DateTime(m.occurredAt.year, m.occurredAt.month, m.occurredAt.day);
    if (day == today) {
      hoy.add(m);
    } else if (day == yesterday) {
      ayer.add(m);
    } else if (day.isAfter(weekAgo)) {
      semanaPasada.add(m);
    } else {
      masAntiguas.add(m);
    }
  }

  final groups = <_MovementGroup>[];
  if (hoy.isNotEmpty) groups.add(_MovementGroup('Hoy', hoy));
  if (ayer.isNotEmpty) groups.add(_MovementGroup('Ayer', ayer));
  if (semanaPasada.isNotEmpty) groups.add(_MovementGroup('Semana Pasada', semanaPasada));
  if (masAntiguas.isNotEmpty) groups.add(_MovementGroup('Más antiguas', masAntiguas));

  return groups;
}

/// Formats a [DateTime] as time-only "HH:MM".
String _formatTimeOnly(DateTime time) {
  final local = time.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
