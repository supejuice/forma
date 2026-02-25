import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'design_tokens.dart';

ThemeData buildAppTheme() {
  return _buildTheme(Brightness.light);
}

ThemeData buildDarkAppTheme() {
  return _buildTheme(Brightness.dark);
}

ThemeData _buildTheme(Brightness brightness) {
  final bool isDark = brightness == Brightness.dark;
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: AppColors.leaf,
    brightness: brightness,
  ).copyWith(secondary: AppColors.coral);

  final TextTheme base =
      ThemeData(brightness: brightness, useMaterial3: true).textTheme;
  final TextTheme manrope = GoogleFonts.manropeTextTheme(base).copyWith(
    displaySmall: GoogleFonts.fraunces(
      textStyle: base.displaySmall,
      fontWeight: FontWeight.w700,
      color: scheme.onSurface,
      letterSpacing: -0.6,
    ),
    headlineMedium: GoogleFonts.fraunces(
      textStyle: base.headlineMedium,
      fontWeight: FontWeight.w700,
      color: scheme.onSurface,
    ),
    titleLarge: GoogleFonts.manrope(
      textStyle: base.titleLarge,
      fontWeight: FontWeight.w700,
      color: scheme.onSurface,
    ),
    bodyLarge: GoogleFonts.manrope(
      textStyle: base.bodyLarge,
      height: 1.4,
      color: scheme.onSurface,
    ),
    bodyMedium: GoogleFonts.manrope(
      textStyle: base.bodyMedium,
      height: 1.35,
      color: scheme.onSurfaceVariant,
    ),
  );

  return ThemeData(
    brightness: brightness,
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    textTheme: manrope,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLow,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor:
          isDark
              ? scheme.surfaceContainerHighest.withValues(alpha: 0.55)
              : scheme.surfaceContainerLowest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: scheme.primary, width: 1.4),
      ),
      contentPadding: const EdgeInsets.all(AppSpacing.md),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        side: BorderSide(color: scheme.outlineVariant),
        foregroundColor: scheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor:
          isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLow,
      labelStyle: TextStyle(color: scheme.onSurface),
      selectedColor: scheme.primary.withValues(alpha: 0.2),
      side: BorderSide(color: scheme.outlineVariant),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor:
          isDark ? scheme.surfaceContainer : scheme.surfaceContainerLow,
      indicatorColor: scheme.primaryContainer,
      iconTheme: WidgetStatePropertyAll<IconThemeData>(
        IconThemeData(color: scheme.onSurfaceVariant),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((
        Set<WidgetState> states,
      ) {
        final Color color =
            states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant;
        return TextStyle(color: color, fontWeight: FontWeight.w600);
      }),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.transparent,
      selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
      unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      selectedLabelTextStyle: TextStyle(
        color: scheme.onPrimaryContainer,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: TextStyle(color: scheme.onSurfaceVariant),
      indicatorColor: scheme.primaryContainer,
    ),
  );
}
