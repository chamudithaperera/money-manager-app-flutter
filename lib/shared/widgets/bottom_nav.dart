import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/theme.dart';

enum BottomTab { home, history, wallets, wishlist, profile }

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
                        onTap: () => onTabChange(BottomTab.home),
                      ),
                      _NavItem(
                        label: 'History',
                        icon: Symbols.history,
                        isActive: activeTab == BottomTab.history,
                        onTap: () => onTabChange(BottomTab.history),
                      ),
                      _NavItem(
                        label: 'Wallets',
                        icon: Symbols.account_balance_wallet,
                        isActive: activeTab == BottomTab.wallets,
                        onTap: () => onTabChange(BottomTab.wallets),
                      ),
                      _NavItem(
                        label: 'Wishlist',
                        icon: Symbols.star,
                        isActive: activeTab == BottomTab.wishlist,
                        onTap: () => onTabChange(BottomTab.wishlist),
                      ),
                      _NavItem(
                        label: 'Profile',
                        icon: Symbols.person,
                        isActive: activeTab == BottomTab.profile,
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
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
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
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isActive ? activeColor : inactiveColor,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.navLabel.copyWith(
                      color: isActive ? activeColor : inactiveColor,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
