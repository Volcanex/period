import 'package:flutter/material.dart';

/// Design tokens for Period — direct port of `colors_and_type.css`, with a
/// small app-level dark theme layered on top for the live demo.
class Tokens {
  Tokens._();

  static bool _dark = false;

  static bool get dark => _dark;
  static void setDark(bool value) => _dark = value;

  // ---- brand palette ----
  static Color get ink => _dark ? const Color(0xFFF4F1EA) : _inkLight;
  static Color get paper => _dark ? const Color(0xFF121217) : _paperLight;
  static Color get eggshell => _dark ? const Color(0xFF1B1B22) : _eggshellLight;
  static const oxide = Color(0xFF7A1F1F);
  static const oxidePressed = Color(0xFF5A1818);
  static const ember = Color(0xFFE85D2C);
  static Color get graphite => _dark ? const Color(0xFFC5C2BE) : _graphiteLight;
  static Color get graphite2 =>
      _dark ? const Color(0xFFA09C98) : _graphite2Light;

  // ---- sky scale ----
  static const sky1 = Color(0xFFEAF1F7);
  static const sky2 = Color(0xFFC7D8E8);
  static const sky3 = Color(0xFF8FAFCB);
  static const sky4 = Color(0xFF4A6E8F);
  static const sky5 = Color(0xFF1F3A55);

  // ---- cycle phase tints ----
  static const phaseMenstrual = oxide;
  static Color get phaseMenstrualSoft =>
      _dark ? const Color(0xFF342024) : const Color(0xFFE8D2D2);
  static Color get phaseFollicular =>
      _dark ? const Color(0xFF252631) : const Color(0xFFFFFFFF);
  static Color get phaseFollicularEdge =>
      _dark ? const Color(0xFF3A4654) : const Color(0xFFD8E2EC);
  static Color get phaseOvulation =>
      _dark ? const Color(0xFF223244) : const Color(0xFFB7CFE2);
  static Color get phaseOvulationDeep => _dark ? const Color(0xFF8FAFCB) : sky4;
  static Color get phaseLuteal =>
      _dark ? const Color(0xFF322838) : const Color(0xFFDCD0E0);
  static Color get phaseLutealDeep =>
      _dark ? const Color(0xFFB99AC7) : const Color(0xFF8A6E96);

  // Calendar-only blends: pale enough that the grid stays calm.
  static Color get phaseCalMenstrual =>
      _dark ? const Color(0xFF2A171B) : const Color(0xFFF2D8D8);
  static Color get phaseCalFollicular =>
      _dark ? const Color(0xFF22232B) : const Color(0xFFFFFFFF);
  static Color get phaseCalOvulation =>
      _dark ? const Color(0xFF1C2A38) : const Color(0xFFD6E2EE);
  static Color get phaseCalLuteal =>
      _dark ? const Color(0xFF2A2230) : const Color(0xFFEDE6F0);
  static Color get phaseCalMenstrualGlow =>
      _dark ? const Color(0xFFFFA45C) : const Color(0xFFF2A447);
  static Color get phaseCalFollicularGlow =>
      _dark ? const Color(0xFFFFC078) : const Color(0xFFF4B15F);
  static Color get phaseCalOvulationGlow =>
      _dark ? const Color(0xFFFFBB70) : const Color(0xFFEFA85A);
  static Color get phaseCalLutealGlow =>
      _dark ? const Color(0xFFFFB08A) : const Color(0xFFEFA06D);
  static Color get phaseCalMenstrualToday =>
      _dark ? const Color(0xFF9F3A20) : const Color(0xFFE86D2D);
  static Color get phaseCalFollicularToday =>
      _dark ? const Color(0xFF5C4A1E) : const Color(0xFFFFE79A);
  static Color get phaseCalOvulationToday =>
      _dark ? const Color(0xFF245C82) : const Color(0xFF9FD7F5);
  static Color get phaseCalLutealToday =>
      _dark ? const Color(0xFF6C426D) : const Color(0xFFE9B7CF);

  // ---- semantic roles ----
  static Color get base =>
      _dark ? const Color(0xFF0E0E13) : const Color(0xFFF2F5F8);
  static Color get bg =>
      _dark ? const Color(0xFF171820) : const Color(0xFFFFFFFF);
  static Color get bgElevated => eggshell;
  static Color get bgTonal =>
      _dark ? const Color(0xFF202632) : const Color(0xFFEAF1F7);
  static Color get fg => ink;
  static Color get fgMuted => graphite2;
  static const fgOnOxide = Color(0xFFFFFFFF);
  static Color get border => graphite;
  // app.css pins border-soft to 40% (the colors_and_type.css default is 55%).
  static Color get borderSoft =>
      graphite.withValues(alpha: _dark ? 0.32 : 0.40);

  static const _inkLight = Color(0xFF0E0E10);
  static const _paperLight = Color(0xFFF4F1EA);
  static const _eggshellLight = Color(0xFFFBF8F2);
  static const _graphiteLight = Color(0xFF2A2A2E);
  static const _graphite2Light = Color(0xFF4A4A50);

  // ---- spacing (4px base) ----
  static const sp1 = 4.0;
  static const sp2 = 8.0;
  static const sp3 = 12.0;
  static const sp4 = 16.0;
  static const sp6 = 24.0;
  static const sp8 = 32.0;
  static const sp12 = 48.0;

  // ---- type scale ----
  static const fsXs = 12.0;
  static const fsSm = 13.0;
  static const fsMd = 15.0;
  static const fsLg = 17.0;
  static const fsXl = 20.0;
  static const fs2xl = 24.0;

  // ---- weights ----
  static const fwRegular = FontWeight.w400;
  static const fwMedium = FontWeight.w500;
  static const fwSemibold = FontWeight.w600;
  static const fwBold = FontWeight.w700;

  // ---- radii ----
  static const r1 = 2.0;
  static const r2 = 4.0;
  static const r3 = 8.0;

  // ---- borders ----
  static const bwHair = 1.0;
  static const bwRule = 1.5;
  static const bwStrong = 2.0;

  // ---- motion ----
  static const durFast = Duration(milliseconds: 120);
  static const durBase = Duration(milliseconds: 150);
  static const durSlow = Duration(milliseconds: 600);
  static const ease = Cubic(0.2, 0, 0, 1);
}
