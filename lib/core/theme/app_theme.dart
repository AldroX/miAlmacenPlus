import 'package:flutter/material.dart';

/// Spacing, radii, and other non-color layout tokens from DESING.MD.
///
/// All dimensions are in logical pixels. Spacing follows a 4px baseline.
class AppTokens {
  AppTokens._();

  // Spacing (4px baseline)
  static const double spacingUnit = 4.0;
  static const double marginMobile = 20.0;
  static const double gutter = 16.0;
  static const double stackSm = 8.0;
  static const double stackMd = 16.0;
  static const double stackLg = 24.0;

  // Border radius (rem → px at 16px base)
  static const double borderRadiusSm = 4.0;
  static const double borderRadiusDefault = 8.0;
  static const double borderRadiusMd = 12.0;
  static const double borderRadiusLg = 16.0;
  static const double borderRadiusXl = 24.0;
  static const double borderRadiusFull = 9999.0;

  // Component sizes
  static const double fabSize = 56.0;
  static const double bottomNavHeight = 84.0;
  static const double touchTargetMin = 48.0;
}

/// Custom ThemeExtension carrying additional visual tokens that don't fit
/// in the Material 3 [ColorScheme] (radii, elevations, shadows, spacing).
@immutable
class AppThemeExtra extends ThemeExtension<AppThemeExtra> {
  const AppThemeExtra({
    required this.radiusXl,
    required this.radiusLg,
    required this.radiusFull,
    required this.spacingUnit,
    required this.marginMobile,
    required this.gutter,
    required this.fabSize,
    required this.cardShadow,
    required this.modalShadow,
  });

  final double radiusXl;
  final double radiusLg;
  final double radiusFull;
  final double spacingUnit;
  final double marginMobile;
  final double gutter;
  final double fabSize;
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> modalShadow;

  @override
  AppThemeExtra copyWith() => this;

  @override
  AppThemeExtra lerp(ThemeExtension<AppThemeExtra>? other, double t) {
    if (other is! AppThemeExtra) return this;
    return t < 0.5 ? this : other;
  }

  /// Light-mode extra tokens matching DESING.MD.
  static const light = AppThemeExtra(
    radiusXl: 24.0,
    radiusLg: 16.0,
    radiusFull: 9999.0,
    spacingUnit: 4.0,
    marginMobile: 20.0,
    gutter: 16.0,
    fabSize: 56.0,
    cardShadow: [
      BoxShadow(
        blurRadius: 15,
        offset: Offset(0, 4),
        color: Color(0x0D000000), // 5% opacity
      ),
    ],
    modalShadow: [
      BoxShadow(
        blurRadius: 30,
        offset: Offset(0, 10),
        color: Color(0x26000000), // ~40% opacity
      ),
    ],
  );
}

/// Central theme factory: Material 3 [ColorScheme] + [ThemeData] + custom
/// typography built from the DESING.MD token file.
class AppTheme {
  AppTheme._();

  // ── Color helpers (DESING.MD hex → ARGB) ──────────────────────────
  static const _primary = Color(0xFF005A71);
  static const _onPrimary = Color(0xFFFFFFFF);
  static const _primaryContainer = Color(0xFF0E7490);
  static const _onPrimaryContainer = Color(0xFFD3F1FF);
  static const _inversePrimary = Color(0xFF81D1F0);

  static const _secondary = Color(0xFF006C49); // emerald / success
  static const _onSecondary = Color(0xFFFFFFFF);
  static const _secondaryContainer = Color(0xFF6CF8BB);
  static const _onSecondaryContainer = Color(0xFF00714D);

  static const _tertiary = Color(0xFF764900); // amber / warning
  static const _onTertiary = Color(0xFFFFFFFF);
  static const _tertiaryContainer = Color(0xFF965F00);
  static const _onTertiaryContainer = Color(0xFFFFE9D4);

  static const _surface = Color(0xFFFFFFFF);
  static const _onSurface = Color(0xFF0B1C30);
  static const _surfaceContainerLow = Color(0xFFEFF4FF);
  static const _surfaceContainer = Color(0xFFE5EEFF);
  static const _surfaceContainerHigh = Color(0xFFDCE9FF);
  static const _surfaceContainerHighest = Color(0xFFD3E4FE);
  static const _onSurfaceVariant = Color(0xFF3F484C);
  static const _outline = Color(0xFF6F787D);
  static const _outlineVariant = Color(0xFFBEC8CD);
  static const _inverseSurface = Color(0xFF213145);
  static const _inverseOnSurface = Color(0xFFEAF1FF);

