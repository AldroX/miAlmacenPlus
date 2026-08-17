import 'package:flutter/material.dart';
import 'package:mi_almacen_plus/core/theme/app_theme.dart';

/// Reusable summary stat card (figma dash 5.1 Summary Cards Grid).
///
/// Layout: a 4px-wide colored accent bar on the left, an icon+label row, then
/// the stock-style [value] below. The whole surface is tappable when
/// [onTap] is provided.
class SummaryStatCard extends StatelessWidget {
  const SummaryStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final radius = BorderRadius.circular(AppTokens.borderRadiusMd);

    final content = Padding(
      padding: const EdgeInsets.all(AppTokens.gutter),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              height: double.infinity,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppTokens.stackSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 20, color: accentColor),
                      const SizedBox(width: AppTokens.stackSm),
                      Expanded(
                        child: Text(
                          label,
                          style: AppTheme.labelStock.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.stackSm),
                  Text(
                    value,
                    style: AppTheme.displayStock.copyWith(color: cs.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final decoration = BoxDecoration(
      color: cs.surface,
      borderRadius: radius,
      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      boxShadow:
          theme.extension<AppThemeExtra>()?.cardShadow ??
          AppThemeExtra.light.cardShadow,
    );

    if (onTap == null) {
      return Container(decoration: decoration, child: content);
    }

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: decoration,
        child: InkWell(borderRadius: radius, onTap: onTap, child: content),
      ),
    );
  }
}
