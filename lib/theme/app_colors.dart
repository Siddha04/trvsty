import 'package:flutter/material.dart';

/// Brand colour palette for Trvsty.
///
/// Derived from the design specification:
/// - Background: #1A1A2E  (deep navy)
/// - Accent:     #00B4D8  (electric cyan)
/// - Success:    #00C853
/// - Error:      #FF5252
///
/// Card treatment (Option B — white cards on dark navy):
/// All content cards are solid white ([card]) rendered on the dark [background].
/// Text inside cards uses [cardForeground] (near-black) and [cardMuted] (muted
/// gray) for optimal contrast against the white surface. Every screen in the
/// app routes its cards through [AppCard], which sources colors from this file.
class AppColors {
  const AppColors._();

  static const Color background = Color(0xFF1A1A2E);
  static const Color surface = Color(0xFF24243E);
  static const Color accent = Color(0xFF00B4D8);
  static const Color accentDark = Color(0xFF0096B7);
  static const Color success = Color(0xFF00C853);
  static const Color error = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFB300);

  /// White card surface — the primary content island on the dark background.
  static const Color card = Colors.white;

  /// Primary text on a [card] surface (near-black for WCAG AA contrast).
  static const Color cardForeground = Color(0xFF14162B);

  /// Secondary / muted text drawn *on top of* a white [card] (e.g. subtitles).
  /// Distinct from [textSecondary], which is for text on the dark background.
  static const Color cardMuted = Color(0xFF8B92A5);

  /// Hairline border used on [AppCard] to separate card from background.
  static const Color cardBorder = Color(0x14000000);

  /// Drop-shadow base colour for [AppCard]. Semi-transparent black works on
  /// both white cards and the dark background without a harsh cut.
  static const Color shadowBase = Color(0x42000000); // ~26% black

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B3C7);
  static const Color textMuted = Color(0xFF7B7E94);

  static const Color divider = Color(0x1FFFFFFF);

  /// Trust-score gradient anchors (red → amber → green).
  static const Color trustLow = error;
  static const Color trustMedium = warning;
  static const Color trustHigh = success;
}
