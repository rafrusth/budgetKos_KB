import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SlideUpPageTransitionsBuilder extends PageTransitionsBuilder {
  const SlideUpPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const curve = Curves.fastEaseInToSlowEaseOut;

    // The page coming in (push) or going out (pop)
    var primaryTween = Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)
        .chain(CurveTween(curve: curve));
    
    // The page underneath being covered (push) or uncovered (pop)
    var secondaryTween = Tween(begin: Offset.zero, end: const Offset(0.0, -1.0))
        .chain(CurveTween(curve: curve));

    return SlideTransition(
      position: secondaryAnimation.drive(secondaryTween),
      child: SlideTransition(
        position: animation.drive(primaryTween),
        child: child,
      ),
    );
  }
}

class AppTheme {
  // Color Palette Reference:
  // 1. Dark Blue: #295CA3
  // 2. Vivid Blue: #148CD5
  // 3. Light Blue: #4BA6E6
  // 4. Soft Blue: #CBE4F5

  static const pageTransitionsTheme = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: SlideUpPageTransitionsBuilder(),
      TargetPlatform.iOS: SlideUpPageTransitionsBuilder(),
      TargetPlatform.windows: SlideUpPageTransitionsBuilder(),
      TargetPlatform.macOS: SlideUpPageTransitionsBuilder(),
      TargetPlatform.linux: SlideUpPageTransitionsBuilder(),
    },
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      pageTransitionsTheme: pageTransitionsTheme,
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
      pageTransitionsTheme: pageTransitionsTheme,
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
