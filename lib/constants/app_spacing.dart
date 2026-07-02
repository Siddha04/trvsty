/// Layout spacing scale for Trvsty — 4 pt grid.
///
/// Use these instead of magic [SizedBox] heights to keep vertical rhythm
/// consistent across every screen. The scale mirrors Material Design's
/// baseline 4dp grid.
class AppSpacing {
  const AppSpacing._();

  /// 4 logical pixels — hairline gaps, icon padding.
  static const double xs = 4;

  /// 8 logical pixels — tight inline gaps.
  static const double sm = 8;

  /// 12 logical pixels — compact list item spacing.
  static const double md = 12;

  /// 16 logical pixels — standard list item / card padding rhythm.
  static const double lg = 16;

  /// 24 logical pixels — section gap inside a card or between header and list.
  static const double xl = 24;

  /// 32 logical pixels — between major sections.
  static const double xxl = 32;

  /// 40 logical pixels — generous bottom padding / scroll clearance.
  static const double xxxl = 40;
}
