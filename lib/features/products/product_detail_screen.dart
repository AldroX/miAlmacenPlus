import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_almacen_plus/core/domain/entities/category.dart';
import 'package:mi_almacen_plus/core/domain/entities/inventory_movement.dart';
import 'package:mi_almacen_plus/core/domain/entities/product.dart';
import 'package:mi_almacen_plus/core/domain/errors.dart';
import 'package:mi_almacen_plus/core/domain/movement_type.dart';
import 'package:mi_almacen_plus/core/domain/stock_status.dart';
import 'package:mi_almacen_plus/core/domain/stock_status_of.dart';
import 'package:mi_almacen_plus/core/providers/app_providers.dart';
import 'package:mi_almacen_plus/core/providers/stream_providers.dart';
import 'package:mi_almacen_plus/core/theme/app_theme.dart';

import 'widgets/product_form.dart';

/// Product detail — full screen with inline edit (design D8). Edits touch
/// descriptive fields only; currentStock is read-only (spec 3.2).
class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool _editing = false;

  Future<void> _save(Product product, ProductFormData data) async {
    try {
      await ref
          .read(productRepositoryProvider)
          .update(
            id: product.id,
            name: data.name,
            categoryId: data.categoryId,
            unit: data.unit,
            minimumStock: data.minimumStock,
            description: data.description,
          );
      if (!mounted) return;
      setState(() => _editing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cambios guardados')));
    } on DomainException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _confirmDelete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar producto?'),
        content: const Text('Se conservará el historial de movimientos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(productRepositoryProvider).softDelete(product.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final asyncProduct = ref.watch(productByIdProvider(widget.productId));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surface.withValues(alpha: 0xE6 / 255),
        foregroundColor: cs.primary,
        titleTextStyle: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: cs.primary,
        ),
        title: const Text('Producto'),
        actions: [
          if (!_editing)
            IconButton(
              key: const Key('edit-product'),
              onPressed: () => setState(() => _editing = true),
              tooltip: 'Editar producto',
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: asyncProduct.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Error al cargar el producto')),
        data: (product) {
          if (product == null) {
            return const Center(child: Text('Producto no encontrado'));
          }
          if (_editing) {
            return ProductForm(
              isNew: false,
              initialProduct: product,
              onSubmit: (data) => _save(product, data),
            );
          }
          return _buildDetail(context, product);
        },
      ),
    );
  }

  Widget _buildDetail(BuildContext context, Product product) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final status = stockStatusOf(product.currentStock, product.minimumStock);
    final categories =
        ref.watch(categoriesStreamProvider).value ?? const <Category>[];
    final categoryName = categories
        .firstWhere(
          (c) => c.id == product.categoryId,
          orElse: () => const Category(id: '', name: ''),
        )
        .name;
    final movements =
        ref.watch(movementsForProductProvider(product.id)).value ??
        const <InventoryMovement>[];
    final recent = movements.take(3).toList();
    final shadow =
        theme.extension<AppThemeExtra>()?.cardShadow ??
        AppThemeExtra.light.cardShadow;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.marginMobile,
        AppTokens.stackSm,
        AppTokens.marginMobile,
        AppTokens.stackLg,
      ),
      children: [
        _detailCard(
          context: context,
          shadow: shadow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 192,
                width: double.infinity,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(
                      AppTokens.borderRadiusDefault,
                    ),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 48,
                    color: cs.outline,
                  ),
              ),
              const SizedBox(height: AppTokens.stackMd),
              Text(
                'SKU: PROD-${product.id}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.05,
                  color: cs.outline,
                ),
              ),
              const SizedBox(height: AppTokens.stackSm),
              Text(
                product.name,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  height: 32 / 24,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Categoría: $categoryName',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  height: 20 / 14,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.stackLg),
        _detailCard(
          context: context,
          shadow: shadow,
          padding: 24,
          child: Column(
            children: [
               Text(
                'Stock Actual Disponible',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppTokens.stackSm),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${product.currentStock}',
                    style: AppTheme.displayStock.copyWith(
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(width: AppTokens.stackSm),
              Text(
                'Unidades',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.stackSm),
              _DetailStatusChip(status: status),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.stackLg),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                key: const Key('open-movement'),
                label: 'Entrada (+)',
                icon: Icons.add,
                color: cs.secondary,
                onPressed: () =>
                    context.push('/products/${product.id}/movement'),
              ),
            ),
            const SizedBox(width: AppTokens.gutter),
            Expanded(
              child: _QuickActionButton(
                key: const Key('open-exit'),
                label: 'Salida (−)',
                icon: Icons.remove,
                color: cs.error,
                onPressed: () =>
                    context.push('/products/${product.id}/movement?type=out'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.stackLg),
        _detailCard(
          context: context,
          shadow: shadow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              Text(
                'Historial Reciente',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              TextButton(
                    key: const Key('open-history'),
                    onPressed: () =>
                        context.push('/products/${product.id}/history'),
                    style: TextButton.styleFrom(
                      foregroundColor: cs.primary,
                    ),
                    child: const Text(
                      'Ver todo',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.05,
                      ),
                    ),
                  ),
                ],
              ),
              if (recent.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppTokens.stackMd),
                  child: Center(child: Text('Sin movimientos todavía')),
                )
              else
                for (var i = 0; i < recent.length; i++) ...[
                  _MovementRow(movement: recent[i]),
                  if (i < recent.length - 1)
                    const SizedBox(height: AppTokens.stackMd),
                ],
            ],
          ),
        ),
        const SizedBox(height: AppTokens.stackLg),
        Center(
          child: TextButton.icon(
            key: const Key('delete-product'),
            onPressed: () => _confirmDelete(product),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Eliminar producto'),
          ),
        ),
      ],
    );
  }

  Widget _detailCard({
    required BuildContext context,
    required List<BoxShadow> shadow,
    Widget? child,
    double? padding,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(padding ?? AppTokens.gutter),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTokens.borderRadiusMd),
        border: Border.all(
          color: cs.surfaceContainerHigh.withValues(alpha: 0x80 / 255),
        ),
        boxShadow: shadow,
      ),
      child: child,
    );
  }
}

