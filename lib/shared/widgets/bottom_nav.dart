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
        child: SizedBox(
          height: 106,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      height: 74,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xE61D1D1D), Color(0xE6121212)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.65),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.28),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _TabItem(
                              label: 'History',
                              icon: Symbols.history,
                              isActive: activeTab == BottomTab.history,
                              onTap: () => onTabChange(BottomTab.history),
                            ),
                          ),
                          Expanded(
                            child: _TabItem(
                              label: 'Wallets',
                              icon: Symbols.account_balance_wallet,
                              isActive: activeTab == BottomTab.wallets,
                              onTap: () => onTabChange(BottomTab.wallets),
                            ),
                          ),
                          const SizedBox(width: 86),
                          Expanded(
                            child: _TabItem(
                              label: 'Wishlist',
                              icon: Symbols.star,
                              isActive: activeTab == BottomTab.wishlist,
                              onTap: () => onTabChange(BottomTab.wishlist),
                            ),
                          ),
                          Expanded(
                            child: _TabItem(
                              label: 'Profile',
                              icon: Symbols.person,
                              isActive: activeTab == BottomTab.profile,
                              onTap: () => onTabChange(BottomTab.profile),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                child: _HomeCenterButton(
                  isActive: activeTab == BottomTab.home,
                  onTap: () => onTabChange(BottomTab.home),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeCenterButton extends StatelessWidget {
  const _HomeCenterButton({required this.isActive, required this.onTap});

  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(36),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 66,
        height: 66,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isActive
                ? [AppColors.primaryLight, AppColors.primary]
                : [AppColors.primary, AppColors.primaryDark],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(
                alpha: isActive ? 0.45 : 0.28,
              ),
              blurRadius: isActive ? 24 : 16,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(Symbols.home, size: 30, color: Colors.black),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
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
    final inactiveColor = AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: isActive ? activeColor : inactiveColor),
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
      ),
    );
  }
}
