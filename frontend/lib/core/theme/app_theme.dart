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
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF148CD5), // Vivid Blue
        primary: const Color(0xFF148CD5), // Vivid Blue
        secondary: const Color(0xFF295CA3), // Dark Blue
        tertiary: const Color(0xFF4BA6E6), // Light Blue
        background: const Color(0xFFF8FAFC), // Off-white/Neutral
        surface: const Color(0xFFFFFFFF),
        surfaceVariant: const Color(0xFFCBE4F5), // Soft Blue for cards/chips
      ),
      textTheme: GoogleFonts.interTextTheme(),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF148CD5),
        brightness: Brightness.dark,
        primary: const Color(0xFF4BA6E6), // Light Blue stands out in dark mode
        secondary: const Color(0xFFCBE4F5), // Soft Blue
        background: const Color(0xFF0F172A), // Very Dark Blue/Slate
        surface: const Color(0xFF1E293B),
        surfaceVariant: const Color(0xFF295CA3), // Dark Blue for cards
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    );
  }
}