  static const _error = Color(0xFFBA1A1A); // coral / danger
  static const _onError = Color(0xFFFFFFFF);
  static const _errorContainer = Color(0xFFFFDAD6);
  static const _onErrorContainer = Color(0xFF93000A);

  // ── ColorScheme factories ──────────────────────────────────────────
  static final ColorScheme _lightColorScheme = const ColorScheme.light(
    brightness: Brightness.light,
    primary: _primary,
    onPrimary: _onPrimary,
    primaryContainer: _primaryContainer,
    onPrimaryContainer: _onPrimaryContainer,
    inversePrimary: _inversePrimary,
    secondary: _secondary,
    onSecondary: _onSecondary,
    secondaryContainer: _secondaryContainer,
    onSecondaryContainer: _onSecondaryContainer,
    tertiary: _tertiary,
    onTertiary: _onTertiary,
    tertiaryContainer: _tertiaryContainer,
    onTertiaryContainer: _onTertiaryContainer,
    surface: _surface,
    onSurface: _onSurface,
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: _surfaceContainerLow,
    surfaceContainer: _surfaceContainer,
    surfaceContainerHigh: _surfaceContainerHigh,
    surfaceContainerHighest: _surfaceContainerHighest,
    surfaceDim: Color(0xFFCBDBF5),
    surfaceBright: _surface,
    onSurfaceVariant: _onSurfaceVariant,
    outline: _outline,
    outlineVariant: _outlineVariant,
    inverseSurface: _inverseSurface,
    onInverseSurface: _inverseOnSurface,
    error: _error,
    onError: _onError,
    errorContainer: _errorContainer,
    onErrorContainer: _onErrorContainer,
  );

  static final ColorScheme _darkColorScheme = ColorScheme.fromSeed(
    seedColor: _primary,
    brightness: Brightness.dark,
    primary: _primary,
    onPrimary: _onPrimary,
    secondary: _secondary,
    onSecondary: _onSecondary,
    tertiary: _tertiary,
    onTertiary: _onTertiary,
    error: _error,
    onError: _onError,
  );

