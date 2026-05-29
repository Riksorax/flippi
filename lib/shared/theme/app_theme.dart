import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F0F13),
      colorScheme: const ColorScheme.dark(
        surface: Color(0xFF18181F),
        primary: Color(0xFF7C6AF7),
        secondary: Color(0xFFF76A8C),
      ),
      fontFamily: 'sans-serif',
    );
  }
}
