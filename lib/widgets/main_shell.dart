import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../viewmodels/nav_viewmodel.dart';

class ShellTab {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;

  const ShellTab(this.label, this.icon, this.selectedIcon, this.page);
}

/// A centre button docked in the middle of the bottom bar.
class ShellAction {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const ShellAction(this.icon, this.tooltip, this.onPressed);
}

/// Bottom-navigation scaffold shared by the user and supplier roles.
/// With [centerAction], tabs are split evenly around a docked, always-coloured
/// centre button (needs an even number of tabs).
class MainShell extends StatelessWidget {
  final List<ShellTab> tabs;
  final ShellAction? centerAction;

  const MainShell({super.key, required this.tabs, this.centerAction});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavViewModel>();
    final body = IndexedStack(
      index: nav.index,
      children: [for (final t in tabs) t.page],
    );

    if (centerAction == null) {
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: nav.index,
          onDestinationSelected: nav.setIndex,
          destinations: [
            for (final t in tabs)
              NavigationDestination(
                icon: Icon(t.icon),
                selectedIcon: Icon(t.selectedIcon),
                label: t.label,
              ),
          ],
        ),
      );
    }

    final half = tabs.length ~/ 2;
    Widget item(int i) => Expanded(
      child: _NavItem(
        tab: tabs[i],
        selected: nav.index == i,
        onTap: () => nav.setIndex(i),
      ),
    );

    return Scaffold(
      body: body,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        tooltip: centerAction!.tooltip,
        onPressed: centerAction!.onPressed,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: Icon(centerAction!.icon, size: 28),
      ),
      bottomNavigationBar: BottomAppBar(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        padding: EdgeInsets.zero,
        height: 68,
        child: Row(
          children: [
            for (var i = 0; i < half; i++) item(i),
            const SizedBox(width: 72), // room for the docked button
            for (var i = half; i < tabs.length; i++) item(i),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final ShellTab tab;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? tab.selectedIcon : tab.icon, color: color),
          const SizedBox(height: 2),
          Text(
            tab.label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
