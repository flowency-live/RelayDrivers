import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design_system/foundations/backgrounds.dart';
import '../design_system/components/controls/nav_bar.dart';

/// Main app shell with premium background and bottom navigation.
///
/// Wraps all main app screens (post-auth) with:
/// - City blur background (dark mode)
/// - 5-tab bottom navigation
/// - Tab state persistence via StatefulNavigationShell
class AppShell extends StatelessWidget {
  /// GoRouter's navigation shell for tab persistence
  final StatefulNavigationShell navigationShell;

  const AppShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: navigationShell,
        bottomNavigationBar: PremiumNavBar(
          currentIndex: navigationShell.currentIndex,
          onTap: _onTabTapped,
        ),
      ),
    );
  }

  void _onTabTapped(int index) {
    // Use goBranch to switch tabs while preserving state
    navigationShell.goBranch(
      index,
      // If tapping the current tab, go to initial location (pop to root)
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

/// Minimal shell without background (for auth screens, etc.)
class MinimalShell extends StatelessWidget {
  final Widget child;

  const MinimalShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: child,
      ),
    );
  }
}
