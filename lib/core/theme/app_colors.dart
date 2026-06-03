import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF5B2C83);
  static const Color primaryLight = Color(0xFF7B3FB3);
  static const Color primaryDark = Color(0xFF3D1D58);
  static const Color secondary = Color(0xFFF9C80E);
  static const Color background = Color(0xFF18181B);
  static const Color surface = Color(0xFF27272A);
  static const Color surfaceVariant = Color(0xFF3F3F46);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textDisabled = Color(0xFF52525B);
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E0E33), Color(0xFF2D1A4A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
