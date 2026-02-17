import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/transaksi.dart';
import '../../core/routes.dart';
import '../../core/logger.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class KurirOrders extends StatefulWidget {
  const KurirOrders({super.key});

  @override
  State<KurirOrders> createState() => _KurirOrdersState();
}

class _KurirOrdersState extends State<KurirOrders> {
  String _selectedTab = 'all'; // 'all', 'selesai', 'dikirim'
  
  List<Transaksi> _filterOrders(List<Transaksi> transaksi) {
    // Filter hanya order yang aktif untuk kurir (selesai & dikirim, NOT diterima)
    final activeOrders = transaksi.where((t) => 
      t.status == 'selesai' || t.status == 'dikirim'
    ).toList();

    // Apply tab filter
    if (_selectedTab == 'selesai') {
      return activeOrders.where((t) => t.status == 'selesai').toList();
    } else if (_selectedTab == 'dikirim') {
      return activeOrders.where((t) => t.status == 'dikirim').toList();
    }
    
    return activeOrders;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransaksiProvider>(
      builder: (context, provider, child) {
        final filteredOrders = _filterOrders(provider.transaksi);
        
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Active Deliveries'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => provider.refresh(),
                tooltip: 'Refresh',
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: Colors.white,
                child: Row(
                  children: [
                    _buildTabButton('Semua', 'all', filteredOrders.length),
                    _buildTabButton('Selesai', 'selesai', 
                      provider.transaksi.where((t) => t.status == 'selesai').length),
                    _buildTabButton('Dikirim', 'dikirim',
                      provider.transaksi.where((t) => t.status == 'dikirim').length),
                  ],
                ),
              ),
            ),
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async => provider.refresh(),
                  child: filteredOrders.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredOrders.length,
                          itemBuilder: (context, index) {
                            final transaksi = filteredOrders[index];
                            return _buildOrderCard(context, transaksi, provider);
                          },
                        ),
                ),
          bottomNavigationBar: MobileBottomNavBar(
            currentIndex: 1, // Orders tab
            onTap: (index) {
              if (index == 0) {
                Navigator.of(context).pushReplacementNamed(AppRoutes.kurirDashboard);
              } else if (index == 2) {
                Navigator.of(context).pushReplacementNamed(AppRoutes.kurirRiwayat);
              }
            },
            items: const [
              MobileNavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
              MobileNavItem(icon: Icons.local_shipping_outlined, activeIcon: Icons.local_shipping, label: 'Orders'),
              MobileNavItem(icon: Icons.history_outlined, activeIcon: Icons.history, label: 'History'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabButton(String label, String value, int count) {
    final isActive = _selectedTab == value;
    
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTab = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppColors.brandBlue : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isActive ? AppColors.brandBlue : AppColors.textMuted,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive 
                      ? AppColors.brandBlue.withAlpha(30)
                      : AppColors.border.withAlpha(100),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isActive ? AppColors.brandBlue : AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Transaksi transaksi, TransaksiProvider provider) {
    final statusColor = _getStatusColor(transaksi.status);
    final isSelesai = transaksi.status == 'selesai';
    final nextStatus = isSelesai ? 'dikirim' : 'diterima';
    final actionLabel = isSelesai ? 'Mulai Pengiriman' : 'Diterima';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaksi.customerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            transaksi.customerPhone,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatStatus(transaksi.status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Order ID & Date
            Row(
              children: [
                Icon(Icons.confirmation_number, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  transaksi.id.substring(0, 8).toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatDate(transaksi.tanggalMasuk),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            
            // Address if delivery (Note: address needs to be loaded from customer/order_kurir table)
            // For now, we'll just show delivery indicator
            if (transaksi.isDelivery) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.local_shipping, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Pengiriman',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),

            // Total
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.brandBlue.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Rp ${_formatCurrency(transaksi.totalHarga)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Action Buttons Row
            Row(
              children: [
                // Call Button
                SizedBox(
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed: () => _launchCall(transaksi.customerPhone),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Call', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      side: BorderSide(color: AppColors.brandBlue),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Maps Button (disabled for now - need to load address from order_kurir)
                if (transaksi.isDelivery)
                  Tooltip(
                    message: 'Alamat belum dimuat',
                    child: SizedBox(
                      height: 36,
                      child: OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.map, size: 16),
                        label: const Text('Maps', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                  ),
                const Spacer(),
                // Update Status Button
                SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: () => _showUpdateStatusDialog(context, transaksi, provider, nextStatus, actionLabel),
                    icon: Icon(isSelesai ? Icons.local_shipping : Icons.check, size: 16),
                    label: Text(actionLabel, style: const TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelesai ? AppColors.brandBlue : AppColors.accentGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchCall(String phone) async {
    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showUpdateStatusDialog(BuildContext context, Transaksi transaksi, TransaksiProvider provider, String newStatus, String statusText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: Text(
          'Ubah status order "${transaksi.customerName}" menjadi "$statusText"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                await provider.updateTransaksiStatus(transaksi.id, newStatus);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Status berhasil diupdate ke $statusText'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                logger.e('Error updating status', error: e);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal update status: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 64,
            color: AppColors.gray400,
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada pengiriman aktif',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pesanan siap kirim akan muncul di sini',
            style: TextStyle(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return 'Hari ini';
    } else if (diff.inDays == 1) {
      return 'Kemarin';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'selesai':
        return 'Selesai';
      case 'dikirim':
        return 'Dikirim';
      case 'diterima':
        return 'Diterima';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'selesai':
        return AppColors.accentGreen;
      case 'dikirim':
        return AppColors.brandBlue;
      case 'diterima':
        return AppColors.success;
      default:
        return AppColors.gray400;
    }
  }
}
