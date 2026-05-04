import 'package:flutter/material.dart';

/// Design tokens for Period — direct port of `colors_and_type.css`.
/// Source of truth: `/sequence/project/design/colors_and_type.css` from the
/// design handoff. Names match the CSS variables.
///
/// app.css overrides the dark-mode media query and pins the prototype to
/// light. We do the same here: the screen is always shown on a pale sky
/// "base" color, regardless of system theme.
class Tokens {
  Tokens._();

  // ---- brand palette ----
  static const ink = Color(0xFF0E0E10);
  static const paper = Color(0xFFF4F1EA);
  static const eggshell = Color(0xFFFBF8F2);
  static const oxide = Color(0xFF7A1F1F);
  static const oxidePressed = Color(0xFF5A1818);
  static const ember = Color(0xFFE85D2C);
  static const graphite = Color(0xFF2A2A2E);
  static const graphite2 = Color(0xFF4A4A50);

  // ---- sky scale ----
  static const sky1 = Color(0xFFEAF1F7);
  static const sky2 = Color(0xFFC7D8E8);
  static const sky3 = Color(0xFF8FAFCB);
  static const sky4 = Color(0xFF4A6E8F);
  static const sky5 = Color(0xFF1F3A55);

  // ---- cycle phase tints ----
  static const phaseMenstrual = oxide;
  static const phaseMenstrualSoft = Color(0xFFE8D2D2);
  static const phaseFollicular = Color(0xFFFFFFFF);
  static const phaseFollicularEdge = Color(0xFFD8E2EC);
  static const phaseOvulation = Color(0xFFB7CFE2);
  static const phaseOvulationDeep = sky4;
  static const phaseLuteal = Color(0xFFDCD0E0);
  static const phaseLutealDeep = Color(0xFF8A6E96);

  // ---- semantic roles (light, prototype-pinned) ----
  static const base = Color(0xFFF2F5F8); // app.css override: pale sky scaffold
  static const bg = Color(0xFFFFFFFF);
  static const bgElevated = eggshell;
  static const bgTonal = sky1;
  static const fg = ink;
  static const fgMuted = graphite2;
  static const fgOnOxide = Color(0xFFFFFFFF);
  static const border = graphite;
  // app.css pins border-soft to 40% (the colors_and_type.css default is 55%).
  static final borderSoft = graphite.withValues(alpha: 0.40);

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
