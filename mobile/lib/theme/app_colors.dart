import 'package:flutter/material.dart';

/// TWR REAL ESTATE brand palette.
class AppColors {
  const AppColors._();

  /// Primary brand navy.
  static const Color primary = Color(0xFF081C34);
  static const Color primaryLight = Color(0xFF12314F);
  static const Color primaryDark = Color(0xFF04101F);

  static const Color white = Color(0xFFFFFFFF);
  static const Color royalBlue = Color(0xFF1D4ED8);
  static const Color gold = Color(0xFFC5A253);
  static const Color goldLight = Color(0xFFE3CB8F);
  static const Color black = Color(0xFF0B0B0B);

  static const Color lightGrey = Color(0xFFF4F6F8);
  static const Color border = Color(0xFFE2E6EB);
  static const Color textPrimary = Color(0xFF10202F);
  static const Color textSecondary = Color(0xFF6B7A88);

  static const Color hot = Color(0xFFD1495B);
  static const Color warm = Color(0xFFE08D2F);
  static const Color cold = Color(0xFF4A7FA5);

  static const Color success = Color(0xFF1E8E5A);
  static const Color danger = Color(0xFFC0392B);

  /// Version-safe translucency helper.
  ///
  /// `Color.withValues(alpha:)` requires Flutter 3.27+ and `withOpacity()` is
  /// deprecated on newer SDKs. Building the colour explicitly compiles on both.
  static Color alpha(Color color, double opacity) {
    final int argb = color.value;
    return Color.fromRGBO(
      (argb >> 16) & 0xFF,
      (argb >> 8) & 0xFF,
      argb & 0xFF,
      opacity,
    );
  }
}
