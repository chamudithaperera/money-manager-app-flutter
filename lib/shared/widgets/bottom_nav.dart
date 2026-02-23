import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/theme.dart';

enum BottomTab { home, history, wishlist, profile }

class BottomNav extends StatelessWidget {
  const BottomNav({
    super.key,
    required this.activeTab,
    required this.onTabChange,
  });

  final BottomTab activeTab;
  final ValueChanged<BottomTab> onTabChange;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showActiveLabel = constraints.maxWidth >= 390;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xE01A1A1A), Color(0xE0121212)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.extraLarge),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _NavItem(
                        label: 'Home',
                        icon: Symbols.home,
                        isActive: activeTab == BottomTab.home,
                        showActiveLabel: showActiveLabel,
                        onTap: () => onTabChange(BottomTab.home),
                      ),
                      _NavItem(
                        label: 'History',
                        icon: Symbols.history,
                        isActive: activeTab == BottomTab.history,
                        showActiveLabel: showActiveLabel,
                        onTap: () => onTabChange(BottomTab.history),
                      ),
                      _NavItem(
                        label: 'Wishlist',
                        icon: Symbols.star,
                        isActive: activeTab == BottomTab.wishlist,
                        showActiveLabel: showActiveLabel,
                        onTap: () => onTabChange(BottomTab.wishlist),
                      ),
                      _NavItem(
                        label: 'Profile',
                        icon: Symbols.person,
                        isActive: activeTab == BottomTab.profile,
                        showActiveLabel: showActiveLabel,
                        onTap: () => onTabChange(BottomTab.profile),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.showActiveLabel,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final bool showActiveLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primary;
    final inactiveColor = AppColors.textTertiary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(
              color: isActive
                  ? activeColor.withValues(alpha: 0.45)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? activeColor : inactiveColor,
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: isActive && showActiveLabel
                    ? Padding(
                        key: const ValueKey('active-label'),
                        padding: const EdgeInsets.only(left: 6),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 56),
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.navLabel.copyWith(
                              color: activeColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('inactive-label')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
