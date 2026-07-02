import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routes/route_paths.dart';
import '../../theme/app_colors.dart';
import '../../constants/app_spacing.dart';

/// Persistent navigation shell that wraps the four primary destinations:
/// Home, History, Profile, and Settings.
///
/// **Responsive behaviour**
/// - Mobile  (< 720 px wide) → [NavigationBar] pinned at the bottom.
/// - Desktop (≥ 720 px wide) → [NavigationRail] pinned on the left with
///   labels always shown and a "Trvsty" brand header above the destinations.
///
/// Deep routes (verification pipeline, report preview, etc.) push on top
/// of the shell and hide the navigation automatically because they are not
/// shell children.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  static const _kBreakpoint = 720.0;

  static const _tabs = <_NavTab>[
    _NavTab(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      route: RoutePaths.home,
    ),
    _NavTab(
      label: 'History',
      icon: Icons.history_outlined,
      selectedIcon: Icons.history,
      route: RoutePaths.history,
    ),
    _NavTab(
      label: 'Profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      route: RoutePaths.profile,
    ),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final idx = _tabs.indexWhere((t) => location.startsWith(t.route));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex(context);
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= _kBreakpoint;

    if (isDesktop) {
      return _DesktopShell(
        selectedIndex: selectedIndex,
        tabs: _tabs,
        child: child,
      );
    }

    return _MobileShell(
      selectedIndex: selectedIndex,
      tabs: _tabs,
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile shell — NavigationBar at the bottom
// ─────────────────────────────────────────────────────────────────────────────
class _MobileShell extends StatelessWidget {
  const _MobileShell({
    required this.selectedIndex,
    required this.tabs,
    required this.child,
  });

  final int selectedIndex;
  final List<_NavTab> tabs;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accent.withValues(alpha: 0.15),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        animationDuration: const Duration(milliseconds: 300),
        onDestinationSelected: (index) {
          if (index != selectedIndex) {
            context.go(tabs[index].route);
          }
        },
        destinations: tabs
            .map(
              (t) => NavigationDestination(
                icon: Icon(t.icon, color: AppColors.textSecondary),
                selectedIcon: Icon(t.selectedIcon, color: AppColors.accent),
                label: t.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Desktop shell — NavigationRail on the left
// ─────────────────────────────────────────────────────────────────────────────
class _DesktopShell extends StatelessWidget {
  const _DesktopShell({
    required this.selectedIndex,
    required this.tabs,
    required this.child,
  });

  final int selectedIndex;
  final List<_NavTab> tabs;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // ── Left navigation rail ─────────────────────────────────────
          _SideRail(selectedIndex: selectedIndex, tabs: tabs),
          // ── Vertical divider ─────────────────────────────────────────
          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: AppColors.surface,
          ),
          // ── Page content ─────────────────────────────────────────────
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SideRail extends StatelessWidget {
  const _SideRail({required this.selectedIndex, required this.tabs});

  final int selectedIndex;
  final List<_NavTab> tabs;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Brand header ──────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xxl,
                AppSpacing.xl,
                AppSpacing.xxl,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent,
                    ),
                    child: const Icon(
                      Icons.verified_user,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Trvsty',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                  ),
                ],
              ),
            ),
          ),

          // ── Nav items ─────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 0,
              ),
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final tab = tabs[index];
                final isSelected = index == selectedIndex;
                return _SideRailItem(
                  tab: tab,
                  isSelected: isSelected,
                  onTap: () {
                    if (!isSelected) context.go(tab.route);
                  },
                );
              },
            ),
          ),

          // ── Bottom padding ────────────────────────────────────────────
          const SafeArea(top: false, child: SizedBox(height: AppSpacing.xl)),
        ],
      ),
    );
  }
}

class _SideRailItem extends StatelessWidget {
  const _SideRailItem({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  final _NavTab tab;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                  ? AppColors.accent.withValues(alpha: 0.15)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? tab.selectedIcon : tab.icon,
                  color: isSelected ? AppColors.accent : AppColors.textSecondary,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  tab.label,
                  style: TextStyle(
                    color: isSelected ? AppColors.accent : AppColors.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab {
  const _NavTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
}
