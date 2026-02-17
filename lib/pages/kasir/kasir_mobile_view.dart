import 'package:flutter/material.dart';
import '../../models/transaksi.dart';
import '../../services/transaksi_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/mobile_header.dart';
import '../../widgets/stats_card.dart';
import '../../widgets/quick_action_button.dart';
import '../../widgets/order_list_item.dart';

/// Mobile view for Kasir Dashboard
class KasirMobileView extends StatelessWidget {
  final String userName;
  final int pendingCount;
  final int prosesCount;
  final int selesaiCount;
  final double todayRevenue;
  final int todayTransactions;
  final List<Transaksi> pendingPayments;
  final List<Transaksi> readyForPickup;
  final VoidCallback onNewOrder;
  final VoidCallback onPayment;
  final VoidCallback onFindCustomer;
  final VoidCallback? onViewAllPending;
  final VoidCallback? onViewAllReady;
  final Function(Transaksi)? onProcessPayment;
  final Function(Transaksi) onTapOrder;
  final Function(Transaksi) onPrintStruk;
  final VoidCallback? onRefresh;
  final VoidCallback? onLogout;
  
  // Search properties
  final Function(String)? onSearchChanged;
  final VoidCallback? onFilterTap;
  final bool isSearching;
  final List<dynamic> searchResults;

  const KasirMobileView({
    super.key,
    required this.userName,
    required this.pendingCount,
    required this.prosesCount,
    required this.selesaiCount,
    required this.todayRevenue,
    required this.todayTransactions,
    required this.pendingPayments,
    required this.readyForPickup,
    required this.onNewOrder,
    required this.onPayment,
    required this.onFindCustomer,
    this.onViewAllPending,
    this.onViewAllReady,
    this.onProcessPayment,
    required this.onTapOrder,
    required this.onPrintStruk,
    this.onRefresh,
    this.onLogout,
    this.onSearchChanged,
    this.onFilterTap,
    this.isSearching = false,
    this.searchResults = const [],
  });

  String _formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return 'Rp $formatted';
  }

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
            
            // Search Bar & Filter
            Padding(
               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
               child: Row(
                 children: [
                   Expanded(
                     child: TextField(
                       decoration: InputDecoration(
                         hintText: 'Cari transaksi...',
                         prefixIcon: const Icon(Icons.search),
                         filled: true,
                         fillColor: Colors.white,
                         contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                         border: OutlineInputBorder(
                           borderRadius: BorderRadius.circular(12),
                           borderSide: BorderSide.none,
                         ),
                         enabledBorder: OutlineInputBorder(
                           borderRadius: BorderRadius.circular(12),
                           borderSide: BorderSide(color: AppColors.border),
                         ),
                       ),
                       onChanged: onSearchChanged,
                     ),
                   ),
                   const SizedBox(width: 8),
                   Container(
                     height: 48,
                     width: 48,
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(12),
                       border: Border.all(color: AppColors.border),
                     ),
                     child: IconButton(
                       icon: const Icon(Icons.filter_list),
                       color: AppColors.brandBlue,
                       onPressed: onFilterTap,
                       tooltip: 'Filter',
                     ),
                   ),
                 ],
               ),
            ),
            
            // Search Results Mode
            if (isSearching) ...[
               _buildSectionHeader('Search Results', null),
               if (searchResults.isEmpty)
                 const Padding(
                   padding: EdgeInsets.all(20),
                   child: Center(child: Text("Tidak ada data ditemukan")),
                 )
               else
                 ...searchResults.map((trx) {
                    return OrderListItem(
                      orderId: trx.id.length > 8 ? trx.id.substring(0, 8) : trx.id,
                      customerName: trx.customerName,
                      description: _getDescription(trx),
                      status: trx.status,
                      statusColor: _getStatusColor(trx.status),
                      onTap: () => onTapOrder(trx),
                      trailing: IconButton(
                        icon: const Icon(Icons.print, size: 20),
                        color: AppColors.brandBlue,
                        onPressed: () => onPrintStruk(trx),
                      ),
                    );
                 }).toList(),
            ] else ...[
            
            // Stats Card
            StatsCard(
              title: "Today's Collections",
              amount: _formatCurrency(todayRevenue),
              subtitle: 'Transactions',
              subtitleValue: todayTransactions.toString(),
              icon: Icons.account_balance_wallet,
              onViewReport: onViewAllPending,
            ),
            
            const SizedBox(height: 16),
            
            // Quick Actions
            QuickActionsGrid(
              actions: [
                QuickActionButton(
                  icon: Icons.shopping_cart,
                  label: 'New Order',
                  onTap: onNewOrder,
                ),
                QuickActionButton(
                  icon: Icons.payment,
                  label: 'Payment',
                  onTap: onPayment,
                  backgroundColor: AppColors.accentGreen.withAlpha(30),
                  iconColor: AppColors.accentGreen,
                ),
                QuickActionButton(
                  icon: Icons.person_search,
                  label: 'Find User',
                  onTap: onFindCustomer,
                  backgroundColor: AppColors.accentPurple.withAlpha(30),
                  iconColor: AppColors.accentPurple,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Pending Payments
            if (pendingPayments.isNotEmpty) ...[
              _buildSectionHeader('Pending Payments', onViewAllPending),
              const SizedBox(height: 8),
              SizedBox(
                height: 185,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: pendingPayments.length,
                  itemBuilder: (context, index) {
                    final trx = pendingPayments[index];
                    return PendingPaymentCard(
                      orderId: trx.id.length > 8 ? trx.id.substring(0, 8) : trx.id,
                      customerName: trx.customerName,
                      dueInfo: 'Due Today',
                      amount: _formatCurrency(trx.totalHarga),
                      onProcessPayment: () { if (onProcessPayment != null) onProcessPayment!(trx); },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Ready for Pickup
            OrderSection(
              title: 'Ready for Pickup',
              onSeeAll: onViewAllReady,
              children: readyForPickup.take(5).map((trx) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OrderListItem(
                    orderId: trx.id.length > 8 ? trx.id.substring(0, 8) : trx.id,
                    customerName: trx.customerName,
                    description: _getDescription(trx),
                    status: trx.status,
                    statusColor: _getStatusColor(trx.status),
                    onTap: () => onTapOrder(trx),
                    trailing: IconButton(
                      icon: const Icon(Icons.print, size: 20),
                      color: AppColors.brandBlue,
                      onPressed: () => onPrintStruk(trx),
                      tooltip: 'Print Struk',
                    ),
                  ),
                );
              }).toList(),
            ),
            
            // Empty state if no orders
            if (readyForPickup.isEmpty && pendingPayments.isEmpty)
              _buildEmptyState(),
            
            const SizedBox(height: 100), // Space for bottom nav
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback? onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: Text(
                'See All',
                style: TextStyle(
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getDescription(Transaksi trx) {
    // Simple description based on transaction
    return trx.isDelivery ? 'Delivery' : 'Pickup';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'proses':
        return AppColors.brandBlue;
      case 'selesai':
        return AppColors.accentGreen;
      case 'dikirim':
        return AppColors.accentPurple;
      case 'diterima':
        return AppColors.success;
      default:
        return AppColors.gray400;
    }
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
            Icons.inbox_outlined,
            size: 64,
            color: AppColors.gray400,
          ),
          const SizedBox(height: 16),
          Text(
            'No orders yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create a new order',
            style: TextStyle(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
