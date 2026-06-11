import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0D9488),
        primary: const Color(0xFF0D9488),
        secondary: const Color(0xFF6366F1),
        background: const Color(0xFFF8FAFC),
        surface: const Color(0xFFFFFFFF),
      ),
      textTheme: GoogleFonts.interTextTheme(),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2DD4BF),
        brightness: Brightness.dark,
        primary: const Color(0xFF2DD4BF),
        secondary: const Color(0xFF818CF8),
        background: const Color(0xFF0F172A),
        surface: const Color(0xFF1E293B),
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    );
  }
}
