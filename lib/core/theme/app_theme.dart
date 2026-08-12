import 'package:flutter/material.dart';

class AppTheme {
  // ── Palette ──────────────────────────────────────────────────────────
  static const Color accent       = Color(0xFF7C5CFC); // electric violet
  static const Color accentLight  = Color(0xFF9B7EFD);
  static const Color amber        = Color(0xFFFFB74D); // folders

  // Dark
  static const Color bgDark       = Color(0xFF0E0E10);
  static const Color surfaceDark  = Color(0xFF18181B);
  static const Color surface2Dark = Color(0xFF202024);
  static const Color borderDark   = Color(0xFF2E2E35);
  static const Color textDark     = Color(0xFFEAEAEA);
  static const Color subTextDark  = Color(0xFF71717A);

  // Light
  static const Color bgLight      = Color(0xFFF4F4F6);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surface2Light= Color(0xFFF9F9FB);
  static const Color borderLight  = Color(0xFFE4E4E7);
  static const Color textLight    = Color(0xFF18181B);
  static const Color subTextLight = Color(0xFF71717A);

  // ── Dark Theme ───────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accentLight,
        surface: surfaceDark,
        onSurface: textDark,
        outline: borderDark,
        error: Color(0xFFFF5C5C),
      ),
      fontFamily: '.AppleSystemUIFont',
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: subTextDark, size: 18),
      ),
      dividerTheme: const DividerThemeData(
        color: borderDark,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: surface2Dark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: borderDark),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2Dark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        labelStyle: const TextStyle(color: subTextDark, fontSize: 13),
        hintStyle: const TextStyle(color: subTextDark, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: subTextDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(fontSize: 13),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: subTextDark,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: subTextDark,
        textColor: textDark,
        selectedTileColor: Color(0xFF2A2438),
        selectedColor: accent,
        dense: true,
        visualDensity: VisualDensity.compact,
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(surface2Dark),
        headingTextStyle: const TextStyle(
          color: subTextDark,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        dataRowMinHeight: 36,
        dataRowMaxHeight: 36,
        dataTextStyle: const TextStyle(color: textDark, fontSize: 13),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return const Color(0xFF2A2438);
          if (states.contains(WidgetState.hovered)) return surface2Dark;
          return bgDark;
        }),
        columnSpacing: 16,
        horizontalMargin: 16,
        dividerThickness: 0,
        checkboxHorizontalMargin: 8,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: borderDark,
        linearMinHeight: 3,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface2Dark,
        contentTextStyle: const TextStyle(color: textDark, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: surface2Dark,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderDark),
        ),
        textStyle: const TextStyle(color: textDark, fontSize: 12),
        waitDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  // ── Light Theme ──────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgLight,
      colorScheme: const ColorScheme.light(
        primary: accent,
        secondary: accentLight,
        surface: surfaceLight,
        onSurface: textLight,
        outline: borderLight,
        error: Color(0xFFDC2626),
      ),
      fontFamily: '.AppleSystemUIFont',
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceLight,
        foregroundColor: textLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textLight,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: subTextLight, size: 18),
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: borderLight),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2Light,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        labelStyle: const TextStyle(color: subTextLight, fontSize: 13),
        hintStyle: const TextStyle(color: subTextLight, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: subTextLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(fontSize: 13),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: subTextLight,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: subTextLight,
        textColor: textLight,
        selectedTileColor: Color(0xFFF0EEFF),
        selectedColor: accent,
        dense: true,
        visualDensity: VisualDensity.compact,
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(surface2Light),
        headingTextStyle: const TextStyle(
          color: subTextLight,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        dataRowMinHeight: 36,
        dataRowMaxHeight: 36,
        dataTextStyle: const TextStyle(color: textLight, fontSize: 13),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return const Color(0xFFF0EEFF);
          if (states.contains(WidgetState.hovered)) return surface2Light;
          return surfaceLight;
        }),
        columnSpacing: 16,
        horizontalMargin: 16,
        dividerThickness: 0,
        checkboxHorizontalMargin: 8,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: borderLight,
        linearMinHeight: 3,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textLight,
        contentTextStyle: const TextStyle(color: surfaceLight, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: textLight,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: const TextStyle(color: surfaceLight, fontSize: 12),
        waitDuration: const Duration(milliseconds: 500),
      ),
    );
  }
}
