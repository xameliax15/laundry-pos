import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/transaksi.dart';
import '../../core/routes.dart';
import '../../core/logger.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bottom_nav_bar.dart';

class KasirOrders extends StatefulWidget {
  const KasirOrders({super.key});

  @override
  State<KasirOrders> createState() => _KasirOrdersState();
}

class _KasirOrdersState extends State<KasirOrders> {
  String _selectedTab = 'all'; // 'all', 'pending', 'proses'

  @override
  void initState() {
    super.initState();
  }

  List<Transaksi> _filterOrders(List<Transaksi> transaksi) {
    // Filter hanya order yang aktif (pending & proses)
    final activeOrders = transaksi.where((t) => 
      t.status == 'pending' || t.status == 'proses'
    ).toList();

    // Apply tab filter
    if (_selectedTab == 'pending') {
      return activeOrders.where((t) => t.status == 'pending').toList();
    } else if (_selectedTab == 'proses') {
      return activeOrders.where((t) => t.status == 'proses').toList();
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
            title: const Text('Orders'),
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
                    _buildTabButton('Pending', 'pending', 
                      provider.transaksi.where((t) => t.status == 'pending').length),
                    _buildTabButton('Proses', 'proses',
                      provider.transaksi.where((t) => t.status == 'proses').length),
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
                Navigator.of(context).pushReplacementNamed(AppRoutes.kasirDashboard);
              } else if (index == 2) {
                Navigator.of(context).pushReplacementNamed(AppRoutes.kasirPelanggan);
              } else if (index == 3) {
                Navigator.of(context).pushReplacementNamed(AppRoutes.kasirRiwayat);
              }
            },
            onFabTap: () {
              // Terima Laundry action - navigate to dashboard
              Navigator.of(context).pushReplacementNamed(AppRoutes.kasirDashboard);
            },
            fabIcon: Icons.add,
            items: const [
              MobileNavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
              MobileNavItem(icon: Icons.shopping_bag_outlined, activeIcon: Icons.shopping_bag, label: 'Orders'),
              MobileNavItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Customers'),
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
    final isPending = transaksi.status == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showOrderDetail(context, transaksi, provider),
        borderRadius: BorderRadius.circular(12),
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

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showUpdateStatusDialog(context, transaksi, provider),
                  icon: Icon(isPending ? Icons.play_arrow : Icons.check),
                  label: Text(isPending ? 'Mulai Proses' : 'Selesaikan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPending ? AppColors.brandBlue : AppColors.accentGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDetail(BuildContext context, Transaksi transaksi, TransaksiProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(transaksi.customerName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Order ID', transaksi.id.substring(0, 8).toUpperCase()),
              _buildDetailRow('Telepon', transaksi.customerPhone),
              _buildDetailRow('Status', _formatStatus(transaksi.status)),
              _buildDetailRow('Total', 'Rp ${_formatCurrency(transaksi.totalHarga)}'),
              _buildDetailRow('Tanggal', _formatDate(transaksi.tanggalMasuk)),
              if (transaksi.isDelivery) 
                _buildDetailRow('Pengiriman', 'Ya'),
              if (transaksi.catatan != null && transaksi.catatan!.isNotEmpty)
                _buildDetailRow('Catatan', transaksi.catatan!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showUpdateStatusDialog(context, transaksi, provider);
            },
            child: const Text('Update Status'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateStatusDialog(BuildContext context, Transaksi transaksi, TransaksiProvider provider) {
    final isPending = transaksi.status == 'pending';
    final newStatus = isPending ? 'proses' : 'selesai';
    final statusText = isPending ? 'Proses' : 'Selesai';

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
                // Update status via provider
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
            Icons.shopping_bag_outlined,
            size: 64,
            color: AppColors.gray400,
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada order',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Order yang perlu diproses akan muncul di sini',
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
      case 'pending':
        return 'Pending';
      case 'proses':
        return 'Proses';
      case 'selesai':
        return 'Selesai';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'proses':
        return AppColors.brandBlue;
      case 'selesai':
        return AppColors.accentGreen;
      default:
        return AppColors.gray400;
    }
  }
}
