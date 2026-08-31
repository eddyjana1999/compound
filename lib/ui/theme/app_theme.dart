import 'package:flutter/material.dart';

/// Semantic colours the calculator needs that a Material scheme has no name
/// for: what growth looks like, what a cost looks like.
///
/// Carried on the theme rather than reached for as constants, so a widget
/// never has to ask which mode it is in.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.growth,
    required this.growthSoft,
    required this.deposits,
    required this.depositsSoft,
    required this.fees,
    required this.tax,
    required this.heroGradient,
    required this.cardBorder,
    required this.shadow,
  });

  /// Interest earned. The colour of the headline number.
  final Color growth;
  final Color growthSoft;

  /// Money the user put in themselves.
  final Color deposits;
  final Color depositsSoft;

  /// Management fees.
  final Color fees;

  /// Capital gains tax.
  final Color tax;

  final List<Color> heroGradient;
  final Color cardBorder;
  final Color shadow;

  @override
  AppPalette copyWith({
    Color? growth,
    Color? growthSoft,
    Color? deposits,
    Color? depositsSoft,
    Color? fees,
    Color? tax,
    List<Color>? heroGradient,
    Color? cardBorder,
    Color? shadow,
  }) {
    return AppPalette(
      growth: growth ?? this.growth,
      growthSoft: growthSoft ?? this.growthSoft,
      deposits: deposits ?? this.deposits,
      depositsSoft: depositsSoft ?? this.depositsSoft,
      fees: fees ?? this.fees,
      tax: tax ?? this.tax,
      heroGradient: heroGradient ?? this.heroGradient,
      cardBorder: cardBorder ?? this.cardBorder,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      growth: Color.lerp(growth, other.growth, t)!,
      growthSoft: Color.lerp(growthSoft, other.growthSoft, t)!,
      deposits: Color.lerp(deposits, other.deposits, t)!,
      depositsSoft: Color.lerp(depositsSoft, other.depositsSoft, t)!,
      fees: Color.lerp(fees, other.fees, t)!,
      tax: Color.lerp(tax, other.tax, t)!,
      heroGradient: [
        Color.lerp(heroGradient.first, other.heroGradient.first, t)!,
        Color.lerp(heroGradient.last, other.heroGradient.last, t)!,
      ],
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

/// Reaches the palette without every widget spelling out the lookup.
extension PaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get texts => Theme.of(this).textTheme;
}

class AppTheme {
  AppTheme._();

  static const Color _emerald = Color(0xFF10B981);
  static const Color _emeraldDeep = Color(0xFF059669);
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _rose = Color(0xFFF43F5E);

  static const double radius = 20;
  static const double pagePadding = 20;

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: _emerald,
      brightness: Brightness.light,
    ).copyWith(
      surface: const Color(0xFFF7F9FB),
      surfaceContainerLowest: Colors.white,
      surfaceContainer: Colors.white,
    );

    return _base(scheme).copyWith(
      extensions: [
        const AppPalette(
          growth: _emeraldDeep,
          growthSoft: Color(0x1A10B981),
          deposits: _indigo,
          depositsSoft: Color(0x1A6366F1),
          fees: _amber,
          tax: _rose,
          heroGradient: [Color(0xFF10B981), Color(0xFF0D9488)],
          cardBorder: Color(0x14000000),
          shadow: Color(0x0F0F172A),
        ),
      ],
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: _emerald,
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF0B0F14),
      surfaceContainerLowest: const Color(0xFF111820),
      surfaceContainer: const Color(0xFF151D26),
      onSurface: const Color(0xFFE8EDF2),
    );

    return _base(scheme).copyWith(
      extensions: [
        const AppPalette(
          growth: Color(0xFF34D399),
          growthSoft: Color(0x2634D399),
          deposits: Color(0xFF818CF8),
          depositsSoft: Color(0x26818CF8),
          fees: Color(0xFFFBBF24),
          tax: Color(0xFFFB7185),
          heroGradient: [Color(0xFF0F766E), Color(0xFF065F46)],
          cardBorder: Color(0x1AFFFFFF),
          shadow: Color(0x40000000),
        ),
      ],
    );
  }

  static ThemeData _base(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;

    final textTheme = Typography.material2021()
        .englishLike
        .apply(
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        )
        .copyWith(
          displayLarge: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.4,
            height: 1.05,
            color: scheme.onSurface,
          ),
          headlineMedium: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            color: scheme.onSurface,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: scheme.onSurface,
          ),
          bodyMedium: TextStyle(
            fontSize: 15,
            height: 1.45,
            color: scheme.onSurface.withValues(alpha: 0.86),
          ),
          labelLarge: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          labelMedium: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: scheme.onSurface.withValues(alpha: 0.6),
          ),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        // Centred, because both screens that carry a title now have
        // controls on the leading side — two on Results — and a title pushed
        // up against them reads as part of the button group rather than as
        // the name of the screen.
        centerTitle: true,
        titleTextStyle: textTheme.titleMedium,
      ),
      // Declared here rather than passed to showModalBottomSheet, which
      // stores whatever colour it is handed as a field on the route. A sheet
      // opened in one theme kept that colour when the theme flipped
      // underneath it, so its contents repainted and its background did not.
      // Read from the theme, it is resolved on every build instead.
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        modalBackgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? scheme.surfaceContainer
            : scheme.surfaceContainerLowest,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? const Color(0x1AFFFFFF) : const Color(0x14000000),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
        labelStyle: TextStyle(
          color: scheme.onSurface.withValues(alpha: 0.6),
          fontWeight: FontWeight.w500,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(58),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.onSurface.withValues(alpha: 0.08),
        space: 1,
        thickness: 1,
      ),
    );
  }
}