  // ── Typography (DESING.MD) ───────────────────────────────────────
  static const _displayStock = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 44 / 36, // lineHeight 44px
    letterSpacing: -0.02,
  );

  static const _headlineLg = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
  );

  static const _headlineMd = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
  );

  static const _bodyLg = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
  );

  static const _bodyMd = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
  );

  static const _labelStock = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 16 / 12,
    letterSpacing: 0.05,
  );

   /// High-visibility stock number (DESING.MD display-stock).
   static TextStyle get displayStock => _displayStock;

   /// Compact stock-level label (DESING.MD label-stock).
   static TextStyle get labelStock => _labelStock;

   // ── Shared InputDecoration builder ────────────────────────────────
   static InputDecorationTheme _inputDecoration(ColorScheme cs) {
     return InputDecorationTheme(
       filled: true,
       fillColor: cs.surfaceContainerLow,
       labelStyle: TextStyle(
         fontFamily: 'Inter',
         fontSize: 16,
         color: cs.onSurfaceVariant,
       ),
       hintStyle: TextStyle(
         fontFamily: 'Inter',
         fontSize: 14,
         color: cs.onSurfaceVariant,
       ),
       contentPadding:
           const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
       border: OutlineInputBorder(
         borderRadius: BorderRadius.circular(AppTokens.borderRadiusLg),
         borderSide: BorderSide.none,
       ),
       enabledBorder: OutlineInputBorder(
         borderRadius: BorderRadius.circular(AppTokens.borderRadiusLg),
         borderSide: BorderSide.none,
       ),
       focusedBorder: OutlineInputBorder(
         borderRadius: BorderRadius.circular(AppTokens.borderRadiusLg),
         borderSide: BorderSide(color: cs.primary, width: 1),
       ),
       errorBorder: OutlineInputBorder(
         borderRadius: BorderRadius.circular(AppTokens.borderRadiusLg),
         borderSide: BorderSide(color: cs.error, width: 1),
       ),
       focusedErrorBorder: OutlineInputBorder(
         borderRadius: BorderRadius.circular(AppTokens.borderRadiusLg),
         borderSide: BorderSide(color: cs.error, width: 1),
       ),
     );
   }

   // ── ThemeData ────────────────────────────────────────────────────
   static ThemeData get light => ThemeData(
     colorScheme: _lightColorScheme,
     textTheme: TextTheme(
       displayLarge: _headlineLg.copyWith(color: _lightColorScheme.onSurface),
       displayMedium: _headlineMd.copyWith(color: _lightColorScheme.onSurface),
       headlineLarge: _headlineLg.copyWith(color: _lightColorScheme.onSurface),
       headlineMedium: _headlineMd.copyWith(
         color: _lightColorScheme.onSurface,
       ),
       bodyLarge: _bodyLg.copyWith(color: _lightColorScheme.onSurface),
       bodyMedium: _bodyMd.copyWith(color: _lightColorScheme.onSurface),
       labelMedium: _labelStock.copyWith(
         color: _lightColorScheme.onSurfaceVariant,
       ),
     ),
     scaffoldBackgroundColor: _surface,
     inputDecorationTheme: _inputDecoration(_lightColorScheme),
     appBarTheme: const AppBarTheme(
       backgroundColor: Colors.transparent,
       foregroundColor: _onSurface,
       elevation: 0,
       centerTitle: true,
     ),
     floatingActionButtonTheme: const FloatingActionButtonThemeData(
       sizeConstraints: BoxConstraints.tightFor(
         width: AppTokens.fabSize,
         height: AppTokens.fabSize,
       ),
     ),
     cardTheme: CardThemeData(
       color: Colors.white,
       shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(AppTokens.borderRadiusXl),
       ),
       shadowColor: const Color(0x0D000000),
       elevation: 0,
     ),
     chipTheme: ChipThemeData(
       selectedColor: _secondaryContainer.withAlpha(30),
       backgroundColor: _surfaceContainer,
       side: BorderSide.none,
       shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(AppTokens.borderRadiusFull),
       ),
     ),
     bottomSheetTheme: const BottomSheetThemeData(
       backgroundColor: Colors.white,
       shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
       ),
     ),
     navigationBarTheme: NavigationBarThemeData(
       height: AppTokens.bottomNavHeight,
       backgroundColor: Colors.white,
       indicatorColor: const Color(0x1A00714D),
       iconTheme: WidgetStateProperty.resolveWith(
         (states) => IconThemeData(
           color: states.contains(WidgetState.selected)
               ? const Color(0xFF00714D)
               : const Color(0xFF3F484C),
         ),
       ),
       labelTextStyle: WidgetStateProperty.resolveWith(
         (states) => TextStyle(
           fontFamily: 'Inter',
           fontSize: 12,
           fontWeight: FontWeight.w600,
           color: states.contains(WidgetState.selected)
               ? const Color(0xFF00714D)
               : const Color(0xFF3F484C),
         ),
       ),
     ),
     extensions: <ThemeExtension<dynamic>>[AppThemeExtra.light],
   );

   static ThemeData get dark => ThemeData(
     colorScheme: _darkColorScheme,
     textTheme: TextTheme(
       displayLarge: _headlineLg.copyWith(color: _darkColorScheme.onSurface),
       displayMedium: _headlineMd.copyWith(color: _darkColorScheme.onSurface),
       headlineLarge: _headlineLg.copyWith(color: _darkColorScheme.onSurface),
       headlineMedium: _headlineMd.copyWith(
         color: _darkColorScheme.onSurface,
       ),
       bodyLarge: _bodyLg.copyWith(color: _darkColorScheme.onSurface),
       bodyMedium: _bodyMd.copyWith(color: _darkColorScheme.onSurface),
       labelMedium: _labelStock.copyWith(
         color: _darkColorScheme.onSurfaceVariant,
       ),
     ),
     scaffoldBackgroundColor: _darkColorScheme.surface,
     inputDecorationTheme: _inputDecoration(_darkColorScheme),
     extensions: <ThemeExtension<dynamic>>[AppThemeExtra.light],
   );
}
