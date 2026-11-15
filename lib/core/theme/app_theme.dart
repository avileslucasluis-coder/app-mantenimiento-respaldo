import 'package:flutter/material.dart';
import 'spacing.dart';

abstract final class AppTheme {
  static const seed = Color(0xFF00695C);
  static ThemeData get light => build(Brightness.light);
  static ThemeData get dark => build(Brightness.dark);

  static ThemeData build(Brightness brightness, {bool mantenimiento = false}) {
    var colors = ColorScheme.fromSeed(
      seedColor: mantenimiento ? const Color(0xFF0B5FA5) : seed,
      brightness: brightness,
    );
    if (!mantenimiento && brightness == Brightness.light) {
      colors = colors.copyWith(
        primary: const Color(0xFF006B5E),
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFF9FF2E1),
        onPrimaryContainer: const Color(0xFF005046),
        secondaryContainer: const Color(0xFFCDE8E1),
        onSecondaryContainer: const Color(0xFF334B45),
        tertiaryContainer: const Color(0xFFCAE6FF),
        onTertiaryContainer: const Color(0xFF2C495A),
        surface: const Color(0xFFF4FBF8),
        onSurface: const Color(0xFF171D1B),
        onSurfaceVariant: const Color(0xFF3F4946),
        surfaceContainerLow: const Color(0xFFEFF5F2),
        surfaceContainer: const Color(0xFFE9EFEC),
        surfaceContainerHigh: const Color(0xFFE3EAE6),
        surfaceContainerHighest: const Color(0xFFDEE4E1),
        outline: const Color(0xFF6F7975),
        outlineVariant: const Color(0xFFBEC9C5),
        errorContainer: const Color(0xFFFFDAD6),
      );
    }
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: colors.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surfaceContainer,
        indicatorColor: colors.secondaryContainer,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(Radii.xs)),
        ),
      ),
    );
  }
}
