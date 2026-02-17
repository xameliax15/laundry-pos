import 'package:flutter/material.dart';
import 'dart:io';
import '../../models/transaksi.dart';
import '../../models/pembayaran.dart';
import '../../models/detail_laundry.dart';
import '../../core/routes.dart';
import '../../core/logger.dart';
import '../../services/transaksi_service.dart';
import '../../services/print_service.dart';
import '../../services/status_log_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/sidebar_layout.dart';
import '../../models/user.dart' as app_user;
import '../owner/user_management_page.dart';

class KasirRiwayat extends StatefulWidget {
  final bool isEmbedded;
  final String? userRole;
  
  const KasirRiwayat({super.key, this.isEmbedded = false, this.userRole});

  @override
  State<KasirRiwayat> createState() => _KasirRiwayatState();
}

class _KasirRiwayatState extends State<KasirRiwayat> {
  bool isLoading = true;
  List<Transaksi> riwayatTransaksi = [];
  Map<String, List<DetailLaundry>> detailLaundryMap = {};
  
  // Search and filter
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _filterStatus;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  bool _isFiltered = false;

  // Service
  final TransaksiService _transaksiService = TransaksiService();

  @override
  void initState() {
    super.initState();
    // Move _loadData to didChangeDependencies to read arguments
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Check arguments only once
    if (!_isFiltered && _filterStatus == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is String) {
        if (args == 'active') {
          _filterStatus = 'active'; // Ongoing orders: pending, proses, selesai, dikirim
          _isFiltered = true;
        } else if (args == 'history') {
          _filterStatus = 'history'; // Completed orders only: diterima
          _isFiltered = true;
        } else if (['pending', 'proses', 'selesai', 'dikirim', 'diterima'].contains(args)) {
          _filterStatus = args;
          _isFiltered = true;
        }
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
    setState(() {
      _searchQuery = _searchController.text;
    });
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      List<Transaksi> transaksiList = [];

      if (_searchQuery.isNotEmpty) {
        // Jika ada search query, gunakan search
        final searchResults = await _transaksiService.searchTransaksi(_searchQuery);
        if (_isFiltered) {
          // Apply filter ke search results
          transaksiList = searchResults.where((t) {
            if (_filterStatus != null && t.status != _filterStatus) return false;
            if (_filterStartDate != null && t.tanggalMasuk.isBefore(_filterStartDate!)) return false;
            if (_filterEndDate != null) {
              final endDate = DateTime(_filterEndDate!.year, _filterEndDate!.month, _filterEndDate!.day, 23, 59, 59);
              if (t.tanggalMasuk.isAfter(endDate)) return false;
            }
            return true;
          }).toList();
        } else {
          transaksiList = searchResults;
        }
      } else if (_isFiltered) {
        // Jika hanya filter tanpa search
        if (_filterStatus == 'active') {
           // Active/Ongoing orders: pending, proses, selesai, dikirim (NOT diterima)
           final all = await _transaksiService.getAllTransaksi();
           transaksiList = all.where((t) => ['pending', 'proses', 'selesai', 'dikirim'].contains(t.status)).toList();
           
           // Apply date filter if exists
           if (_filterStartDate != null || _filterEndDate != null) {
              transaksiList = transaksiList.where((t) {
                if (_filterStartDate != null && t.tanggalMasuk.isBefore(_filterStartDate!)) return false;
                if (_filterEndDate != null) {
                  final endDate = DateTime(_filterEndDate!.year, _filterEndDate!.month, _filterEndDate!.day, 23, 59, 59);
                   if (t.tanggalMasuk.isAfter(endDate)) return false;
                }
                return true;
              }).toList();
           }
        } else if (_filterStatus == 'history') {
           // History/Completed orders: only 'diterima' status
           final all = await _transaksiService.getAllTransaksi();
           transaksiList = all.where((t) => t.status == 'diterima').toList();
           
           // Apply date filter if exists
           if (_filterStartDate != null || _filterEndDate != null) {
              transaksiList = transaksiList.where((t) {
                if (_filterStartDate != null && t.tanggalMasuk.isBefore(_filterStartDate!)) return false;
                if (_filterEndDate != null) {
                  final endDate = DateTime(_filterEndDate!.year, _filterEndDate!.month, _filterEndDate!.day, 23, 59, 59);
                   if (t.tanggalMasuk.isAfter(endDate)) return false;
                }
                return true;
              }).toList();
           }
        } else {
          transaksiList = await _transaksiService.filterTransaksi(
            status: _filterStatus,
            startDate: _filterStartDate,
            endDate: _filterEndDate,
          );
        }
      } else {
        // Load semua transaksi (bukan hanya hari ini)
        transaksiList = await _transaksiService.getAllTransaksi();
      }

      // Sort by tanggal masuk (terbaru dulu)
      transaksiList.sort((a, b) => b.tanggalMasuk.compareTo(a.tanggalMasuk));

      // Load detail laundry untuk semua transaksi
      final detailMap = <String, List<DetailLaundry>>{};
      for (var transaksi in transaksiList) {
        final details = await _transaksiService.getDetailLaundryByTransaksiId(transaksi.id);
        detailMap[transaksi.id] = details;
      }

      setState(() {
        riwayatTransaksi = transaksiList;
        detailLaundryMap = detailMap;
        isLoading = false;
      });
    } catch (e) {
      logger.e('Error loading riwayat transaksi', error: e);
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If embedded in another page, return just the content
    if (widget.isEmbedded) {
      return _buildEmbeddedLayout();
    }
    
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

  Widget _buildEmbeddedLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pesanan'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: _buildContent(),
    );
  }


