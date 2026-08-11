import 'package:flutter/material.dart';
import 'package:mi_almacen_plus/core/domain/stock_status.dart';
import 'package:mi_almacen_plus/core/theme/app_theme.dart';

/// Spanish label + accent color per stock status (DESING.MD status chips).
extension StockStatusUi on StockStatus {
  String get label => switch (this) {
    StockStatus.normal => 'En stock',
    StockStatus.lowStock => 'Stock bajo',
    StockStatus.outOfStock => 'Agotado',
  };

  /// Figma inventory-card accent bar color per status.
  Color get accent => switch (this) {
    StockStatus.normal => const Color(0xFF6CF8BB),
    StockStatus.lowStock => const Color(0xFFFFB95F),
    StockStatus.outOfStock => const Color(0xFFBA1A1A),
  };
}

/// Pill-shaped stock status badge (DESING.MD "Status Chips"): tinted pill
/// with high-contrast text, using the Figma list palette.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final StockStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      StockStatus.normal => (const Color(0x336CF8BB), const Color(0xFF4EDEA3)),
      StockStatus.lowStock => (
        const Color(0x33FFB95F),
        const Color(0xFF965F00),
      ),
      StockStatus.outOfStock => (
        const Color(0x4DFFDAD6),
        const Color(0xFFBA1A1A),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTokens.borderRadiusFull),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 16 / 12,
          letterSpacing: 0.05,
          color: foreground,
        ),
      ),
    );
  }
}
