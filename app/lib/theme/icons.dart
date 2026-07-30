import 'package:flutter/widgets.dart';

/// Phosphor icons, regular weight.
///
/// Declared as plain `const IconData` against a subset font built by
/// `scripts/subset_icon_font.py`. Adding an icon means adding it to that
/// script's `ICONS` map and re-running it — the font ships only what is
/// listed here, so a code point with no glyph renders blank.
class Ph {
  Ph._();

  static const _family = 'Phosphor';

  static const lockSimple = IconData(0xE308, fontFamily: _family);
  static const deviceMobile = IconData(0xE1E0, fontFamily: _family);
  static const userCircle = IconData(0xE4C4, fontFamily: _family);
  static const code = IconData(0xE1BC, fontFamily: _family);
  static const caretLeft = IconData(0xE138, fontFamily: _family);
  static const caretRight = IconData(0xE13A, fontFamily: _family);
  static const calendarBlank = IconData(0xE10A, fontFamily: _family);
  static const minus = IconData(0xE32A, fontFamily: _family);
  static const plus = IconData(0xE3D4, fontFamily: _family);
  static const circle = IconData(0xE18A, fontFamily: _family);
  static const chartLine = IconData(0xE154, fontFamily: _family);
  static const listChecks = IconData(0xEADC, fontFamily: _family);
}
