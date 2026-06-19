import 'package:flutter/material.dart';

import 'tokens.dart';

/// Three families: Space Grotesk (display), Inter (body), JetBrains Mono.
/// Bundled as variable TTFs in `assets/fonts/` and declared in pubspec.yaml.
class Type {
  Type._();

  static const _display = 'SpaceGrotesk';
  static const _body = 'Inter';
  static const _mono = 'JetBrainsMono';

  static TextStyle display({
    double size = Tokens.fsMd,
    FontWeight weight = Tokens.fwMedium,
    Color? color,
    double height = 1.1,
    double letterSpacingEm = -0.01,
  }) => TextStyle(
    fontFamily: _display,
    fontSize: size,
    fontWeight: weight,
    color: color ?? Tokens.ink,
    height: height,
    letterSpacing: size * letterSpacingEm,
  );

  static TextStyle body({
    double size = Tokens.fsMd,
    FontWeight weight = Tokens.fwRegular,
    Color? color,
    double height = 1.55,
  }) => TextStyle(
    fontFamily: _body,
    fontSize: size,
    fontWeight: weight,
    color: color ?? Tokens.ink,
    height: height,
  );

  static TextStyle mono({
    double size = Tokens.fsXs,
    FontWeight weight = Tokens.fwRegular,
    Color? color,
    double letterSpacingEm = 0.04,
    double height = 1.3,
  }) => TextStyle(
    fontFamily: _mono,
    fontSize: size,
    fontWeight: weight,
    color: color ?? Tokens.ink,
    height: height,
    letterSpacing: size * letterSpacingEm,
  );

  /// Mono caps used for eyebrows / muted-mono labels: 10px, +0.10em tracking,
  /// uppercase, graphite2.
  static TextStyle eyebrow({
    Color? color,
    double size = 10,
    double tracking = 0.10,
  }) => TextStyle(
    fontFamily: _mono,
    fontSize: size,
    fontWeight: Tokens.fwRegular,
    color: color ?? Tokens.graphite2,
    height: 1.0,
    letterSpacing: size * tracking,
  );
}
