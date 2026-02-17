import 'package:flutter/material.dart';
import '../../models/order_kurir.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/mobile_header.dart';
import '../../widgets/stats_card.dart';
import '../../widgets/quick_action_button.dart';
import 'package:url_launcher/url_launcher.dart'; // Add url_launcher
import '../../widgets/order_list_item.dart';

/// Mobile view for Kurir Dashboard
class KurirMobileView extends StatelessWidget {
  final String userName;
  final int activeOrders;
  final int completedOrders;
  final int pendingCOD;
  final List<dynamic> orders;
  final VoidCallback onHistory;
  final VoidCallback onReceivePayment;
  final VoidCallback onSettings;
  final VoidCallback onSeeAllOrders;
  final Function(dynamic) onTapOrder;
  final Function(dynamic) onUpdateStatus;
  final VoidCallback? onRefresh;
  final VoidCallback? onLogout;

  const KurirMobileView({
    super.key,
    required this.userName,
    required this.activeOrders,
    required this.completedOrders,
    required this.pendingCOD,
    required this.orders,
    required this.onHistory,
    required this.onReceivePayment,
    required this.onSettings,
    required this.onSeeAllOrders,
    required this.onTapOrder,
    required this.onUpdateStatus,
    this.onRefresh,
    this.onLogout,
  });

  String _formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return 'Rp $formatted';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'dikirim':
        return AppColors.brandBlue;
      case 'diterima':
        return AppColors.accentGreen;
      default:
        return AppColors.warning;
    }
  }

  Future<void> _launchMaps(String address) async {
    final query = Uri.encodeComponent(address);
    final googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    }
  }

  Future<void> _launchCall(String phone) async {
    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh?.call(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            MobileHeader(
              userName: userName,
              onNotificationTap: () => NotificationService.showNotificationsDialog(context),
              onLogoutTap: onLogout,
            ),
            
            // Stats Card
            StatsCard(
              title: 'Active Deliveries',
              amount: activeOrders.toString(),
              subtitle: 'Completed Today',
              subtitleValue: completedOrders.toString(),
              icon: Icons.local_shipping,
              onViewReport: onHistory,
            ),
            
            const SizedBox(height: 16),
            
            // Quick Actions
            QuickActionsGrid(
              actions: [
                QuickActionButton(
                  icon: Icons.payments,
                  label: 'COD ($pendingCOD)',
                  onTap: onReceivePayment,
                  backgroundColor: AppColors.accentGreen.withAlpha(30),
                  iconColor: AppColors.accentGreen,
                ),
                QuickActionButton(
                  icon: Icons.history,
                  label: 'History',
                  onTap: onHistory,
                ),
                QuickActionButton(
                  icon: Icons.settings,
                  label: 'Settings',
                  onTap: onSettings,
                  backgroundColor: AppColors.gray400.withAlpha(30),
                  iconColor: AppColors.gray400,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Active Orders
            OrderSection(
              title: 'Active Deliveries',
              onSeeAll: onSeeAllOrders,
              children: orders.take(10).map((order) {
                final customerName = order is Map 
                    ? (order['customer_name'] ?? 'Unknown')
                    : 'Unknown';
                final orderId = order is Map 
                    ? (order['id']?.toString() ?? '')
                    : '';
                final status = order is Map 
                    ? (order['status']?.toString() ?? 'pending')
                    : 'pending';
                final address = order is Map 
                    ? (order['alamat_pengiriman'] ?? 'No address')
                    : 'No address';
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: InkWell(
                      onTap: () => onTapOrder(order),
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.brandBlue.withAlpha(30),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.local_shipping,
                                  color: AppColors.brandBlue,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '#${orderId.length > 8 ? orderId.substring(0, 8) : orderId}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.text,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(status).withAlpha(30),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            status.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: _getStatusColor(status),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      customerName,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: AppColors.brandBlue,
                                ),
                                onPressed: () => onUpdateStatus(orderId),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  address,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Action Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                                // Call Button
                                if (order is Map && order['customer_phone'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: SizedBox(
                                      height: 36,
                                      child: OutlinedButton.icon(
                                        onPressed: () => _launchCall(order['customer_phone']),
                                        icon: const Icon(Icons.phone, size: 18),
                                        label: const Text('Call'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          side: BorderSide(color: AppColors.brandBlue),
                                        ),
                                      ),
                                    ),
                                  ),
                                // Map Button
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: SizedBox(
                                    height: 36,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _launchMaps(address),
                                      icon: const Icon(Icons.map, size: 18),
                                      label: const Text('Maps'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        side: BorderSide(color: AppColors.brandBlue),
                                      ),
                                    ),
                                  ),
                                ),
                                // Update Status Button (Primary)
                                SizedBox(
                                  height: 36,
                                  child: ElevatedButton.icon(
                                    onPressed: () => onUpdateStatus(order),
                                    icon: const Icon(Icons.check, size: 18),
                                    label: const Text('Done'),
                                    style: ElevatedButton.styleFrom(
                                       padding: const EdgeInsets.symmetric(horizontal: 12),
                                       backgroundColor: AppColors.accentGreen,
                                       foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            // Empty state
            if (orders.isEmpty)
              _buildEmptyState(),
            
            const SizedBox(height: 100), // Space for bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 64,
            color: AppColors.gray400,
          ),
          const SizedBox(height: 16),
          Text(
            'No active deliveries',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new orders',
            style: TextStyle(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