  Widget _buildDesktopLayout() {
    // Determine if this is being used by owner or kasir
    final isOwner = widget.userRole == 'owner';
    
    return SidebarLayout(
      title: 'Riwayat Transaksi',
      headerActions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilterDialog,
          tooltip: 'Filter',
        ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _showSearchDialog,
          tooltip: 'Pencarian',
        ),
      ],
      items: isOwner ? [
        // Owner sidebar items
        SidebarItem(
          label: 'Dashboard',
          icon: Icons.dashboard_rounded,
          onTap: () => Navigator.of(context)
              .pushReplacementNamed(AppRoutes.ownerDashboard),
        ),
        SidebarItem(
          label: 'Manajemen User',
          icon: Icons.people,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UserManagementPage(),
              ),
            );
          },
        ),
        SidebarItem(
          label: 'Riwayat Pesanan',
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
      ] : [
        // Kasir sidebar items
        SidebarItem(
          label: 'Dashboard',
          icon: Icons.dashboard_rounded,
          onTap: () => Navigator.of(context)
              .pushReplacementNamed(AppRoutes.kasirDashboard),
        ),
        SidebarItem(
          label: 'Riwayat Transaksi',
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
    final isOrdersPage = _filterStatus == 'active';
    final isHistoryPage = _filterStatus == 'history';
    final pageTitle = isOrdersPage 
        ? 'Pesanan Berlangsung' 
        : (isHistoryPage ? 'Riwayat Selesai' : 'Riwayat Transaksi');
    final currentNavIndex = isOrdersPage ? 1 : (isHistoryPage ? 3 : 3);

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
        automaticallyImplyLeading: false, // Remove back button for consistency
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: _buildContent(),
      bottomNavigationBar: MobileBottomNavBar(
        currentIndex: currentNavIndex,
        onTap: (index) {
          if (index == 0) {
            // Home - Dashboard
            Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.kasirDashboard, (route) => false);
          } else if (index == 1) {
            // Orders - Navigate to Orders page
            Navigator.of(context).pushReplacementNamed(AppRoutes.kasirOrders);
          } else if (index == 2) {
            // Customers
            Navigator.of(context).pushReplacementNamed(AppRoutes.kasirPelanggan);
          } else if (index == 3) {
            // History - Completed
            if (!isHistoryPage) {
              Navigator.of(context).pushReplacementNamed(
                  AppRoutes.kasirRiwayat, arguments: 'history');
            }
          }
        },
        onFabTap: () => Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.kasirDashboard, (route) => false),
        items: const [
          MobileNavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
          MobileNavItem(icon: Icons.shopping_bag_outlined, activeIcon: Icons.shopping_bag, label: 'Orders'),
          MobileNavItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Customers'),
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

                    // Riwayat Transaksi
                    _buildSectionTitle('📋 Riwayat Transaksi'),
                    const SizedBox(height: 12),
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
                hintText: 'Cari transaksi...',
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
        color: AppColors.brandBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_alt, size: 16, color: AppColors.brandBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Filter aktif: ${_getFilterText()}',
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
                _filterStartDate = null;
                _filterEndDate = null;
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

  String _getFilterText() {
    final parts = <String>[];
    if (_filterStatus != null) {
      parts.add('Status: ${_formatStatus(_filterStatus!)}');
    }
    if (_filterStartDate != null) {
      parts.add('Dari: ${_formatDate(_filterStartDate!)}');
    }
    if (_filterEndDate != null) {
      parts.add('Sampai: ${_formatDate(_filterEndDate!)}');
    }
    return parts.join(', ');
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
      return _buildEmptyState('Belum ada riwayat transaksi');
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
    final detailLaundry = detailLaundryMap[transaksi.id] ?? [];
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
                    color: statusColor.withOpacity(0.1),
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
            
            // Tanggal Masuk
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  'Tanggal Masuk: ${_formatDateTime(transaksi.tanggalMasuk)}',
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
            const Divider(height: 24),
            
            // Detail Laundry
            if (detailLaundry.isNotEmpty) ...[
              Text(
                'Detail Laundry:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              ...detailLaundry.map((detail) => _buildRiwayatDetailLaundryItem(detail)),
              const SizedBox(height: 12),
            ],
            
            // Foto Transaksi (jika ada)
            if (detailLaundry.any((d) => d.foto != null && d.foto!.isNotEmpty)) ...[
              Text(
                'Foto Transaksi:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              _buildFotoTransaksi(detailLaundry),
              const SizedBox(height: 12),
            ],
            
            const Divider(height: 24),
            
            // Informasi Pembayaran
            FutureBuilder<List<Pembayaran>>(
              future: _transaksiService.getPembayaranByTransaksiId(transaksi.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 40,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                
                final pembayaranListRaw = snapshot.data ?? [];
                // Filter unique by ID (Fix Duplicate Display)
                final seenIds = <String>{};
                final pembayaranList = pembayaranListRaw.where((p) => seenIds.add(p.id)).toList();
                final totalPembayaran = pembayaranList
                    .where((p) => p.status == 'lunas')
                    .fold<double>(0.0, (sum, p) => sum + p.jumlah);
                final isLunas = totalPembayaran >= transaksi.totalHarga;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi Pembayaran:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (pembayaranList.isNotEmpty) ...[
                      ...pembayaranList.map((pembayaran) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                              _getPaymentIcon(pembayaran.metodePembayaran),
                              size: 16,
                              color: _getPaymentColor(pembayaran.metodePembayaran),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${_formatPaymentMethod(pembayaran.metodePembayaran)} - Rp ${_formatCurrency(pembayaran.jumlah)}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: pembayaran.status == 'lunas'
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                pembayaran.status == 'lunas' ? 'Lunas' : 'Pending',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: pembayaran.status == 'lunas'
                                      ? Colors.green[700]
                                      : Colors.orange[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                      const SizedBox(height: 8),
                    ] else ...[
                      Text(
                        'Belum ada pembayaran',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isLunas ? Icons.check_circle : Icons.pending,
                              size: 18,
                              color: isLunas ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isLunas ? 'Lunas' : 'Belum Lunas',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isLunas ? Colors.green[700] : Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                        if (!isLunas && totalPembayaran > 0)
                          Text(
                            'Sisa: Rp ${_formatCurrency(transaksi.totalHarga - totalPembayaran)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
            
            const Divider(height: 24),
            
            // Total Harga
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.brandBlue.withOpacity(0.1),
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
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
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
            
            const SizedBox(height: 16),
            const Divider(),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showStatusLogDialog(transaksi.id),
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('Status Log'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => PrintService.showPrintDialog(context, transaksi),
                  icon: const Icon(Icons.print, size: 18),
                  label: const Text('Cetak Struk'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiwayatDetailLaundryItem(DetailLaundry detail) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.brandBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getServiceIcon(detail.jenisLayanan),
              size: 20,
              color: AppColors.brandBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatServiceType(detail.jenisLayanan),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Jenis: ${detail.jenisBarang}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
                if (detail.jumlah > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Jumlah: ${detail.jumlah}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
                if (detail.berat != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Berat: ${detail.berat} kg',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
                if (detail.ukuran != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Ukuran: ${detail.ukuran}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
                if (detail.catatan != null && detail.catatan!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Catatan: ${detail.catatan}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFotoTransaksi(List<DetailLaundry> detailLaundry) {
    final fotoList = detailLaundry
        .where((d) => d.foto != null && d.foto!.isNotEmpty)
        .map((d) => d.foto!)
        .toList();
    
    if (fotoList.isEmpty) return const SizedBox.shrink();
    
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: fotoList.length,
        itemBuilder: (context, index) {
          final fotoPath = fotoList[index];
          return Container(
            margin: const EdgeInsets.only(right: 8),
            width: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildImageWidget(fotoPath),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showStatusLogDialog(String transaksiId) async {
    final statusLogService = StatusLogService();
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final logs = await statusLogService.getStatusHistory(transaksiId);
      
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Riwayat Status'),
          content: SizedBox(
            width: double.maxFinite,
            child: logs.isEmpty
                ? const Center(child: Text('Belum ada riwayat status'))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return ListTile(
                        leading: const Icon(Icons.history, color: AppColors.brandBlue),
                        title: Text(_formatStatus(log.newStatus)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dari: ${_formatStatus(log.oldStatus)}'),
                            Text('Oleh: ${log.changedByName ?? "Unknown"}'),
                            Text(
                              _formatDateTime(log.changedAt),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            if (log.notes != null && log.notes!.isNotEmpty)
                              Text(
                                'Catatan: ${log.notes}',
                                style: const TextStyle(fontStyle: FontStyle.italic),
                              ),
                          ],
                        ),
                        isThreeLine: true,
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context); // Dismiss loading
      logger.e('Error showing status logs', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat riwayat: $e')),
        );
      }
    }
  }
  Widget _buildImageWidget(String imagePath) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      // URL dari Supabase
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      );
    } else {
      // Local file path
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    }
  }

  IconData _getServiceIcon(String jenisLayanan) {
    switch (jenisLayanan) {
      case 'laundry_kiloan':
        return Icons.local_laundry_service;
      case 'sepatu':
        return Icons.sports_soccer;
      case 'jaket':
        return Icons.checkroom;
      case 'helm':
        return Icons.sports_motorsports;
      case 'karpet':
        return Icons.carpenter;
      case 'tas':
        return Icons.shopping_bag;
      case 'boneka':
        return Icons.toys;
      default:
        return Icons.cleaning_services;
    }
  }

  String _formatServiceType(String jenisLayanan) {
    switch (jenisLayanan) {
      case 'laundry_kiloan':
        return 'Laundry Kiloan';
      case 'sepatu':
        return 'Cuci Sepatu';
      case 'jaket':
        return 'Cuci Jaket';
      case 'helm':
        return 'Cuci Helm';
      case 'karpet':
        return 'Cuci Karpet';
      case 'tas':
        return 'Cuci Tas';
      case 'boneka':
        return 'Cuci Boneka';
      default:
        return jenisLayanan;
    }
  }

  IconData _getPaymentIcon(String metode) {
    switch (metode.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'transfer':
        return Icons.account_balance;
      case 'qris':
        return Icons.qr_code;
      case 'cod':
        return Icons.local_shipping;
      default:
        return Icons.payment;
    }
  }

  Color _getPaymentColor(String metode) {
    switch (metode.toLowerCase()) {
      case 'cash':
        return Colors.green;
      case 'transfer':
        return Colors.blue;
      case 'qris':
        return Colors.purple;
      case 'cod':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatPaymentMethod(String metode) {
    switch (metode.toLowerCase()) {
      case 'cash':
        return 'Tunai';
      case 'transfer':
        return 'Transfer';
      case 'qris':
        return 'QRIS';
      case 'cod':
        return 'COD (Cash on Delivery)';
      default:
        return metode;
    }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'proses':
        return 'Proses';
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
      case 'pending':
        return Colors.orange;
      case 'proses':
        return Colors.blue;
      case 'selesai':
        return Colors.green;
      case 'dikirim':
        return Colors.purple;
      case 'diterima':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pencarian Transaksi'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Cari (Nama Customer, No. Telepon, atau ID Transaksi)',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() async {
    String? selectedStatus = _filterStatus;
    DateTime? startDate = _filterStartDate;
    DateTime? endDate = _filterEndDate;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Transaksi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Filter Status
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Semua Status')),
                    const DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    const DropdownMenuItem(value: 'proses', child: Text('Proses')),
                    const DropdownMenuItem(value: 'selesai', child: Text('Selesai')),
                    const DropdownMenuItem(value: 'dikirim', child: Text('Dikirim')),
                    const DropdownMenuItem(value: 'diterima', child: Text('Diterima')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedStatus = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Filter Tanggal Mulai
                ListTile(
                  title: Text(startDate == null ? 'Tanggal Mulai' : 'Dari: ${_formatDate(startDate!)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setDialogState(() {
                        startDate = date;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                // Filter Tanggal Akhir
                ListTile(
                  title: Text(endDate == null ? 'Tanggal Akhir' : 'Sampai: ${_formatDate(endDate!)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: endDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setDialogState(() {
                        endDate = date;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _filterStatus = null;
                  _filterStartDate = null;
                  _filterEndDate = null;
                  _isFiltered = false;
                });
                Navigator.pop(context);
                _loadData();
              },
              child: const Text('Reset'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _filterStatus = selectedStatus;
                  _filterStartDate = startDate;
                  _filterEndDate = endDate;
                  _isFiltered = selectedStatus != null || startDate != null || endDate != null;
                });
                Navigator.pop(context);
                _loadData();
              },
              child: const Text('Terapkan'),
            ),
          ],
        ),
      ),
    );
  }
  void _showUpdateStatusDialog(Transaksi transaksi) async {
    // Tentukan status berikutnya yang valid
    List<String> nextStatuses = [];
    
    switch (transaksi.status) {
      case 'pending':
        nextStatuses = ['proses'];
        break;
      case 'proses':
        nextStatuses = ['selesai'];
        break;
      case 'selesai':
        if (!transaksi.isDelivery) {
          nextStatuses = ['diterima'];
        } else {
          nextStatuses = [];
        }
        break;
      case 'dikirim':
        nextStatuses = ['diterima'];
        break;
      default:
        nextStatuses = [];
    }

    if (nextStatuses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status tidak dapat diubah lagi'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String? selectedStatus;
    String? selectedKurirId;

    // Load kurir jika transaksi delivery akan diset ke selesai
    List<app_user.User> kurirList = [];
    if (transaksi.isDelivery &&
        (transaksi.status == 'proses' || transaksi.status == 'selesai')) {
      try {
        kurirList = await _transaksiService.getAvailableKurir();
      } catch (e) {
        print('Error loading kurir: $e');
      }
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Update Status Transaksi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transaksi: ${transaksi.id}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Status Saat Ini: ${_formatStatus(transaksi.status)}'),
                const SizedBox(height: 16),
                const Text(
                  'Pilih Status Baru:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...nextStatuses.map((status) => RadioListTile<String>(
                      title: Text(_formatStatus(status)),
                      value: status,
                      groupValue: selectedStatus,
                      onChanged: (value) {
                        setDialogState(() {
                          selectedStatus = value;
                        if (value != 'selesai') {
                          selectedKurirId = null;
                        }
                        });
                      },
                    )),
                // Pilih kurir jika status selesai dan delivery
                if (selectedStatus == 'selesai' && transaksi.isDelivery && kurirList.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Pilih Kurir:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedKurirId,
                    decoration: const InputDecoration(
                      labelText: 'Kurir',
                      border: OutlineInputBorder(),
                    ),
                    items: kurirList.map<DropdownMenuItem<String>>((kurir) {
                      return DropdownMenuItem<String>(
                        value: kurir.id,
                        child: Text('${kurir.username} (${kurir.phone ?? ''})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedKurirId = value;
                      });
                    },
                  ),
                ],
                if (selectedStatus == 'selesai' && transaksi.isDelivery && kurirList.isEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Tidak ada kurir yang tersedia',
                    style: TextStyle(color: Colors.orange[700], fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: selectedStatus == null ||
                      (selectedStatus == 'selesai' && transaksi.isDelivery && selectedKurirId == null)
                  ? null
                  : () async {
                      try {
                        await _transaksiService.updateStatusTransaksi(
                          transaksi.id,
                          selectedStatus!,
                          kurirId: selectedKurirId,
                          isDelivery: transaksi.isDelivery,
                        );

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Status berhasil diupdate menjadi ${_formatStatus(selectedStatus!)}',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );

                        // Reload data
                        _loadData(); // Function di KasirRiwayat state
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}
