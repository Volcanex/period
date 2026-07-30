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

  /// Month grids: 7 cells of 56 plus six 4px gaps. Cells stop growing here so
  /// a desktop window gets a calendar rather than a wall of squares.
  static const double gridCellMax = 56;
  static const double gridGap = 4;
  static const double monthGridMax = gridCellMax * 7 + gridGap * 6;

  /// Setup reads as a single statement, so it keeps a narrow column at every
  /// size rather than stretching.
  static const double onboardingMax = 520;

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
