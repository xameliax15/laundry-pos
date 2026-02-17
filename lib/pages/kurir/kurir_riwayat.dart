import 'package:flutter/material.dart';
import '../../models/transaksi.dart';
import '../../core/routes.dart';
import '../../core/logger.dart';
import '../../services/transaksi_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/sidebar_layout.dart';
import '../../widgets/bottom_nav_bar.dart';

class KurirRiwayat extends StatefulWidget {
  const KurirRiwayat({super.key});

  @override
  State<KurirRiwayat> createState() => _KurirRiwayatState();
}

class _KurirRiwayatState extends State<KurirRiwayat> {
  bool isLoading = true;
  List<Transaksi> riwayatTransaksi = [];
  
  // Search and filter
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _filterStatus;
  bool _isFiltered = false;

  // Service
  final TransaksiService _transaksiService = TransaksiService();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // _loadData moved to didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isFiltered && _filterStatus == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args == 'active') {
        _filterStatus = 'aktif'; // Orders: pesanan yang sedang diproses (dikirim)
        _isFiltered = true;
      } else if (args == 'history') {
        _filterStatus = 'history'; // History: pesanan selesai (diterima)
        _isFiltered = true;
      }
      _loadData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (!mounted) return;
    setState(() {
      _searchQuery = _searchController.text;
    });
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
    });

    try {
      // Get current user (kurir)
      final currentUser = AuthService().getCurrentUser();
      if (currentUser == null) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
        return;
      }

      List<Transaksi> transaksiList = [];

      if (_searchQuery.isNotEmpty) {
        // Search by customer name
        final searchResults = await _transaksiService.searchTransaksi(_searchQuery);
        transaksiList = searchResults.where((t) => 
          t.status == 'diterima' || t.status == 'dikirim' || t.status == 'selesai'
        ).toList();
      } else if (_isFiltered && _filterStatus != null) {
         if (_filterStatus == 'aktif') {
           // Orders: pesanan yang sedang diproses (status 'dikirim')
           final dikirim = await _transaksiService.getTransaksiByStatus('dikirim');
           transaksiList = dikirim;
         } else if (_filterStatus == 'history') {
           // History: pesanan yang sudah selesai (status 'diterima' - sudah dikirim dan dibayar)
           final diterima = await _transaksiService.getTransaksiByStatus('diterima');
           transaksiList = diterima;
         } else {
           transaksiList = await _transaksiService.getTransaksiByStatus(_filterStatus!);
         }
      } else {
        // Default: semua riwayat
        final diterima = await _transaksiService.getTransaksiByStatus('diterima');
        final dikirim = await _transaksiService.getTransaksiByStatus('dikirim');
        transaksiList = [...dikirim, ...diterima];
      }

      // Sort by tanggal (newest first)
      transaksiList.sort((a, b) => b.tanggalMasuk.compareTo(a.tanggalMasuk));

      if (!mounted) return;
      setState(() {
        riwayatTransaksi = transaksiList;
        isLoading = false;
      });
    } catch (e) {
      logger.e('Error loading riwayat transaksi', error: e);
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 768) {
          return _buildMobileLayout();
        } else {
          return _buildDesktopLayout();
        }
      },
    );
  }

  Widget _buildDesktopLayout() {
    return SidebarLayout(
      title: 'Riwayat Pengiriman',
      headerActions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilterDialog,
          tooltip: 'Filter',
        ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {},
          tooltip: 'Cari',
        ),
      ],
      items: [
        SidebarItem(
          label: 'Dashboard',
          icon: Icons.dashboard_rounded,
          onTap: () => Navigator.of(context)
              .pushReplacementNamed(AppRoutes.kurirDashboard),
        ),
        SidebarItem(
          label: 'Riwayat',
          icon: Icons.history,
          isActive: true,
          onTap: () {},
        ),
        SidebarItem(
          label: 'Keluar',
          icon: Icons.logout,
          isDestructive: true,
          onTap: () => AppRoutes.logout(context),
        ),
      ],
      body: _buildContent(),
    );
  }

  Widget _buildMobileLayout() {
    // Determine title and currentIndex based on filter status
    final isOrdersPage = _filterStatus == 'aktif';
    final isHistoryPage = _filterStatus == 'history';
    final pageTitle = isOrdersPage 
        ? 'Pesanan Aktif' 
        : (isHistoryPage ? 'Riwayat Selesai' : 'Riwayat Pengiriman');
    final currentNavIndex = isOrdersPage ? 1 : (isHistoryPage ? 2 : 2);

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: _buildContent(),
      bottomNavigationBar: MobileBottomNavBar(
        currentIndex: currentNavIndex,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.kurirDashboard, (route) => false);
          } else if (index == 1) {
            // Orders - Active deliveries
            Navigator.of(context).pushReplacementNamed(AppRoutes.kurirOrders);
          } else if (index == 2) {
            // History - Already on this page, do nothing if already here
            if (!isHistoryPage) {
              Navigator.of(context).pushReplacementNamed(AppRoutes.kurirRiwayat);
            }
          }
        },
        items: const [
          MobileNavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
          MobileNavItem(icon: Icons.local_shipping_outlined, activeIcon: Icons.local_shipping, label: 'Orders'),
          MobileNavItem(icon: Icons.history_outlined, activeIcon: Icons.history, label: 'History'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    _buildSearchBar(),
                    const SizedBox(height: 16),

                    // Filter Info
                    if (_isFiltered) _buildFilterInfo(),

                    // Stats Cards
                    _buildStatsCards(),
                    const SizedBox(height: 20),

                    // Section Title
                    _buildSectionTitle('📋 Riwayat Pengiriman'),
                    const SizedBox(height: 12),

                    // Transaction List
                    _buildRiwayatTransaksi(),
                  ],
                ),
              ),
            );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Cari berdasarkan nama pelanggan...',
                border: InputBorder.none,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 20),
              onPressed: () {
                _searchController.clear();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.brandBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_alt, size: 16, color: AppColors.brandBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Filter aktif: Status - ${_formatStatus(_filterStatus ?? '')}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.brandBlue,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _filterStatus = null;
                _isFiltered = false;
              });
              _loadData();
            },
            child: const Text('Hapus Filter'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final dikirimCount = riwayatTransaksi.where((t) => t.status == 'dikirim').length;
    final diterimaCount = riwayatTransaksi.where((t) => t.status == 'diterima').length;
    final selesaiCount = riwayatTransaksi.where((t) => t.status == 'selesai').length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Dikirim', dikirimCount, Icons.local_shipping, Colors.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Diterima', diterimaCount, Icons.check_circle, Colors.green),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Selesai', selesaiCount, Icons.done_all, Colors.purple),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildRiwayatTransaksi() {
    if (riwayatTransaksi.isEmpty) {
      return _buildEmptyState('Belum ada riwayat pengiriman');
    }

    return Column(
      children: riwayatTransaksi.map((transaksi) {
        return _buildRiwayatTransaksiCard(transaksi);
      }).toList(),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: AppColors.gray400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.gray600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiwayatTransaksiCard(Transaksi transaksi) {
    Color statusColor = _getStatusColor(transaksi.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Nama Customer & Status
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            transaksi.customerPhone,
                            style: TextStyle(
                              fontSize: 13,
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
                    color: statusColor.withValues(alpha: 0.1),
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

            // Order ID
            Row(
              children: [
                Icon(Icons.confirmation_number, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  'Order ID: ${transaksi.id.substring(0, 8).toUpperCase()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Tanggal Masuk
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  'Tanggal: ${_formatDateTime(transaksi.tanggalMasuk)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            if (transaksi.tanggalSelesai != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 14, color: Colors.green[600]),
                  const SizedBox(width: 6),
                  Text(
                    'Selesai: ${_formatDateTime(transaksi.tanggalSelesai!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ],
            
            // Delivery indicator
            if (transaksi.isDelivery) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_shipping, size: 14, color: Colors.orange[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Pengiriman',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Divider(height: 24),

            // Total Harga
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.brandBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Harga:',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    'Rp ${_formatCurrency(transaksi.totalHarga)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandBlue,
                    ),
                  ),
                ],
              ),
            ),

            // Catatan jika ada
            if (transaksi.catatan != null && transaksi.catatan!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.amber[800]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        transaksi.catatan!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber[900],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Semua'),
              leading: Radio<String?>(
                value: null,
                groupValue: _filterStatus,
                onChanged: (value) {
                  Navigator.pop(context);
                  setState(() {
                    _filterStatus = value;
                    _isFiltered = value != null;
                  });
                  _loadData();
                },
              ),
            ),
            ListTile(
              title: const Text('Dikirim'),
              leading: Radio<String?>(
                value: 'dikirim',
                groupValue: _filterStatus,
                onChanged: (value) {
                  Navigator.pop(context);
                  setState(() {
                    _filterStatus = value;
                    _isFiltered = true;
                  });
                  _loadData();
                },
              ),
            ),
            ListTile(
              title: const Text('Diterima'),
              leading: Radio<String?>(
                value: 'diterima',
                groupValue: _filterStatus,
                onChanged: (value) {
                  Navigator.pop(context);
                  setState(() {
                    _filterStatus = value;
                    _isFiltered = true;
                  });
                  _loadData();
                },
              ),
            ),
            ListTile(
              title: const Text('Selesai'),
              leading: Radio<String?>(
                value: 'selesai',
                groupValue: _filterStatus,
                onChanged: (value) {
                  Navigator.pop(context);
                  setState(() {
                    _filterStatus = value;
                    _isFiltered = true;
                  });
                  _loadData();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'dikirim':
        return 'Dikirim';
      case 'diterima':
        return 'Diterima';
      case 'selesai':
        return 'Selesai';
      default:
        return status.toUpperCase();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'dikirim':
        return Colors.blue;
      case 'diterima':
        return Colors.green;
      case 'selesai':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
