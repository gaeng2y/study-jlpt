import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static const Color themeColor = Color(0xFF4A7DFF);
  static const Color accentColor = Color(0xFF2E62E7);
  static const Color secondaryColor = Color(0xFF31B8A9);

  static ThemeData light(TargetPlatform platform) {
    return _glassTheme(platform);
  }

  static ThemeData _glassTheme(TargetPlatform platform) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: themeColor,
      brightness: Brightness.light,
    ).copyWith(
      primary: accentColor,
      onPrimary: Colors.white,
      secondary: secondaryColor,
      onSecondary: Colors.white,
      surface: const Color(0xFFF4F7FF),
      onSurface: const Color(0xFF13203F),
      onSurfaceVariant: const Color(0xFF2B3D66),
    );

    return ThemeData(
      platform: platform,
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFE8EEFF),
      textTheme: ThemeData.light().textTheme.apply(
            bodyColor: const Color(0xFF13203F),
            displayColor: const Color(0xFF13203F),
          ),
      primaryTextTheme: ThemeData.light().textTheme.apply(
            bodyColor: const Color(0xFF13203F),
            displayColor: const Color(0xFF13203F),
          ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF13203F),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cupertinoOverrideTheme: const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: accentColor,
        scaffoldBackgroundColor: Color(0xFFE8EEFF),
        barBackgroundColor: Color(0x00000000),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF1B2A55)),
      primaryIconTheme: const IconThemeData(color: Color(0xFF1B2A55)),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.38),
        indicatorColor: themeColor.withValues(alpha: 0.22),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: accentColor);
          }
          return const IconThemeData(color: Color(0xFF5A6A93));
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: Color(0xFF1B2A55),
              fontWeight: FontWeight.w700,
            );
          }
          return const TextStyle(
            color: Color(0xFF5A6A93),
            fontWeight: FontWeight.w600,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.24),
        hintStyle: const TextStyle(color: Color(0xFF67779E)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.34),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.34),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: accentColor,
            width: 1.3,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 46),
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          disabledBackgroundColor: const Color(0xFF9AAEDB),
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 46),
          foregroundColor: const Color(0xFF1F3F95),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.42),
            width: 1.1,
          ),
          backgroundColor: Colors.white.withValues(alpha: 0.20),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 44),
          foregroundColor: const Color(0xFF274EBA),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.25),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.34),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.23),
        selectedColor: themeColor.withValues(alpha: 0.25),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.34),
        ),
        labelStyle: const TextStyle(
          color: Color(0xFF162B57),
          fontWeight: FontWeight.w600,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return themeColor.withValues(alpha: 0.24);
            }
            return Colors.white.withValues(alpha: 0.22);
          }),
          foregroundColor: const WidgetStatePropertyAll(Color(0xFF223768)),
          side: WidgetStatePropertyAll(
            BorderSide(color: Colors.white.withValues(alpha: 0.34)),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }
}
