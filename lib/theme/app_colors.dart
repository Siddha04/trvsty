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

  /// Cards are solid white "islands" of content on the dark background —
  /// this is the primary content surface used by [AppCard] everywhere.
  static const Color card = Colors.white;
  static const Color cardForeground = Color(0xFF14162B);
  /// Secondary/muted text drawn *on top of* a white [card] (e.g. subtitles).
  /// Distinct from [textSecondary], which is for text on the dark background.
  static const Color cardMuted = Color(0xFF8B92A5);
  static const Color cardBorder = Color(0x14000000);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B3C7);
  static const Color textMuted = Color(0xFF7B7E94);

  static const Color divider = Color(0x1FFFFFFF);

  /// Trust-score gradient anchors (red → amber → green).
  static const Color trustLow = error;
  static const Color trustMedium = warning;
  static const Color trustHigh = success;
}
