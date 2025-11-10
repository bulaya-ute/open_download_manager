import 'package:flutter/material.dart';



final darkTheme = ThemeData.dark().copyWith(
  scaffoldBackgroundColor: const Color(0xFF101922),
  cardColor: const Color(0xFF0f172a),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF4A9EFF),
    secondary: Color(0xFF34D399),
    surface: Color(0xFF101826),
    surfaceBright: Color(0xFF172131),
    onSurface: Color(0xFFE8EAED),

    onSurfaceVariant: Color(0xFF9AA0B0),
    outline: Color(0xFF1e293b),
    outlineVariant: Color(0xff334155),
    error: Color(0xFFF87171), // Red for errors
  ),

  cardTheme: const CardThemeData(
    color: Color(0xFF101826),
    elevation: 0,
    margin: EdgeInsets.zero,
  ),

  inputDecorationTheme: InputDecorationTheme(
    contentPadding: EdgeInsets.all(8),
    filled: false,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF2F3544)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF2F3544)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF4A9EFF), width: 2),
    ),
  ),

  dividerTheme: DividerThemeData(
    color: Color(0xFF1e293b),
  ),
);

// Light theme colors (equivalent for light mode)
final lightTheme = ThemeData.light().copyWith(
  scaffoldBackgroundColor: const Color(0xFFFFFFFF), // Pure white
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF2563EB),
    // Strong blue for buttons/actions
    secondary: Color(0xFF10B981),
    // Green for success states
    surface: Color(0xFFF8F9FA),
    // Very light gray for cards
    onSurface: Color(0xFF1F2937),
    // Dark text
    onSurfaceVariant: Color(0xFF6B7280),
    // Medium gray for secondary text
    outline: Color(0xFFE5E7EB),
    // Light gray borders
    error: Color(0xFFEF4444), // Red for errors
  ),
  cardTheme: const CardThemeData(
    color: Color(0xFFF8F9FA),
    elevation: 0,
    margin: EdgeInsets.zero,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: false,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
    ),
  ),
);
