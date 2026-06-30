import 'package:flutter/material.dart';

/// Brand colour palette for Trvsty.
///
/// Derived from the design specification:
/// - Background: #1A1A2E
/// - Accent:     #00B4D8
/// - Success:    #00C853
/// - Error:      #FF5252
class AppColors {
  const AppColors._();

  static const Color background = Color(0xFF1A1A2E);
  static const Color surface = Color(0xFF24243E);
  static const Color accent = Color(0xFF00B4D8);
  static const Color accentDark = Color(0xFF0096B7);
  static const Color success = Color(0xFF00C853);
  static const Color error = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFB300);

  static const Color card = Color(0x0AFFFFFF); // Premium glassmorphism base
  static const Color cardForeground = Colors.white;

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B3C7);
  static const Color textMuted = Color(0xFF7B7E94);

  static const Color divider = Color(0x1FFFFFFF);

  /// Trust-score gradient anchors (red → amber → green).
  static const Color trustLow = error;
  static const Color trustMedium = warning;
  static const Color trustHigh = success;
}
