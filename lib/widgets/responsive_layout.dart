import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'sidebar_layout.dart';
import 'bottom_nav_bar.dart';

/// Responsive layout that switches between sidebar (desktop) and bottom nav (mobile)
class ResponsiveLayout extends StatelessWidget {
  final String title;
  final Widget mobileBody;
  final Widget? desktopBody;
  final List<SidebarItem> sidebarItems;
  final List<MobileNavItem> mobileNavItems;
  final int currentNavIndex;
  final ValueChanged<int> onNavTap;
  final VoidCallback onFabTap;
  final IconData fabIcon;
  final String fabLabel;
  final List<Widget>? headerActions;
  final double breakpoint;

  const ResponsiveLayout({
    super.key,
    required this.title,
    required this.mobileBody,
    this.desktopBody,
    required this.sidebarItems,
    required this.mobileNavItems,
    required this.currentNavIndex,
    required this.onNavTap,
    required this.onFabTap,
    this.fabIcon = Icons.add,
    this.fabLabel = 'Add',
    this.headerActions,
    this.breakpoint = 768,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < breakpoint;
        
        if (isMobile) {
          return _buildMobileLayout();
        } else {
          return _buildDesktopLayout();
        }
      },
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: mobileBody),
      bottomNavigationBar: MobileBottomNavBar(
        currentIndex: currentNavIndex,
        onTap: onNavTap,
        onFabTap: onFabTap,
        items: mobileNavItems,
        fabIcon: fabIcon,
        fabLabel: fabLabel,
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return SidebarLayout(
      title: title,
      body: desktopBody ?? mobileBody,
      items: sidebarItems,
      headerActions: headerActions,
    );
  }
}
