import 'package:flutter/material.dart';

class AppTheme {
  // ألوان مستوحاة من تطبيق Fazlaka Pay (الأول)
  static const Color primaryDarkGreen = Color(0xFF0A4D44); // الأخضر الغامق (الرئيسي)
  static const Color secondaryMint = Color(0xFF80E5D0);    // الأخضر الفاتح (النعناعي)
  static const Color bgColor = Color(0xFFF4F7F6);          // لون الخلفية الفاتح
  static const Color darkBgColor = Color(0xFF121A1A);      // لون الخلفية الداكن

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Cairo',
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryDarkGreen,
      primary: primaryDarkGreen,
      secondary: secondaryMint,
      background: bgColor,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: bgColor,
    
    // تخصيص شكل الـ AppBar عشان يبقى زي الأول
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryDarkGreen,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    ),

    // تخصيص الأزرار
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryDarkGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Cairo',
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryDarkGreen,
      primary: primaryDarkGreen,
      secondary: secondaryMint,
      background: darkBgColor,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: darkBgColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryDarkGreen,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    ),
  );
}
