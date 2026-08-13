import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_almacen_plus/core/theme/app_theme.dart';

double _contrastRatio(Color a, Color b) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
  double lum(Color c) {
    final r = channel(c.r),
        g = channel(c.g),
        b = channel(c.b);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }
  final h = max(lum(a), lum(b)), l = min(lum(a), lum(b));
  return (h + 0.05) / (l + 0.05);
}

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

      test('surface is white', () {
        expect(cs.surface.toARGB32(), 0xFFFFFFFF);
      });

      test('surfaceBright is white', () {
        expect(cs.surfaceBright.toARGB32(), 0xFFFFFFFF);
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

    group('text style colors fix gray-on-gray', () {
      final theme = AppTheme.light;
      final cs = theme.colorScheme;

      test('bodyLarge color is onSurface', () {
        expect(theme.textTheme.bodyLarge?.color?.toARGB32(), cs.onSurface.toARGB32());
        expect(theme.textTheme.bodyLarge?.color?.toARGB32(), 0xFF0B1C30);
      });

      test('bodyMedium color is onSurface', () {
        expect(theme.textTheme.bodyMedium?.color?.toARGB32(), cs.onSurface.toARGB32());
        expect(theme.textTheme.bodyMedium?.color?.toARGB32(), 0xFF0B1C30);
      });

      test('headlineMedium color is onSurface', () {
        expect(theme.textTheme.headlineMedium?.color?.toARGB32(), cs.onSurface.toARGB32());
      });

      test('displayLarge color is onSurface', () {
        expect(theme.textTheme.displayLarge?.color?.toARGB32(), cs.onSurface.toARGB32());
      });

      test('labelMedium color is onSurfaceVariant', () {
        expect(theme.textTheme.labelMedium?.color?.toARGB32(), cs.onSurfaceVariant.toARGB32());
        expect(theme.textTheme.labelMedium?.color?.toARGB32(), 0xFF3F484C);
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

    group('dark color scheme + contrast (craft floor >=4.5:1)', () {
      final theme = AppTheme.dark;
      final cs = theme.colorScheme;

      test('surface is NOT white (dark surface)', () {
        expect(cs.surface.toARGB32(), isNot(0xFFFFFFFF));
      });

      test('onSurface is light (luminance > 0.5)', () {
        expect(cs.onSurface.computeLuminance(), greaterThan(0.5));
      });

      test('_contrastRatio(onSurface, surface) >= 4.5', () {
        expect(_contrastRatio(cs.onSurface, cs.surface), greaterThanOrEqualTo(4.5));
      });

      test('_contrastRatio(onPrimary, primary) >= 4.5', () {
        expect(_contrastRatio(cs.onPrimary, cs.primary), greaterThanOrEqualTo(4.5));
      });

      test('_contrastRatio(onSecondary, secondary) >= 4.5', () {
        expect(_contrastRatio(cs.onSecondary, cs.secondary), greaterThanOrEqualTo(4.5));
      });

      test('_contrastRatio(onTertiary, tertiary) >= 4.5', () {
        expect(_contrastRatio(cs.onTertiary, cs.tertiary), greaterThanOrEqualTo(4.5));
      });

      test('_contrastRatio(onError, error) >= 4.5', () {
        expect(_contrastRatio(cs.onError, cs.error), greaterThanOrEqualTo(4.5));
      });

      test('displayStock getter color is null', () {
        expect(AppTheme.displayStock.color, isNull);
      });

      test('dark bodyLarge color tracks dark onSurface', () {
        expect(
          theme.textTheme.bodyLarge?.color?.toARGB32(),
          cs.onSurface.toARGB32(),
        );
      });
    });
  });
}
