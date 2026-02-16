import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static ThemeData light(TargetPlatform platform) {
    if (platform == TargetPlatform.iOS) {
      return _iosGlassTheme();
    }

    return _androidMaterialTheme();
  }

  static ThemeData _androidMaterialTheme() {
    const seed = Color(0xFF0A7B83);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      primary: const Color(0xFF0A7B83),
      secondary: const Color(0xFFF4A259),
      surface: const Color(0xFFFFF9F2),
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFFFFDF8),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE8E1D7)),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: Color(0xFFE7F4F5),
        selectedColor: Color(0xFF0A7B83),
      ),
    );
  }

  static ThemeData _iosGlassTheme() {
    const seed = Color(0xFF3D84FF);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      primary: const Color(0xFF2A6EEC),
      secondary: const Color(0xFF26B8A6),
      surface: const Color(0xBFFFFFFF),
    );

    return ThemeData(
      platform: TargetPlatform.iOS,
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF3F7FF),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF1E2A3A),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cupertinoOverrideTheme: const CupertinoThemeData(
        brightness: Brightness.light,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withOpacity(0.65),
        indicatorColor: Colors.white.withOpacity(0.4),
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: colorScheme.primary),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withOpacity(0.75),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: Colors.white.withOpacity(0.8)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white.withOpacity(0.75),
        selectedColor: colorScheme.primary.withOpacity(0.2),
      ),
    );
  }
}
