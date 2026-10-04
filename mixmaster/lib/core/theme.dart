import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0B0B0F);
  static const card = Color(0xFF18181C);
  static const border = Color(0xFF2A2A30);
  static const accent = Color(0xFFE29C2F);
  static const muted = Color(0xFF9A9AA3);
  static const green = Color(0xFF2BB673);
  static const red = Color(0xFFE5484D);
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      surface: AppColors.card,
    ),
    textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
  );
}
