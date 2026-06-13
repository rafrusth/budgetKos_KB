import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color Palette Reference:
  // 1. Dark Blue: #295CA3
  // 2. Vivid Blue: #148CD5
  // 3. Light Blue: #4BA6E6
  // 4. Soft Blue: #CBE4F5

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF148CD5), // Vivid Blue
        primary: const Color(0xFF148CD5), // Vivid Blue
        secondary: const Color(0xFF295CA3), // Dark Blue
        tertiary: const Color(0xFF4BA6E6), // Light Blue
        surface: const Color(0xFFFFFFFF),
        surfaceContainerHighest: const Color(0xFFF3F4F6), // Neutral Light Grey for cards/chips
      ),
      textTheme: GoogleFonts.interTextTheme(),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF148CD5),
        brightness: Brightness.dark,
        primary: const Color(0xFF4BA6E6), // Light Blue stands out in dark mode
        secondary: const Color(0xFFCBE4F5), // Soft Blue
        surface: const Color(0xFF1E293B),
        surfaceContainerHighest: const Color(0xFF334155), // Dark Slate Grey for cards
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    );
  }
}
