import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_almacen_plus/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    group('light color scheme matches DESING.MD', () {
      final theme = AppTheme.light;
      final cs = theme.colorScheme;

      test('primary is teal-blue #005a71', () {
        expect(cs.primary.toARGB32(), 0xFF005A71);
      });

      test('onPrimary is white', () {
        expect(cs.onPrimary.toARGB32(), 0xFFFFFFFF);
      });

      test('surface is #f8f9ff', () {
        expect(cs.surface.toARGB32(), 0xFFF8F9FF);
      });

      test('onSurface is #0b1c30', () {
        expect(cs.onSurface.toARGB32(), 0xFF0B1C30);
      });

      test('error is coral #ba1a1a', () {
        expect(cs.error.toARGB32(), 0xFFBA1A1A);
      });

      test('secondary is emerald #006c49', () {
        expect(cs.secondary.toARGB32(), 0xFF006C49);
      });

      test('tertiary is amber #764900', () {
        expect(cs.tertiary.toARGB32(), 0xFF764900);
      });

      test('outline is #6f787d', () {
        expect(cs.outline.toARGB32(), 0xFF6F787D);
      });
    });

    group('typography uses Plus Jakarta Sans and Inter', () {
      final theme = AppTheme.light;

      test('headlineLarge uses Plus Jakarta Sans', () {
        final fontFamily = theme.textTheme.headlineLarge?.fontFamily;
        expect(fontFamily, 'Plus Jakarta Sans');
      });

      test('bodyMedium uses Inter', () {
        final fontFamily = theme.textTheme.bodyMedium?.fontFamily;
        expect(fontFamily, 'Inter');
      });

      test('displayStock uses Plus Jakarta Sans with weight 700', () {
        final style = AppTheme.displayStock;
        expect(style.fontFamily, 'Plus Jakarta Sans');
        expect(style.fontSize, 36);
        expect(style.fontWeight, FontWeight.w700);
      });

      test('labelStock uses Inter with weight 600', () {
        final style = AppTheme.labelStock;
        expect(style.fontFamily, 'Inter');
        expect(style.fontSize, 12);
        expect(style.fontWeight, FontWeight.w600);
      });
    });

    group('custom tokens via AppTokens extension', () {
      test('borderRadius values match DESING.MD', () {
        expect(AppTokens.borderRadiusXl, 24.0);
        expect(AppTokens.borderRadiusLg, 16.0);
        expect(AppTokens.borderRadiusFull, 9999.0);
      });

      test('spacing values match DESING.MD 4px baseline', () {
        expect(AppTokens.spacingUnit, 4.0);
        expect(AppTokens.marginMobile, 20.0);
        expect(AppTokens.gutter, 16.0);
      });

      test('fabSize is 56px', () {
        expect(AppTokens.fabSize, 56.0);
      });
    });
  });
}
