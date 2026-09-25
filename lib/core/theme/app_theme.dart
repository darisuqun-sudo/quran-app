import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color primaryEmerald = Color(0xFF1B5E20);
  static const Color deepEmerald = Color(0xFF0F291E);
  static const Color accentGold = Color(0xFFD4AF37);
  static const Color creamBackground = Color(0xFFFBF9F3);
  static const Color parchmentCard = Color(0xFFFDFCF7);

  static ThemeData lightTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primaryEmerald,
      primary: primaryEmerald,
      secondary: accentGold,
      surface: parchmentCard,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: creamBackground,
      fontFamily: 'NotoNaskhArabic',
      textTheme: ThemeData.light().textTheme.apply(
            fontFamily: 'NotoNaskhArabic',
            bodyColor: const Color(0xFF1C2826),
            displayColor: const Color(0xFF0F291E),
          ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: primaryEmerald,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: parchmentCard,
        elevation: 1.5,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: accentGold.withValues(alpha: 0.22), width: 1),
        ),
      ),
    );
  }

  static ThemeData darkTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E7D32),
      primary: const Color(0xFF66BB6A),
      secondary: accentGold,
      surface: const Color(0xFF132A21),
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF0B1913),
      fontFamily: 'NotoNaskhArabic',
      textTheme: ThemeData.dark().textTheme.apply(
            fontFamily: 'NotoNaskhArabic',
            bodyColor: const Color(0xFFE8F5E9),
            displayColor: Colors.white,
          ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF11261E),
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF152E24),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: accentGold.withValues(alpha: 0.25), width: 1),
        ),
      ),
    );
  }
}
