import 'package:flutter/material.dart';

class FinsheColors {
  FinsheColors._();

  static const bg = Color(0xFF121212);
  static const card = Color(0xFF1E1E26);
  static const cardMuted = Color(0xFF16161E);
  static const outlineSoft = Color(0xFF2E2E3A);
  static const accentPurple = Color(0xFF8B5CF6);
  static const accentPink = Color(0xFFF03E97);
  static const accentLavender = Color(0xFFE9D5FF);
  static const emerald = Color(0xFF34D399);
  static const gradientPurplePink = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA377FF), Color(0xFFF03E97)],
  );
  static const gradientHeader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6D28D9), Color(0xFF8B5CF6), Color(0xFF4C1D95)],
  );
}

ThemeData buildFinsheTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: FinsheColors.accentPurple,
    brightness: Brightness.dark,
    primary: FinsheColors.accentPurple,
    secondary: FinsheColors.emerald,
  ).copyWith(
    surface: FinsheColors.bg,
    surfaceContainerLowest: const Color(0xFF0C0C12),
    surfaceContainerLow: FinsheColors.cardMuted,
    surfaceContainer: FinsheColors.card,
    surfaceContainerHigh: const Color(0xFF252530),
    surfaceContainerHighest: const Color(0xFF2C2C38),
    onSurface: Colors.white,
    onSurfaceVariant: const Color(0xFFB0B0C0),
    outline: FinsheColors.outlineSoft,
    outlineVariant: const Color(0xFF3D3D4A),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: FinsheColors.bg,
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      backgroundColor: FinsheColors.bg,
      foregroundColor: scheme.onSurface,
      titleTextStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      color: FinsheColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: FinsheColors.outlineSoft.withValues(alpha: 0.6)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      height: 72,
      backgroundColor: FinsheColors.cardMuted,
      indicatorColor: FinsheColors.accentPurple.withValues(alpha: 0.28),
      labelTextStyle: WidgetStateProperty.resolveWith((s) {
        final selected = s.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? Colors.white : scheme.onSurfaceVariant,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((s) {
        final selected = s.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? FinsheColors.accentLavender : scheme.onSurfaceVariant,
          size: 24,
        );
      }),
    ),
    tabBarTheme: TabBarThemeData(
      dividerColor: Colors.transparent,
      labelColor: Colors.white,
      unselectedLabelColor: scheme.onSurfaceVariant,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: FinsheColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: FinsheColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: FinsheColors.cardMuted,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: FinsheColors.cardMuted,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: FinsheColors.outlineSoft.withValues(alpha: 0.8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: FinsheColors.accentPurple, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.75)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: FinsheColors.accentPurple,
        foregroundColor: Colors.white,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: FinsheColors.accentLavender),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: FinsheColors.accentPurple,
    ),
    dividerTheme: DividerThemeData(
      color: FinsheColors.outlineSoft.withValues(alpha: 0.5),
      thickness: 1,
    ),
  );
}
