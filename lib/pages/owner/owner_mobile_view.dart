import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/mobile_header.dart';
import '../../widgets/stats_card.dart';
import '../../widgets/quick_action_button.dart';
import '../../widgets/order_list_item.dart';

/// Mobile view for Owner Dashboard
class OwnerMobileView extends StatelessWidget {
  final String userName;
  final double totalOmzet;
  final double pendapatanHariIni;
  final int totalTransaksi;
  final int transaksiCODCount;
  final List<Map<String, dynamic>> grafikPendapatan; // New param
  final List<Map<String, dynamic>> transaksiCOD;
  final VoidCallback onViewReport;
  final VoidCallback onManageUsers;
  final VoidCallback onVerifyPayments;
  final VoidCallback onSettings;
  final VoidCallback onSeeAllCOD;
  final Function(Map<String, dynamic>) onVerifyCOD;
  final VoidCallback onDeleteHistory;
  final VoidCallback? onRefresh;
  final VoidCallback? onLogout;

  final int currentIndex;
  final Function(int) onTabChanged;

  const OwnerMobileView({
    super.key,
    required this.userName,
    required this.totalOmzet,
    required this.pendapatanHariIni,
    required this.totalTransaksi,
    required this.transaksiCODCount,
    required this.grafikPendapatan,
    required this.transaksiCOD,
    required this.onViewReport,
    required this.onManageUsers,
    required this.onVerifyPayments,
    required this.onSettings,
    required this.onSeeAllCOD,
    required this.onVerifyCOD,
    required this.onDeleteHistory,
    this.currentIndex = 0,
    required this.onTabChanged,
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
            
            // Stats Card - Total Omzet
            StatsCard(
              title: 'Total Omzet',
              amount: _formatCurrency(totalOmzet),
              subtitle: 'Total Transaksi',
              subtitleValue: totalTransaksi.toString(),
              icon: Icons.trending_up,
              onViewReport: onViewReport,
            ),
            
            const SizedBox(height: 16),
            
            // Quick Actions
            QuickActionsGrid(
              crossAxisCount: 4,
              actions: [
                QuickActionButton(
                  icon: Icons.assessment,
                  label: 'Reports',
                  onTap: onViewReport,
                ),
                QuickActionButton(
                  icon: Icons.people,
                  label: 'Users',
                  onTap: onManageUsers,
                  backgroundColor: AppColors.accentPurple.withAlpha(30),
                  iconColor: AppColors.accentPurple,
                ),
                QuickActionButton(
                  icon: Icons.verified,
                  label: 'Verify',
                  onTap: onVerifyPayments,
                  backgroundColor: AppColors.accentGreen.withAlpha(30),
                  iconColor: AppColors.accentGreen,
                ),
                QuickActionButton(
                  icon: Icons.delete_sweep,
                  label: 'Hapus History',
                  onTap: onDeleteHistory,
                  backgroundColor: AppColors.error.withAlpha(30),
                  iconColor: AppColors.error,
                ),
              ],
            ),
            
            const SizedBox(height: 24),

            // Revenue Chart
            if (grafikPendapatan.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     const Text(
                      'Pendapatan 7 Hari Terakhir',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 150,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: grafikPendapatan.map((data) {
                          final value = (data['pendapatan'] as num).toDouble();
                          final maxValue = grafikPendapatan.map((e) => (e['pendapatan'] as num).toDouble()).reduce((a, b) => a > b ? a : b);
                          final heightFactor = maxValue > 0 ? value / maxValue : 0.0;
                          
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                width: 24,
                                height: 100 * heightFactor + 10, // Min height 10
                                decoration: BoxDecoration(
                                  color: AppColors.brandBlue,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                data['hari']?.toString() ?? '',
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Pendapatan Hari Ini - Additional Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.today,
                        color: AppColors.accentGreen,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pendapatan Hari Ini',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatCurrency(pendapatanHariIni),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // COD Transactions to Verify
            if (transaksiCOD.isNotEmpty)
              OrderSection(
                title: 'Verifikasi COD',
                onSeeAll: onSeeAllCOD,
                children: transaksiCOD.take(5).map((trx) {
                  final customerName = trx['customer_name'] ?? 'Unknown';
                  final orderId = trx['id']?.toString() ?? '';
                  final amount = (trx['total_harga'] as num?)?.toDouble() ?? 0;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.warning.withAlpha(30),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.pending_actions,
                              color: AppColors.warning,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text,
                                  ),
                                ),
                                Text(
                                  '#${orderId.length > 8 ? orderId.substring(0, 8) : orderId}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatCurrency(amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text,
                                ),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => onVerifyCOD(trx),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentGreen,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Verify',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            
            // Empty state if no COD
            if (transaksiCOD.isEmpty)
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
            Icons.check_circle_outline,
            size: 64,
            color: AppColors.accentGreen,
          ),
          const SizedBox(height: 16),
          Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No pending COD verifications',
            style: TextStyle(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
