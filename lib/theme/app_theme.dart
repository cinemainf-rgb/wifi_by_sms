import 'package:material_ui/material_ui.dart';

class AppTheme {
  static const Color primaryIndigo = Color(0xFF1E3A8A);
  static const Color secondaryTeal = Color(0xFF0F766E);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Cairo',
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryIndigo,
      primary: primaryIndigo,
      secondary: secondaryTeal,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF4F6FA),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Cairo',
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryIndigo,
      primary: const Color(0xFF60A5FA),
      secondary: const Color(0xFF2DD4BF),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF0F172A),
  );
}
