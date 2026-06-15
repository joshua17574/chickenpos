import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/utils/responsive.dart';

/// Adaptive app shell:
///  - Tablet/desktop: persistent [NavigationRail] on the left.
///  - Phone: [NavigationBar] at the bottom.
class PosShell extends StatelessWidget {
  const PosShell({required this.child, super.key});

  final Widget child;

  static const _destinations = <_NavDest>[
    _NavDest(Routes.menu, Icons.restaurant_menu, 'Menu'),
    _NavDest(Routes.kds, Icons.kitchen, 'Kitchen'),
    _NavDest(Routes.admin, Icons.admin_panel_settings, 'Admin'),
  ];

  int _indexFor(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;
    final i = _destinations.indexWhere((d) => d.route == loc);
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final index = _indexFor(context);

    if (context.isPhone) {
      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => context.go(_destinations[i].route),
          destinations: [
            for (final d in _destinations)
              NavigationDestination(icon: Icon(d.icon), label: d.label),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: index,
            onDestinationSelected: (i) => context.go(_destinations[i].route),
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NavDest {
  const _NavDest(this.route, this.icon, this.label);
  final String route;
  final IconData icon;
  final String label;
}
