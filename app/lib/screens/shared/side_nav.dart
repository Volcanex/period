import 'package:flutter/material.dart';

import '../../theme/layout.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';
import 'tab_bar.dart';

/// Tablet and desktop navigation: the bottom tab bar turned on its side.
///
/// Same [AppTab] set and same active treatment as `AppBottomTabBar` — ink vs
/// graphite2, with the 24x2 indicator rotated to a 2x24 bar on the leading
/// edge. [expanded] switches from an icon-over-label rail to a wider sidebar
/// with the label beside the icon.
class AppSideNav extends StatelessWidget {
  final AppTab current;
  final ValueChanged<AppTab> onChanged;
  final bool expanded;

  const AppSideNav({
    super.key,
    required this.current,
    required this.onChanged,
    required this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: expanded ? Layout.sidebarWidth : Layout.railWidth,
      decoration: BoxDecoration(
        color: Tokens.base,
        border: Border(right: BorderSide(color: Tokens.borderSoft, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Matches the 52px TopBar so the rule runs unbroken across both.
          Container(
            height: 52,
            alignment: expanded ? Alignment.centerLeft : Alignment.center,
            padding: EdgeInsets.only(left: expanded ? 16 : 0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Tokens.borderSoft, width: 1),
              ),
            ),
            child: Text(expanded ? 'SEQUENCE' : 'SEQ', style: Type.eyebrow()),
          ),
          const SizedBox(height: 8),
          for (final tab in AppTab.values)
            _NavItem(
              tab: tab,
              active: tab == current,
              expanded: expanded,
              onTap: () => onChanged(tab),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final AppTab tab;
  final bool active;
  final bool expanded;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.active,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? Tokens.ink : Tokens.graphite2;
    final indicator = SizedBox(
      width: 2,
      height: 24,
      child: active ? ColoredBox(color: Tokens.ink) : null,
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: expanded ? 44 : 60,
          child: expanded
              ? Row(
                  children: [
                    indicator,
                    const SizedBox(width: 14),
                    Icon(tab.icon, size: 18, color: color),
                    const SizedBox(width: 10),
                    Text(
                      tab.label,
                      style: Type.mono(
                        size: 11,
                        color: color,
                        letterSpacingEm: 0.04,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    indicator,
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(tab.icon, size: 20, color: color),
                          const SizedBox(height: 3),
                          Text(
                            tab.label,
                            style: Type.mono(
                              size: 9,
                              color: color,
                              letterSpacingEm: 0.04,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 2),
                  ],
                ),
        ),
      ),
    );
  }
}
