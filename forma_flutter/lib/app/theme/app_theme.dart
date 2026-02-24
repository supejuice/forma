import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'design_tokens.dart';

ThemeData buildAppTheme() {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: AppColors.leaf,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.leaf,
    secondary: AppColors.coral,
    surface: AppColors.surface,
    outline: AppColors.line,
    onSurface: AppColors.ink,
  );

  final TextTheme base = ThemeData.light(useMaterial3: true).textTheme;
  final TextTheme manrope = GoogleFonts.manropeTextTheme(base).copyWith(
    displaySmall: GoogleFonts.fraunces(
      textStyle: base.displaySmall,
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
      letterSpacing: -0.6,
    ),
    headlineMedium: GoogleFonts.fraunces(
      textStyle: base.headlineMedium,
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
    ),
    titleLarge: GoogleFonts.manrope(
      textStyle: base.titleLarge,
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
    ),
    bodyLarge: GoogleFonts.manrope(
      textStyle: base.bodyLarge,
      height: 1.4,
      color: AppColors.ink,
    ),
    bodyMedium: GoogleFonts.manrope(
      textStyle: base.bodyMedium,
      height: 1.35,
      color: AppColors.mutedInk,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.canvas,
    textTheme: manrope,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: AppColors.leaf, width: 1.4),
      ),
      contentPadding: const EdgeInsets.all(AppSpacing.md),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.leaf,
        foregroundColor: Colors.white,
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
        side: const BorderSide(color: AppColors.line),
        foregroundColor: AppColors.ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      labelStyle: const TextStyle(color: AppColors.ink),
      selectedColor: AppColors.leaf.withValues(alpha: 0.18),
      side: const BorderSide(color: AppColors.line),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
    ),
  );
}