/// Detail status pill: 9999px radius, 6/16 padding, 8px dot + uppercase label.
class _DetailStatusChip extends StatelessWidget {
  const _DetailStatusChip({required this.status});

  final StockStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, border, dot, text, label) = switch (status) {
      StockStatus.normal => (
        const Color(0x4D6CF8BB),
        const Color(0xFF6CF8BB),
        const Color(0xFF006C49),
        const Color(0xFF00714D),
        'STOCK SALUDABLE',
      ),
      StockStatus.lowStock => (
        const Color(0x33FFB95F),
        const Color(0xFFFFB95F),
        const Color(0xFF965F00),
        const Color(0xFF965F00),
        'STOCK BAJO',
      ),
      StockStatus.outOfStock => (
        const Color(0x4DFFDAD6),
        const Color(0xFFBA1A1A),
        const Color(0xFFBA1A1A),
        const Color(0xFFBA1A1A),
        'AGOTADO',
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTokens.borderRadiusFull),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppTokens.stackSm),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.05,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}

/// Figma quick action: 56px tall, 12px radius, 20px SemiBold white label with
/// icon on a solid fill.
class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppTokens.borderRadiusMd),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.borderRadiusMd),
        onTap: onPressed,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: AppTokens.stackSm),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single recent-movement row: 40px circle icon, reason + relative date, and a
/// right-aligned signed delta.
class _MovementRow extends StatelessWidget {
  const _MovementRow({required this.movement});

  final InventoryMovement movement;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final incoming = movement.type == MovementType.incoming;
    final accent = incoming ? cs.secondary : cs.error;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            shape: BoxShape.circle,
          ),
          child: Icon(
            incoming ? Icons.arrow_downward : Icons.arrow_upward,
            size: 13,
            color: accent,
          ),
        ),
        const SizedBox(width: AppTokens.gutter),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                movement.reason.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 20 / 14,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(movement.occurredAt),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  letterSpacing: 0.05,
                  height: 16 / 12,
                  color: cs.outline,
                ),
              ),
            ],
          ),
        ),
        Text(
          '${incoming ? '+' : '-'}${movement.quantity}',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: accent,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    final local = date.toLocal();
    final now = DateTime.now();
    final isToday =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    final prefix = isToday
        ? 'Hoy'
        : '${two(local.day)}/${two(local.month)}/${local.year}';
    return '$prefix, ${two(local.hour)}:${two(local.minute)}';
  }
}
