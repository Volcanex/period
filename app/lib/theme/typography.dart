import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// Three families: Space Grotesk (display), Inter (body), JetBrains Mono.
/// Loaded at runtime via google_fonts; bake to assets later if perf demands.
class Type {
  Type._();

  static TextStyle display({
    double size = Tokens.fsMd,
    FontWeight weight = Tokens.fwMedium,
    Color color = Tokens.ink,
    double height = 1.1,
    double letterSpacingEm = -0.01,
  }) =>
      GoogleFonts.spaceGrotesk(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: size * letterSpacingEm,
      );

  static TextStyle body({
    double size = Tokens.fsMd,
    FontWeight weight = Tokens.fwRegular,
    Color color = Tokens.ink,
    double height = 1.55,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );

  static TextStyle mono({
    double size = Tokens.fsXs,
    FontWeight weight = Tokens.fwRegular,
    Color color = Tokens.ink,
    double letterSpacingEm = 0.04,
    double height = 1.3,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: size * letterSpacingEm,
      );

  /// Mono caps used for eyebrows / muted-mono labels: 10px, +0.10em tracking,
  /// uppercase, graphite2.
  static TextStyle eyebrow({
    Color color = Tokens.graphite2,
    double size = 10,
    double tracking = 0.10,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: Tokens.fwRegular,
        color: color,
        height: 1.0,
        letterSpacing: size * tracking,
      );
}
