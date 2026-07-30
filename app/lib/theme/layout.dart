import 'package:flutter/widgets.dart';

/// Size classes for the app shell.
///
/// [compact] is the phone layout the design was drawn for and is the only one
/// that gets a bottom tab bar. [medium] and [expanded] move navigation to a
/// side rail and hand the extra width to grids rather than to line length.
enum Breakpoint { compact, medium, expanded }

class Layout {
  Layout._();

  static const double mediumMin = 700;
  static const double expandedMin = 1100;

  static Breakpoint forWidth(double width) => width >= expandedMin
      ? Breakpoint.expanded
      : width >= mediumMin
      ? Breakpoint.medium
      : Breakpoint.compact;

  static Breakpoint of(BuildContext context) =>
      forWidth(MediaQuery.sizeOf(context).width);

  /// Text-bearing columns stop here — past this the measure gets hard to read.
  static const double readableMax = 680;

  /// Pages that put two columns side by side, which earn the extra width.
  static const double wideMax = 1080;

  /// Two columns only once each half still clears a readable measure.
  static const double twoColumnMin = 900;

  /// Width of a page's content column for a given available width. The top bar
  /// and the body under it must both use this, or the title sits at a different
  /// left edge from the content it labels.
  static bool twoColumn(double width) => width >= twoColumnMin;
  static double pageMax(double width) =>
      twoColumn(width) ? wideMax : readableMax;

  /// Month grids: 7 cells of 56 plus six 4px gaps. Cells stop growing here so
  /// a desktop window gets a calendar rather than a wall of squares.
  static const double gridCellMax = 56;
  static const double gridGap = 4;
  static const double monthGridMax = gridCellMax * 7 + gridGap * 6;

  /// The calendar page is as wide as its grid plus the page gutters. Giving it
  /// a wider column would centre the grid inside it while the overview and the
  /// legend stayed left-aligned, so the month would sit visibly right of
  /// everything else on the page.
  static const double calendarMax = monthGridMax + 32;

  /// Setup reads as a single statement, so it keeps a narrow column at every
  /// size rather than stretching.
  static const double onboardingMax = 520;

  /// Above [compact], setup becomes a centred card. The height is fixed rather
  /// than fitted so the card does not resize between steps — the date grid is
  /// much taller than the privacy copy, and a card that jumps on every Continue
  /// looks broken.
  static const double onboardingCardMax = 560;
  static const double onboardingCardHeight = 620;

  static const double railWidth = 96;
  static const double sidebarWidth = 216;
}

/// Centres page content and caps its width, so a wide window widens the
/// margins rather than the line length.
class ContentPane extends StatelessWidget {
  final double maxWidth;
  final Widget child;

  const ContentPane({
    super.key,
    this.maxWidth = Layout.readableMax,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
