import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../tokens/colors.dart';
import '../../tokens/typography.dart';
import '../../tokens/spacing.dart';
import '../../tokens/radii.dart';

/// Premium bottom navigation bar with 5 tabs.
///
/// Matches mockup exactly: Home, Bookings, Earnings, Calendar, Profile
/// Features:
/// - Full width (no side margins)
/// - Subtle top border
/// - Cyan accent for active tab
/// - Haptic feedback on selection
class PremiumNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const PremiumNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  // 5 tabs matching mockup exactly
  static const List<_NavItemData> _items = [
    _NavItemData(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavItemData(
      icon: Icons.list_alt_outlined,
      activeIcon: Icons.list_alt_rounded,
      label: 'Bookings',
    ),
    _NavItemData(
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet_rounded,
      label: 'Earnings',
    ),
    _NavItemData(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today_rounded,
      label: 'Calendar',
    ),
    _NavItemData(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? DesignColors.surface : DesignColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark
                ? DesignColors.glassBorder
                : DesignColors.lightBorderSubtle,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final isActive = index == currentIndex;

              return _NavItem(
                icon: isActive ? item.activeIcon : item.icon,
                label: item.label,
                isActive: isActive,
                onTap: () {
                  // Haptic feedback
                  HapticFeedback.selectionClick();
                  onTap(index);
                },
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final activeColor = DesignColors.accent;
    final inactiveColor =
        isDark ? DesignColors.textMuted : DesignColors.lightTextMuted;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive
                    ? activeColor.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(DesignRadii.md),
              ),
              child: Icon(
                icon,
                size: DesignSpacing.iconMd,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: (isActive
                      ? DesignTypography.navLabelActive
                      : DesignTypography.navLabel)
                  .copyWith(
                color: isActive ? activeColor : inactiveColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Alternative floating glass morphism nav bar (more premium but less standard).
/// Use this if the standard nav bar doesn't feel premium enough.
class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignRadii.bottomNav),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: DesignColors.surface.withOpacity(0.85),
            borderRadius: BorderRadius.circular(DesignRadii.bottomNav),
            border: Border.all(
              color: DesignColors.glassBorder,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(PremiumNavBar._items.length, (index) {
              final item = PremiumNavBar._items[index];
              final isActive = index == currentIndex;

              return _NavItem(
                icon: isActive ? item.activeIcon : item.icon,
                label: item.label,
                isActive: isActive,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTap(index);
                },
              );
            }),
          ),
        ),
      ),
    );
  }
}
