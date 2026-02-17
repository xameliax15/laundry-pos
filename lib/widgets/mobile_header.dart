import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Mobile header widget with avatar, greeting, notification, and logout
class MobileHeader extends StatelessWidget {
  final String userName;
  final String? avatarUrl;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onLogoutTap;

  const MobileHeader({
    super.key,
    required this.userName,
    this.avatarUrl,
    this.onNotificationTap,
    this.onAvatarTap,
    this.onLogoutTap,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: onAvatarTap,
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.brandBlue.withAlpha(30),
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              child: avatarUrl == null
                  ? Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandBlue,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          
          // Greeting & Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting()},',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
          
          // Notification Bell
          IconButton(
            onPressed: onNotificationTap,
            icon: Stack(
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.text,
                  size: 26,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.accentOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Logout Button
          IconButton(
            onPressed: onLogoutTap,
            tooltip: 'Logout',
            icon: const Icon(
              Icons.logout,
              color: AppColors.error,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
