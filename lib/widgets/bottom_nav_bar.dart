import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Bottom navigation bar with optional center FAB
class MobileBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onFabTap; // Now optional
  final List<MobileNavItem> items;
  final String fabLabel;
  final IconData? fabIcon; // Now optional

  const MobileBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onFabTap, // Optional
    required this.items,
    this.fabLabel = 'Add',
    this.fabIcon, // Optional
  });

  @override
  Widget build(BuildContext context) {
    final hasFab = onFabTap != null;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: hasFab
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Left items
                    ...items.take(items.length ~/ 2).map((item) => _buildNavItem(item)),
                    
                    // Center FAB
                    _buildFab(),
                    
                    // Right items
                    ...items.skip(items.length ~/ 2).map((item) => _buildNavItem(item)),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: items.map((item) => _buildNavItem(item)).toList(),
                ),
        ),
      ),
    );
  }

  Widget _buildNavItem(MobileNavItem item) {
    final isActive = items.indexOf(item) == currentIndex;
    return InkWell(
      onTap: () => onTap(items.indexOf(item)),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? item.activeIcon : item.icon,
              color: isActive ? AppColors.brandBlue : AppColors.gray400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? AppColors.brandBlue : AppColors.gray400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab() {
    return GestureDetector(
      onTap: onFabTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.brandBlue,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.brandBlue.withAlpha(100),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          fabIcon ?? Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

/// Navigation item for bottom nav
class MobileNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const MobileNavItem({
    required this.icon,
    required this.label,
    IconData? activeIcon,
  }) : activeIcon = activeIcon ?? icon;
}
