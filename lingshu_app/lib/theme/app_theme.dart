import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 核心配色
  static const Color primaryGreen = Color(0xFF4A6D66); // 中式青绿 (近似)
  static const Color secondaryGreen = Color(0xFF6B8E85);
  static const Color backgroundBeige = Color(0xFFF8F8F2); // 淡雅米白
  static const Color cardBgColor = Colors.white;
  static const Color accentPeach = Color(0xFFF2C9C9); // 桃粉辅助色
  static const Color textMain = Color(0xFF2C3E50);
  static const Color textSub = Color(0xFF7F8C8D);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundBeige,
      colorScheme: ColorScheme.light(
        primary: primaryGreen,
        secondary: secondaryGreen,
        surface: cardBgColor,
      ),
      textTheme: GoogleFonts.notoSansScTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textMain,
          ),
          displayMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textMain,
          ),
          bodyLarge: TextStyle(fontSize: 16, color: textMain),
          bodyMedium: TextStyle(fontSize: 14, color: textSub),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
