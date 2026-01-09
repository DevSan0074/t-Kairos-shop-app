import 'package:flutter/material.dart';

class AppColors {
  // Sakura Palette
  static const Color primary = Color(0xFFFFB7C5); // Cherry Blossom Pink
  static const Color secondary = Color(0xFFFFC0CB); // Lighter Pink
  static const Color background = Color(0xFFFFF9FA); // Very light pinkish white
  static const Color surface =
      Colors.white; // This was likely missing or causing issues
  static const Color textDark = Color(0xFF4A4A4A); // Soft Dark Grey
  static const Color textLight = Color(0xFF9E9E9E);
  static const Color error = Color(0xFFE57373);
  static const Color success = Color(0xFF81C784);

  static const LinearGradient sakuraGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
