import 'package:flutter/material.dart';

class AppTheme {
  static const Color pink = Color(0xFFFFB3BA);
  static const Color lavender = Color(0xFFB5B3FF);
  static const Color mint = Color(0xFFB3FFD9);
  static const Color cream = Color(0xFFFFF8F0);
  static const Color peach = Color(0xFFFFDFC4);
  static const Color skyBlue = Color(0xFFBAE1FF);
  static const Color coinGold = Color(0xFFFFD700);
  static const Color gemPurple = Color(0xFFBB86FC);
  static const Color softWhite = Color(0xFFFFFEFC);
  static const Color darkText = Color(0xFF4A4A4A);
  static const Color mediumOrange = Color.fromARGB(255, 246, 162, 73);
  static const Color darkOrange = Color(0xFFCC7722);
  static const Color mediumMint = Color.fromARGB(255, 88, 206, 153);
  static const Color darkMint = Color(0xFF2E9E6B);
  static const Color darkSkyBlue = Color.fromARGB(255, 80, 155, 225);

  static const List<Color> tagColors = [
    Color(0xFFFFB3BA), // pink
    Color(0xFFB5B3FF), // lavender
    Color(0xFFB3FFD9), // mint
    Color(0xFFFFDFC4), // peach
    Color(0xFFBAE1FF), // sky blue
    Color(0xFFFFE0B2), // light orange
    Color(0xFFF8BBD0), // rose
    Color(0xFFC8E6C9), // sage
    Color(0xFFD1C4E9), // lilac
    Color(0xFFFFECB3), // buttercup
    Color(0xFFB2DFDB), // teal
    Color(0xFFFFCDD2), // coral
  ];

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: pink,
        brightness: Brightness.light,
        surface: softWhite,
      ),
      scaffoldBackgroundColor: cream,
      appBarTheme: AppBarTheme(
        backgroundColor: pink,
        foregroundColor: darkText,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: darkText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: softWhite,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lavender,
          foregroundColor: darkText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: pink,
        foregroundColor: darkText,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: softWhite,
        selectedItemColor: pink,
        unselectedItemColor: Colors.grey.shade400,
        type: BottomNavigationBarType.fixed,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
