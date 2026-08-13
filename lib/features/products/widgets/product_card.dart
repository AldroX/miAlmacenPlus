import 'package:flutter/material.dart';
import 'package:mi_almacen_plus/core/domain/entities/product.dart';
import 'package:mi_almacen_plus/core/domain/stock_status.dart';
import 'package:mi_almacen_plus/core/domain/stock_status_of.dart';
import 'package:mi_almacen_plus/core/theme/app_theme.dart';

import 'status_chip.dart';

/// Inventory card (DESING.MD "Inventory Cards"): white surface, 12px radius,
/// soft shadow, full-height 4px status accent on the left, a pill status
/// chip and the `display-stock` number on the right.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.categoryName,
    this.onTap,
  });

  final Product product;

  /// Spanish category name, resolved by the caller from the categories stream.
  final String? categoryName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final status = stockStatusOf(product.currentStock, product.minimumStock);
    final outOfStock = status == StockStatus.outOfStock;
    final radius = BorderRadius.circular(AppTokens.borderRadiusMd);
    final shadow =
        theme.extension<AppThemeExtra>()?.cardShadow ??
        AppThemeExtra.light.cardShadow;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        border: Border.all(color: cs.surfaceContainer),
        boxShadow: shadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Opacity(
            opacity: outOfStock ? 0.75 : 1,
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.gutter),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: status.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: AppTokens.gutter),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              height: 28 / 20,
                              color: cs.onSurface,
                              decoration: outOfStock
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: AppTokens.stackSm / 2),
                          if (categoryName != null)
                            Text(
                              categoryName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                               style: TextStyle(
                                 fontFamily: 'Inter',
                                 fontSize: 14,
                                 height: 20 / 14,
                                 color: cs.outline,
                               ),
                             ),
                           const SizedBox(height: AppTokens.stackSm),
                           StatusChip(status: status),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTokens.stackMd),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${product.currentStock}',
                          style: AppTheme.displayStock.copyWith(
                            color: outOfStock
                                ? (theme.brightness == Brightness.dark
                                    ? cs.onSurface
                                    : cs.error)
                                : cs.onSurface,
                          ),
                        ),
                        Text(
                          product.unit,
                           style: TextStyle(
                             fontFamily: 'Inter',
                             fontSize: 14,
                             height: 20 / 14,
                             color: cs.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
