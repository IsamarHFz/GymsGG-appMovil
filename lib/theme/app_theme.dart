import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1A1A1A);
  static const Color accentColor = Color(0xFFFFD700);
  static const Color iconColor = Colors.white;
  static const Color textColor = Color(0xFFB0B0B0);
  static const Color buttonColor = Color(0xFFFFD700);
  static const Color cardColor = Color(0xFF2A2A2A);

  static const BoxDecoration foundColor = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
    ),
  );
}
