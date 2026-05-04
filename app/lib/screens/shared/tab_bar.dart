import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../theme/tokens.dart';
import '../../theme/typography.dart';

enum AppTab { today, calendar, insights, trackers, exports }

extension AppTabLabel on AppTab {
  String get label => switch (this) {
        AppTab.today => 'today',
        AppTab.calendar => 'calendar',
        AppTab.insights => 'insights',
        AppTab.trackers => 'trackers',
        AppTab.exports => 'export',
      };

  IconData get icon => switch (this) {
        AppTab.today => PhosphorIcons.circle(),
        AppTab.calendar => PhosphorIcons.calendarBlank(),
        AppTab.insights => PhosphorIcons.chartLine(),
        AppTab.trackers => PhosphorIcons.listChecks(),
        AppTab.exports => PhosphorIcons.arrowSquareOut(),
      };
}

class AppBottomTabBar extends StatelessWidget {
  final AppTab current;
  final ValueChanged<AppTab> onChanged;

  const AppBottomTabBar({
    super.key,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Tokens.base,
        border: Border(top: BorderSide(color: Tokens.borderSoft, width: 1)),
      ),
      child: Row(
        children: [
          for (final tab in AppTab.values)
            Expanded(child: _TabItem(tab: tab, active: tab == current, onTap: () => onChanged(tab))),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final AppTab tab;
  final bool active;
  final VoidCallback onTap;

  const _TabItem({required this.tab, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? Tokens.ink : Tokens.graphite2;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            if (active)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 24,
                    height: 2,
                    color: Tokens.ink,
                  ),
                ),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(tab.icon, size: 20, color: color),
                  const SizedBox(height: 3),
                  Text(
                    tab.label,
                    style: Type.mono(size: 9, color: color, letterSpacingEm: 0.04),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
