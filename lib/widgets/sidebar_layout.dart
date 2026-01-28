import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../theme/app_colors.dart';

class SidebarItem {
  const SidebarItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.isDestructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final bool isDestructive;
}

class SidebarLayout extends StatelessWidget {
  const SidebarLayout({
    super.key,
    required this.title,
    required this.body,
    required this.items,
    this.headerActions,
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final List<SidebarItem> items;
  final List<Widget>? headerActions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        if (isWide) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Row(
              children: [
                SizedBox(
                  width: 260,
                  child: _buildSidebar(context, isDrawer: false),
                ),
                Expanded(
                  child: Column(
                    children: [
                      _buildTopBar(context, isDrawer: false),
                      Expanded(child: body),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: floatingActionButton,
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.text,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            actions: headerActions,
          ),
          drawer: Drawer(child: _buildSidebar(context, isDrawer: true)),
          body: body,
          floatingActionButton: floatingActionButton,
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context, {required bool isDrawer}) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),
            if (headerActions != null) ...headerActions!,
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, {required bool isDrawer}) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.deepBlue,
        border: Border(
          right: BorderSide(color: AppColors.border),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                children: [
                  SizedBox(
                    height: 60,
                    child: Image.asset(
                      'assets/images/trias_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.local_laundry_service,
                          size: 40,
                          color: AppColors.brandBlue,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppConstants.appName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: items.map((item) {
                  final activeColor = item.isDestructive
                      ? const Color(0xFFE24A4A)
                      : AppColors.brandBlue;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Material(
                      color: item.isActive
                          ? Color.fromARGB(
                              24,
                              activeColor.red,
                              activeColor.green,
                              activeColor.blue,
                            )
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: ListTile(
                        dense: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        leading: Icon(
                          item.icon,
                          color: item.isActive ? activeColor : Colors.white,
                        ),
                        title: Text(
                          item.label,
                          style: TextStyle(
                            fontWeight:
                                item.isActive ? FontWeight.w700 : FontWeight.w600,
                            color: item.isActive ? activeColor : Colors.white,
                          ),
                        ),
                        onTap: () {
                          if (isDrawer) {
                            Navigator.of(context).pop();
                          }
                          item.onTap();
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
