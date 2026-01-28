import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import '../../models/transaksi.dart';
import '../../models/pembayaran.dart';
import '../../models/detail_laundry.dart';
import '../../models/user.dart' as app_user;
import '../../models/customer.dart';
import '../../core/logger.dart';
import '../../services/transaksi_service.dart';
import '../../services/customer_service.dart';
import '../../core/routes.dart';
import '../../core/price_list.dart';
import '../../core/constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../theme/app_colors.dart';
import '../../widgets/sidebar_layout.dart';

class KasirDashboard extends StatefulWidget {
  const KasirDashboard({super.key});

  @override
  State<KasirDashboard> createState() => _KasirDashboardState();
}

class _KasirDashboardState extends State<KasirDashboard> {
  // Data dari database
  int totalTransaksiHariIni = 0;
  double totalPendapatanHariIni = 0.0;
  bool isLoading = true;
  
  // Map untuk menyimpan detail laundry per transaksi
  Map<String, List<DetailLaundry>> detailLaundryMap = {};
  
  // Service
  final TransaksiService _transaksiService = TransaksiService();
  final CustomerService _customerService = CustomerService();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<Transaksi> daftarLaundryMasuk = [];
  List<Transaksi> riwayatTransaksiHariIni = [];
  
  // Search and filter
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _filterStatus;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  bool _isFiltered = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
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
      // Load statistics
      final totalTransaksi = await _transaksiService.getTotalTransaksiHariIni();
      final totalPendapatan = await _transaksiService.getTotalPendapatanHariIni();

      // Load transaksi dengan search dan filter
      List<Transaksi> laundryMasuk = [];
      List<Transaksi> transaksiHariIni = [];

      if (_searchQuery.isNotEmpty) {
        // Jika ada search query, gunakan search
        final searchResults = await _transaksiService.searchTransaksi(_searchQuery);
        if (_isFiltered) {
          // Apply filter ke search results
          laundryMasuk = searchResults.where((t) {
            if (_filterStatus != null && t.status != _filterStatus) return false;
            if (_filterStartDate != null && t.tanggalMasuk.isBefore(_filterStartDate!)) return false;
            if (_filterEndDate != null) {
              final endDate = DateTime(_filterEndDate!.year, _filterEndDate!.month, _filterEndDate!.day, 23, 59, 59);
              if (t.tanggalMasuk.isAfter(endDate)) return false;
            }
            return true;
          }).toList();
        } else {
          laundryMasuk = searchResults;
        }
        transaksiHariIni = searchResults;
      } else if (_isFiltered) {
        // Jika hanya filter tanpa search
        final filtered = await _transaksiService.filterTransaksi(
          status: _filterStatus,
          startDate: _filterStartDate,
          endDate: _filterEndDate,
        );
        laundryMasuk = filtered.where((t) => t.status == 'pending' || t.status == 'proses').toList();
        transaksiHariIni = filtered;
      } else {
        // Load normal (tanpa search/filter)
        final pending = await _transaksiService.getTransaksiByStatus('pending');
        final proses = await _transaksiService.getTransaksiByStatus('proses');
        laundryMasuk = [...pending, ...proses];
        transaksiHariIni = await _transaksiService.getTransaksiHariIni();
      }

      // Load detail laundry untuk semua transaksi
      final detailMap = <String, List<DetailLaundry>>{};
      for (var transaksi in laundryMasuk) {
        final details = await _transaksiService.getDetailLaundryByTransaksiId(transaksi.id);
        detailMap[transaksi.id] = details;
      }
      for (var transaksi in transaksiHariIni) {
        if (!detailMap.containsKey(transaksi.id)) {
          final details = await _transaksiService.getDetailLaundryByTransaksiId(transaksi.id);
          detailMap[transaksi.id] = details;
        }
      }

      setState(() {
        totalTransaksiHariIni = totalTransaksi;
        totalPendapatanHariIni = totalPendapatan;
        daftarLaundryMasuk = laundryMasuk;
        riwayatTransaksiHariIni = transaksiHariIni;
        detailLaundryMap = detailMap;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SidebarLayout(
      title: 'Dashboard Kasir',
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
      items: [
        SidebarItem(
          label: 'Dashboard',
          icon: Icons.dashboard_rounded,
          isActive: true,
          onTap: () => Navigator.of(context)
              .pushReplacementNamed(AppRoutes.kasirDashboard),
        ),
        SidebarItem(
          label: 'Riwayat Transaksi',
          icon: Icons.history,
          onTap: () => Navigator.of(context)
              .pushNamed(AppRoutes.kasirRiwayat),
        ),
        SidebarItem(
          label: 'Buat Transaksi',
          icon: Icons.add_circle_outline,
          onTap: _buatTransaksiBaru,
        ),
        SidebarItem(
          label: 'Keluar',
          icon: Icons.logout,
          isDestructive: true,
          onTap: () => AppRoutes.logout(context),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _buatTransaksiBaru,
        icon: const Icon(Icons.add),
        label: const Text('Buat Transaksi'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    // Search Bar
                    _buildSearchBar(),
                    const SizedBox(height: 16),

                    // Filter Info
                    if (_isFiltered) _buildFilterInfo(),

                    // Statistik Card
                    _buildStatistikCard(),
                    const SizedBox(height: 20),

                    // Tombol Utama
                    _buildTombolUtama(),
                    const SizedBox(height: 20),

                    // Daftar Laundry Masuk
                    _buildSectionTitle('📦 Daftar Laundry Masuk'),
                    const SizedBox(height: 12),
                    _buildDaftarLaundryMasuk(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatistikCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.brandBlue,
            AppColors.skyBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0x331E88D6),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Total Transaksi',
              totalTransaksiHariIni.toString(),
              Icons.receipt_long,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: const Color(0x4DFFFFFF),
          ),
          Expanded(
            child: _buildStatItem(
              'Total Pendapatan',
              'Rp ${_formatCurrency(totalPendapatanHariIni)}',
              Icons.account_balance_wallet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: const Color(0xE6FFFFFF),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTombolUtama() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTombol(
                'Terima Laundry',
                Icons.add_shopping_cart,
                AppColors.accentGreen,
                _terimaLaundry,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTombol(
                'Input Pembayaran',
                Icons.payment,
                AppColors.brandBlue,
                _inputPembayaran,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTombol(
                'Detail Isi Laundry',
                Icons.list_alt,
                AppColors.accentOrange,
                _detailIsiLaundry,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTombol(
                'Filter Pembayaran',
                Icons.filter_alt,
                AppColors.accentPurple,
                _showFilterPembayaranDialog,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTombol(
                'Cari Customer',
                Icons.person_search,
                AppColors.deepBlue,
                _showSearchCustomerDialog,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showSearchCustomerDialog() async {
    final searchController = TextEditingController();
    List<Customer> searchResults = [];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Pencarian Customer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  labelText: 'Cari (Nama atau No. Telepon)',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                onChanged: (value) async {
                  if (value.isNotEmpty) {
                    final results = await _customerService.searchCustomer(value);
                    setDialogState(() {
                      searchResults = results;
                    });
                  } else {
                    setDialogState(() {
                      searchResults = [];
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              if (searchResults.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final customer = searchResults[index];
                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(customer.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Phone: ${customer.phone}'),
                            if (customer.fullAddress.isNotEmpty)
                              Text(
                                'Alamat: ${customer.fullAddress}',
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          // Bisa ditambahkan aksi lain, misalnya buka detail customer
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Customer: ${customer.name} - ${customer.phone}'),
                            ),
                          );
                        },
                      );
                    },
                  ),
                )
              else if (searchController.text.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Tidak ada customer yang ditemukan'),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                searchController.clear();
                setDialogState(() {
                  searchResults = [];
                });
              },
              child: const Text('Hapus'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTombol(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Color.fromARGB(20, color.red, color.green, color.blue),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Color.fromARGB(60, color.red, color.green, color.blue),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.accentOrange,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.skyBlue, AppColors.brandBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332B7BB9),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ringkasan Kasir',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTanggal(now),
                  style: const TextStyle(
                    color: Color(0xEEFFFFFF),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x33FFFFFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.receipt_long,
              color: Colors.white,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTanggal(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildDaftarLaundryMasuk() {
    if (daftarLaundryMasuk.isEmpty) {
      return _buildEmptyState('Tidak ada laundry masuk');
    }

    return Column(
      children: daftarLaundryMasuk.map((transaksi) {
        return _buildTransaksiCard(transaksi, showActions: true);
      }).toList(),
    );
  }

  Widget _buildRiwayatTransaksi() {
    if (riwayatTransaksiHariIni.isEmpty) {
      return _buildEmptyState('Belum ada riwayat transaksi hari ini');
    }

    return Column(
      children: riwayatTransaksiHariIni.map((transaksi) {
        return _buildRiwayatTransaksiCard(transaksi);
      }).toList(),
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
                
                final pembayaranList = snapshot.data ?? [];
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

  Widget _buildTransaksiCard(Transaksi transaksi, {required bool showActions}) {
    Color statusColor = _getStatusColor(transaksi.status);
    
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
                      Text(
                        transaksi.customerPhone,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
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
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(transaksi.tanggalMasuk),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (transaksi.catatan != null) ...[
              const SizedBox(height: 8),
              Text(
                'Catatan: ${transaksi.catatan}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const Divider(height: 24),
            // Status Pembayaran
            FutureBuilder<double>(
              future: _transaksiService.getTotalPembayaranByTransaksiId(transaksi.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }
                final totalPembayaran = snapshot.data ?? 0.0;
                final sisaBayar = transaksi.totalHarga - totalPembayaran;
                final isLunas = totalPembayaran >= transaksi.totalHarga;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isLunas ? Icons.check_circle : Icons.pending,
                          size: 16,
                          color: isLunas ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isLunas ? 'Lunas' : 'Belum Lunas',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isLunas ? Colors.green : Colors.orange,
                          ),
                        ),
                        const Spacer(),
                        if (!isLunas)
                          Text(
                            'Sisa: Rp ${_formatCurrency(sisaBayar)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    if (!isLunas && totalPembayaran > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Sudah dibayar: Rp ${_formatCurrency(totalPembayaran)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: Rp ${_formatCurrency(transaksi.totalHarga)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                if (showActions)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tombol Update Status
                      if (transaksi.status == 'pending' || 
                          transaksi.status == 'proses' || 
                          (transaksi.status == 'selesai' && !transaksi.isDelivery))
                        IconButton(
                          icon: const Icon(Icons.update, color: Colors.blue),
                          onPressed: () => _showUpdateStatusDialog(transaksi),
                          tooltip: 'Update Status',
                        ),
                      IconButton(
                        icon: const Icon(Icons.list_alt, color: Colors.purple),
                        onPressed: () => _showDetailLaundry(transaksi),
                        tooltip: 'Detail Isi Laundry',
                      ),
                      FutureBuilder<bool>(
                        future: _transaksiService.isTransaksiLunas(transaksi.id),
                        builder: (context, snapshot) {
                          final isLunas = snapshot.data ?? false;
                          // Tampilkan tombol pembayaran jika belum lunas dan status selesai/diterima
                          if (!isLunas &&
                              (transaksi.status == 'pending' ||
                               transaksi.status == 'selesai' ||
                               transaksi.status == 'diterima')) {
                            return IconButton(
                              icon: const Icon(Icons.payment, color: Colors.blue),
                              onPressed: () => _pembayaranDiTempat(transaksi),
                              tooltip: 'Pembayaran',
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.receipt, color: Colors.orange),
                        onPressed: () => _cetakStruk(transaksi),
                        tooltip: 'Cetak/Lihat Struk',
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Action Methods
  void _buatTransaksiBaru() {
    logger.d('_buatTransaksiBaru called');
    _showFormTerimaLaundry();
  }

  void _terimaLaundry() {
    logger.d('_terimaLaundry called');
    _showFormTerimaLaundry();
  }

  void _showFormTerimaLaundry() {
    logger.d('_showFormTerimaLaundry called - showing form dialog');
    final customerNameController = TextEditingController();
    final customerPhoneController = TextEditingController();
    final alamatController = TextEditingController();
    final catatanController = TextEditingController();
    final hargaController = TextEditingController();
    bool isDelivery = false;
    
    List<Map<String, dynamic>> detailLaundryList = [];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Terima Laundry Baru',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Data Customer
                        const Text(
                          'Data Customer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: customerNameController,
                          decoration: InputDecoration(
                            labelText: 'Nama Customer',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: customerPhoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'No. Telepon',
                            prefixIcon: const Icon(Icons.phone),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Pilihan Delivery
                        CheckboxListTile(
                          title: const Text('Delivery (Pengiriman)'),
                          subtitle: const Text('Centang jika pesanan akan diantar ke alamat customer'),
                          value: isDelivery,
                          onChanged: (value) {
                            setDialogState(() {
                              isDelivery = value ?? false;
                              if (!isDelivery) {
                                alamatController.clear();
                              }
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (isDelivery) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: alamatController,
                            decoration: InputDecoration(
                              labelText: 'Alamat Pengiriman *',
                              prefixIcon: const Icon(Icons.location_on),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              hintText: 'Masukkan alamat lengkap untuk delivery',
                            ),
                            maxLines: 2,
                          ),
                        ],
                        const SizedBox(height: 20),
                        
                        // Detail Laundry
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Detail Isi Laundry',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                setDialogState(() {
                                  detailLaundryList.add({
                                    'jenisLayanan': 'laundry_kiloan',
                                    'jenisBarang': 'reguler',
                                    'jumlah': 1,
                                    'ukuran': null,
                                    'berat': 1.0, // minimum 1kg
                                    'luas': null,
                                    'catatan': '',
                                    'foto': null,
                                  });
                                });
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Tambah Item'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // List Detail Laundry
                        if (detailLaundryList.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'Belum ada item laundry.\nKlik "Tambah Item" untuk menambahkan.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        else
                          ...detailLaundryList.asMap().entries.map((entry) {
                            int index = entry.key;
                            Map<String, dynamic> item = entry.value;
                            return _buildDetailLaundryItem(
                              index,
                              item,
                              detailLaundryList,
                              setDialogState,
                              hargaController,
                            );
                          }),
                        
                        const SizedBox(height: 20),
                        
                        // Catatan & Harga
                        TextField(
                          controller: catatanController,
                          decoration: InputDecoration(
                            labelText: 'Catatan (Opsional)',
                            prefixIcon: const Icon(Icons.note),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: hargaController,
                                decoration: InputDecoration(
                                  labelText: 'Total Harga',
                                  prefixIcon: const Icon(Icons.attach_money),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                readOnly: true,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                // Hitung total harga otomatis berdasarkan price list
                                double total = 0;
                                for (var item in detailLaundryList) {
                                  final jenisLayanan = item['jenisLayanan'] ?? 'laundry_kiloan';
                                  final jenisBarang = item['jenisBarang'] ?? 'reguler';
                                  final jumlah = item['jumlah'] ?? 1;
                                  final ukuran = item['ukuran'];
                                  final berat = item['berat'] as double?;
                                  final luas = item['luas'] as double?;
                                  
                                  final hargaPerItem = PriceList.getHarga(
                                    jenisLayanan: jenisLayanan,
                                    jenisBarang: jenisBarang,
                                    ukuran: ukuran,
                                    berat: berat,
                                    luas: luas,
                                  );
                                  
                                  total += hargaPerItem * jumlah;
                                }
                                hargaController.text = total.toStringAsFixed(0);
                                setDialogState(() {});
                              },
                              icon: const Icon(Icons.calculate, size: 18),
                              label: const Text('Hitung'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '*Klik "Hitung" untuk menghitung total harga otomatis berdasarkan jenis dan jumlah',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Footer Buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Batal'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            // Validasi
                            if (customerNameController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Mohon isi nama customer'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            if (customerPhoneController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Mohon isi nomor telepon customer'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            if (detailLaundryList.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Mohon tambahkan minimal 1 item laundry'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            if (hargaController.text.trim().isEmpty || double.tryParse(hargaController.text.trim()) == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Mohon hitung total harga terlebih dahulu'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            // Generate ID transaksi dengan format: TRX-YYYYMMDD-HHMMSS-XXX
                            final now = DateTime.now();
                            final transaksiId = 'TRX-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(7)}';
                            
                            final totalHarga = double.tryParse(hargaController.text.trim()) ?? 0;
                            
                            if (totalHarga <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Total harga harus lebih dari 0'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            // Validasi alamat jika delivery
                            if (isDelivery && alamatController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Mohon isi alamat pengiriman untuk delivery'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            final newTransaksi = Transaksi(
                              id: transaksiId,
                              customerName: customerNameController.text.trim(),
                              customerPhone: customerPhoneController.text.trim(),
                              tanggalMasuk: now,
                              status: 'pending',
                              totalHarga: totalHarga,
                              catatan: catatanController.text.trim().isEmpty
                                  ? null
                                  : catatanController.text.trim(),
                              isDelivery: isDelivery,
                            );

                            // Simpan detail laundry
                            final detailLaundryListToSave = detailLaundryList.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              return DetailLaundry(
                                id: '${transaksiId}_${index}',
                                idTransaksi: transaksiId,
                                jenisLayanan: item['jenisLayanan'] ?? 'laundry_kiloan',
                                jenisBarang: item['jenisBarang'] ?? 'reguler',
                                jumlah: item['jumlah'] ?? 1,
                                ukuran: item['ukuran'],
                                berat: item['berat'] != null ? (item['berat'] as num).toDouble() : null,
                                luas: item['luas'] != null ? (item['luas'] as num).toDouble() : null,
                                catatan: item['catatan']?.toString().trim().isEmpty ?? true
                                    ? null
                                    : item['catatan']?.toString().trim(),
                                foto: item['foto']?.toString(),
                              );
                            }).toList();

                            // Simpan via service ke database dengan alamat
                            await _transaksiService.createTransaksiWithDetail(
                              newTransaksi,
                              detailLaundryListToSave,
                              alamat: alamatController.text.trim().isEmpty
                                  ? null
                                  : alamatController.text.trim(),
                            );

                            Navigator.pop(context);
                            
                            // Reload data dari database
                            await _loadData();
                            
                            // Show success dialog dengan detail
                            _showSuccessDialog(newTransaksi, detailLaundryListToSave);
                          } catch (e) {
                            print('Error saving transaction: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error menyimpan transaksi: $e'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Simpan'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailLaundryItem(
    int index,
    Map<String, dynamic> item,
    List<Map<String, dynamic>> list,
    StateSetter setDialogState,
    TextEditingController hargaController,
  ) {
    final jenisLayanan = item['jenisLayanan'] ?? 'laundry_kiloan';
    final jumlahController = TextEditingController(text: item['jumlah'].toString());
    final beratController = TextEditingController(text: item['berat']?.toString() ?? '2.0');
    final luasController = TextEditingController(text: item['luas']?.toString() ?? '');
    final catatanController = TextEditingController(text: item['catatan'] ?? '');

    void updateHarga() {
      if (hargaController.text.isNotEmpty) {
        double total = 0;
        for (var item in list) {
          final jenisLayanan = item['jenisLayanan'] ?? 'laundry_kiloan';
          final jenisBarang = item['jenisBarang'] ?? 'reguler';
          final jumlah = item['jumlah'] ?? 1;
          final ukuran = item['ukuran'];
          final berat = item['berat'] != null ? (item['berat'] as num).toDouble() : null;
          final luas = item['luas'] != null ? (item['luas'] as num).toDouble() : null;
          
          final hargaPerItem = PriceList.getHarga(
            jenisLayanan: jenisLayanan,
            jenisBarang: jenisBarang,
            ukuran: ukuran,
            berat: berat,
            luas: luas,
          );
          
          total += hargaPerItem * jumlah;
        }
        hargaController.text = total.toStringAsFixed(0);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Item ${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () {
                  setDialogState(() {
                    list.removeAt(index);
                    updateHarga();
                  });
                },
                tooltip: 'Hapus Item',
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Jenis Layanan
          DropdownButtonFormField<String>(
            value: jenisLayanan,
            decoration: InputDecoration(
              labelText: 'Jenis Layanan',
              prefixIcon: const Icon(Icons.local_laundry_service),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            items: PriceList.getJenisLayanan().map((layanan) {
              String label = layanan.replaceAll('_', ' ').toUpperCase();
              return DropdownMenuItem(
                value: layanan,
                child: Text(label),
              );
            }).toList(),
            onChanged: (value) {
              setDialogState(() {
                item['jenisLayanan'] = value;
                // Reset field sesuai jenis layanan
                if (value == 'laundry_kiloan') {
                  item['jenisBarang'] = 'reguler';
                  item['berat'] = 2.0;
                  item['ukuran'] = null;
                  item['luas'] = null;
                } else if (value == 'sepatu') {
                  item['jenisBarang'] = 'sneakers';
                  item['berat'] = null;
                  item['ukuran'] = null;
                  item['luas'] = null;
                } else if (value == 'jaket') {
                  item['jenisBarang'] = 'kulit';
                  item['berat'] = null;
                  item['ukuran'] = null;
                  item['luas'] = null;
                } else if (value == 'helm') {
                  item['jenisBarang'] = 'helm';
                  item['berat'] = null;
                  item['ukuran'] = null;
                  item['luas'] = null;
                } else if (value == 'karpet') {
                  item['jenisBarang'] = 'standar';
                  item['luas'] = 1.0;
                  item['berat'] = null;
                  item['ukuran'] = null;
                } else if (value == 'tas') {
                  item['jenisBarang'] = 'tas';
                  item['ukuran'] = 'kecil';
                  item['berat'] = null;
                  item['luas'] = null;
                } else if (value == 'boneka') {
                  item['jenisBarang'] = 'boneka';
                  item['ukuran'] = 'kecil';
                  item['berat'] = null;
                  item['luas'] = null;
                } else {
                  item['ukuran'] = null;
                  item['berat'] = null;
                  item['luas'] = null;
                }
                updateHarga();
              });
            },
          ),
          const SizedBox(height: 8),
          
          // Opsi sesuai jenis layanan
          if (jenisLayanan == 'laundry_kiloan') ...[
            // Opsi Laundry Kiloan
            DropdownButtonFormField<String>(
              value: item['jenisBarang'] ?? 'reguler',
              decoration: InputDecoration(
                labelText: 'Pilihan Laundry',
                prefixIcon: const Icon(Icons.wash),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: PriceList.getOpsiLaundryKiloan().map((opsi) {
                return DropdownMenuItem<String>(
                  value: opsi['value'] as String,
                  child: Text('${opsi['label']} - Rp ${(opsi['harga'] as double).toStringAsFixed(0)}/kg'),
                );
              }).toList(),
              onChanged: (value) {
                setDialogState(() {
                  item['jenisBarang'] = value;
                  updateHarga();
                });
              },
            ),
            const SizedBox(height: 8),
            // Berat (kg)
            TextField(
              controller: beratController,
              decoration: InputDecoration(
                labelText: 'Berat (kg) - Min ${PriceList.minKiloan}kg',
                prefixIcon: const Icon(Icons.scale),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
                helperText: 'Gunakan titik (.) untuk desimal, contoh: 2.5 atau 3.75',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                setDialogState(() {
                  if (value.isNotEmpty) {
                    final berat = double.tryParse(value);
                    if (berat != null) {
                      final validBerat = berat < PriceList.minKiloan ? PriceList.minKiloan : berat;
                      item['berat'] = validBerat;
                      updateHarga();
                    }
                  }
                });
              },
            ),
          ] else if (jenisLayanan == 'sepatu') ...[
            // Opsi Sepatu
            Builder(
              builder: (context) {
                // Validasi value untuk memastikan ada di items
                final currentValue = item['jenisBarang'] as String?;
                final validValues = ['sneakers', 'kulit'];
                final selectedValue = (currentValue != null && validValues.contains(currentValue))
                    ? currentValue
                    : 'sneakers';
                
                return DropdownButtonFormField<String>(
                  value: selectedValue,
                  decoration: InputDecoration(
                    labelText: 'Jenis Sepatu',
                    prefixIcon: const Icon(Icons.checkroom),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: 'sneakers',
                      child: Text('Sneakers - Rp ${PriceList.sepatuSneakers.toStringAsFixed(0)}'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'kulit',
                      child: Text('Kulit - Rp ${PriceList.sepatuKulit.toStringAsFixed(0)}'),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      item['jenisBarang'] = value;
                      updateHarga();
                    });
                  },
                );
              },
            ),
          ] else if (jenisLayanan == 'jaket') ...[
            // Jaket Kulit
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.checkroom, color: Colors.orange[800]),
                  const SizedBox(width: 8),
                  Text(
                    'Jaket Kulit - Rp ${PriceList.jaketKulit.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[800],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (jenisLayanan == 'helm') ...[
            // Helm
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.airplanemode_active, color: Colors.green[800]),
                  const SizedBox(width: 8),
                  Text(
                    'Helm - Rp ${PriceList.helm.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green[800],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (jenisLayanan == 'tas') ...[
            // Ukuran Tas
            DropdownButtonFormField<String>(
              value: item['ukuran'] ?? 'kecil',
              decoration: InputDecoration(
                labelText: 'Ukuran Tas',
                prefixIcon: const Icon(Icons.backpack),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: PriceList.getUkuranTas().map((ukuran) {
                double harga = 0;
                switch (ukuran) {
                  case 'kecil':
                    harga = PriceList.tasKecil;
                    break;
                  case 'sedang':
                    harga = PriceList.tasSedang;
                    break;
                  case 'besar':
                    harga = PriceList.tasBesar;
                    break;
                  case 'carrier':
                    harga = PriceList.tasCarrier;
                    break;
                }
                return DropdownMenuItem(
                  value: ukuran,
                  child: Text('${ukuran.toUpperCase()} - Rp ${harga.toStringAsFixed(0)}'),
                );
              }).toList(),
              onChanged: (value) {
                setDialogState(() {
                  item['ukuran'] = value;
                  updateHarga();
                });
              },
            ),
          ] else if (jenisLayanan == 'boneka') ...[
            // Ukuran Boneka
            DropdownButtonFormField<String>(
              value: item['ukuran'] ?? 'kecil',
              decoration: InputDecoration(
                labelText: 'Ukuran Boneka',
                prefixIcon: const Icon(Icons.toys),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: PriceList.getUkuranBoneka().map((ukuran) {
                double harga = 0;
                switch (ukuran) {
                  case 'kecil':
                    harga = PriceList.bonekaKecil;
                    break;
                  case 'sedang':
                    harga = PriceList.bonekaSedang;
                    break;
                  case 'besar':
                    harga = PriceList.bonekaBesar;
                    break;
                  case 'jumbo':
                    harga = PriceList.bonekaJumbo;
                    break;
                }
                return DropdownMenuItem(
                  value: ukuran,
                  child: Text('${ukuran.toUpperCase()} - Rp ${harga.toStringAsFixed(0)}'),
                );
              }).toList(),
              onChanged: (value) {
                setDialogState(() {
                  item['ukuran'] = value;
                  updateHarga();
                });
              },
            ),
          ] else if (jenisLayanan == 'karpet') ...[
            // Opsi Karpet
            DropdownButtonFormField<String>(
              value: item['jenisBarang'] ?? 'standar',
              decoration: InputDecoration(
                labelText: 'Jenis Karpet',
                prefixIcon: const Icon(Icons.carpenter),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: [
                DropdownMenuItem(
                  value: 'standar',
                  child: Text('Standar - Rp ${PriceList.karpetStandar.toStringAsFixed(0)}/m²'),
                ),
                DropdownMenuItem(
                  value: 'tipis',
                  child: Text('Tipis - Rp ${PriceList.karpetTipis.toStringAsFixed(0)}/m²'),
                ),
                DropdownMenuItem(
                  value: 'tebal',
                  child: Text('Tebal/Mushola - Rp ${PriceList.karpetTebal.toStringAsFixed(0)}/m²'),
                ),
              ],
              onChanged: (value) {
                setDialogState(() {
                  item['jenisBarang'] = value;
                  updateHarga();
                });
              },
            ),
            const SizedBox(height: 8),
            // Luas (m²)
            TextField(
              controller: luasController,
              decoration: InputDecoration(
                labelText: 'Luas (m²)',
                prefixIcon: const Icon(Icons.square_foot),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                setDialogState(() {
                  item['luas'] = double.tryParse(value) ?? 1.0;
                  updateHarga();
                });
              },
            ),
          ],
          
          const SizedBox(height: 8),
          // Jumlah
          TextField(
            controller: jumlahController,
            decoration: InputDecoration(
              labelText: 'Jumlah',
              prefixIcon: const Icon(Icons.numbers),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setDialogState(() {
                item['jumlah'] = int.tryParse(value) ?? 1;
                updateHarga();
              });
            },
          ),
          const SizedBox(height: 8),
          // Catatan
          TextField(
            controller: catatanController,
            decoration: InputDecoration(
              labelText: 'Catatan (misal: noda, rusak)',
              prefixIcon: const Icon(Icons.note),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            maxLines: 2,
            onChanged: (value) {
              setDialogState(() {
                item['catatan'] = value;
              });
            },
          ),
          const SizedBox(height: 8),
          // Foto (Opsional)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 70,
                        maxWidth: 1024,
                      );
                      
                      if (image != null) {
                        final storedPath = await _storeImage(
                          image,
                          'laundry_photos',
                          'laundry_photos',
                          prefix: 'foto',
                        );
                        setDialogState(() {
                          item['foto'] = storedPath;
                        });
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Foto berhasil diambil'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error mengambil foto: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Ambil Foto'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 70,
                        maxWidth: 1024,
                      );
                      
                      if (image != null) {
                        final storedPath = await _storeImage(
                          image,
                          'laundry_photos',
                          'laundry_photos',
                          prefix: 'foto',
                        );
                        setDialogState(() {
                          item['foto'] = storedPath;
                        });
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Foto berhasil dipilih'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error memilih foto: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: const Text('Pilih dari Galeri'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (item['foto'] != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[800], size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Foto ada',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[800],
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(Icons.delete, size: 16, color: Colors.red[800]),
                        onPressed: () {
                          setDialogState(() {
                            item['foto'] = null;
                          });
                        },
                        tooltip: 'Hapus Foto',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(Transaksi transaksi, List<DetailLaundry> detailList) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Transaksi Berhasil!',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID Transaksi: ${transaksi.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Customer: ${transaksi.customerName}'),
                    Text('Telepon: ${transaksi.customerPhone}'),
                    Text('Total Item: ${detailList.length}'),
                    Text(
                      'Total Harga: Rp ${_formatCurrency(transaksi.totalHarga)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Detail Laundry:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ...detailList.map((detail) {
                String label = _getDetailLabel(detail);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.checkroom, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            if (detail.catatan != null && detail.catatan!.isNotEmpty)
                              Text(
                                'Catatan: ${detail.catatan}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cetakStruk(transaksi);
            },
            child: const Text('Cetak Struk'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showFilterPembayaranDialog() async {
    String? selectedStatus;
    String? selectedMetode;
    DateTime? startDate;
    DateTime? endDate;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Pembayaran'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter Status
                const Text(
                  'Status Pembayaran:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Semua Status')),
                    DropdownMenuItem(value: 'lunas', child: Text('Lunas')),
                    DropdownMenuItem(value: 'belum_lunas', child: Text('Belum Lunas')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedStatus = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Filter Metode Pembayaran
                const Text(
                  'Metode Pembayaran:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedMetode,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Semua Metode')),
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'transfer', child: Text('Transfer Bank')),
                    DropdownMenuItem(value: 'qris', child: Text('QRIS')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedMetode = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Filter Tanggal
                const Text(
                  'Tanggal Pembayaran:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
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
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Dari Tanggal',
                            border: OutlineInputBorder(),
                            isDense: true,
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            startDate != null ? _formatDate(startDate!) : 'Pilih tanggal',
                            style: TextStyle(
                              color: startDate != null ? Colors.black : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDate ?? DateTime.now(),
                            firstDate: startDate ?? DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setDialogState(() {
                              endDate = date;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Sampai Tanggal',
                            border: OutlineInputBorder(),
                            isDense: true,
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            endDate != null ? _formatDate(endDate!) : 'Pilih tanggal',
                            style: TextStyle(
                              color: endDate != null ? Colors.black : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() {
                  selectedStatus = null;
                  selectedMetode = null;
                  startDate = null;
                  endDate = null;
                });
              },
              child: const Text('Reset'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final filteredPembayaran = await _transaksiService.filterPembayaran(
                    status: selectedStatus,
                    metodePembayaran: selectedMetode,
                    startDate: startDate,
                    endDate: endDate,
                  );
                  
                  Navigator.pop(context);
                  
                  // Tampilkan hasil filter
                  _showFilterPembayaranResults(filteredPembayaran);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Terapkan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterPembayaranResults(List<Pembayaran> pembayaranList) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hasil Filter Pembayaran (${pembayaranList.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: pembayaranList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada pembayaran yang ditemukan',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: pembayaranList.length,
                        itemBuilder: (context, index) {
                          final pembayaran = pembayaranList[index];
                          return FutureBuilder<Transaksi?>(
                            future: _transaksiService.getTransaksiById(pembayaran.transaksiId),
                            builder: (context, snapshot) {
                              final transaksi = snapshot.data;
                              return ListTile(
                                title: Text(transaksi?.customerName ?? 'Customer'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('ID: ${pembayaran.transaksiId}'),
                                    Text('Metode: ${pembayaran.metodePembayaran}'),
                                    Text('Status: ${pembayaran.status}'),
                                    Text('Tanggal: ${_formatDateTime(pembayaran.tanggalBayar)}'),
                                  ],
                                ),
                                trailing: Text(
                                  'Rp ${_formatCurrency(pembayaran.jumlah)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _inputPembayaran() async {
    // Load semua transaksi untuk dipilih
    final allTransaksi = await _transaksiService.getAllTransaksi();
    final transaksiBelumLunas = <Transaksi>[];
    
    for (var transaksi in allTransaksi) {
      final isLunas = await _transaksiService.isTransaksiLunas(transaksi.id);
      if (!isLunas) {
        transaksiBelumLunas.add(transaksi);
      }
    }
    
    if (transaksiBelumLunas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua transaksi sudah lunas'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Tampilkan dialog untuk memilih transaksi
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Transaksi untuk Pembayaran'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: transaksiBelumLunas.length,
            itemBuilder: (context, index) {
              final transaksi = transaksiBelumLunas[index];
              return ListTile(
                leading: const Icon(Icons.receipt),
                title: Text(transaksi.customerName),
                subtitle: Text('ID: ${transaksi.id}\nTotal: Rp ${_formatCurrency(transaksi.totalHarga)}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _showFormPembayaran(transaksi);
                },
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
  }

  void _detailIsiLaundry() {
    if (daftarLaundryMasuk.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada transaksi laundry'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Tampilkan dialog untuk memilih transaksi
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Transaksi'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: daftarLaundryMasuk.length,
            itemBuilder: (context, index) {
              final transaksi = daftarLaundryMasuk[index];
              return ListTile(
                leading: const Icon(Icons.receipt),
                title: Text(transaksi.customerName),
                subtitle: Text('ID: ${transaksi.id}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _showDetailLaundry(transaksi);
                },
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
  }

  void _showDetailLaundry(Transaksi transaksi) async {
    // Load detail dari map atau database
    List<DetailLaundry> detailList = detailLaundryMap[transaksi.id] ?? [];
    
    // Jika belum ada di map, load dari database
    if (detailList.isEmpty) {
      detailList = await _transaksiService.getDetailLaundryByTransaksiId(transaksi.id);
      // Simpan ke map untuk next time
      if (detailList.isNotEmpty) {
        setState(() {
          detailLaundryMap[transaksi.id] = detailList;
        });
      }
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detail Isi Laundry',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${transaksi.customerName} - ID: ${transaksi.id}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: detailList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada detail laundry',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...detailList.map((detail) => Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.blue[200]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            _getIconForLayanan(detail.jenisLayanan),
                                            color: Theme.of(context).colorScheme.primary,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _getDetailLabel(detail),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                if (detail.berat != null)
                                                  Text(
                                                    'Berat: ${detail.berat} kg',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                if (detail.luas != null)
                                                  Text(
                                                    'Luas: ${detail.luas} m²',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.primary,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '${detail.jumlah} pcs',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (detail.catatan != null && detail.catatan!.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.note,
                                              size: 16,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                detail.catatan!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (detail.foto != null) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.image,
                                              size: 16,
                                              color: Colors.green[600],
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Foto tersedia',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.green[700],
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: ${detailList.length} item',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tutup'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pembayaranDiTempat(Transaksi transaksi) {
    _showFormPembayaran(transaksi);
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
                        _loadData();
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

  Future<String> _uploadImageToSupabase(XFile image, String folder) async {
    final bytes = await image.readAsBytes();
    final ext = path.extension(image.name.isNotEmpty ? image.name : image.path);
    final safeExt = ext.isNotEmpty ? ext : '.jpg';
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$safeExt';
    final filePath = '$folder/$fileName';

    await _supabase.storage.from('images').uploadBinary(
          filePath,
          bytes,
          fileOptions: FileOptions(
            contentType: image.mimeType,
            upsert: false,
          ),
        );

    return _supabase.storage.from('images').getPublicUrl(filePath);
  }

  Future<String> _storeImage(
    XFile image,
    String localFolder,
    String remoteFolder, {
    String prefix = 'foto',
  }) async {
    if (kIsWeb || AppConstants.useSupabase) {
      return _uploadImageToSupabase(image, remoteFolder);
    }

    final appDir = await getApplicationDocumentsDirectory();
    final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
    final savedImage = File(path.join(appDir.path, localFolder, fileName));
    await savedImage.parent.create(recursive: true);
    await File(image.path).copy(savedImage.path);
    return savedImage.path;
  }

  void _showFormPembayaran(Transaksi transaksi) async {
    // Load data pembayaran yang sudah ada
    final pembayaranList = await _transaksiService.getPembayaranByTransaksiId(transaksi.id);
    final totalSudahDibayar = pembayaranList
        .where((p) => p.status == 'lunas')
        .fold(0.0, (sum, p) => sum + p.jumlah);
    final sisaBayar = transaksi.totalHarga - totalSudahDibayar;

    // Form controllers
    final jumlahController = TextEditingController(text: sisaBayar.toStringAsFixed(0));
    String? metodePembayaran = 'cash';
    String? buktiPembayaranPath;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Form Pembayaran',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${transaksi.customerName} - ${transaksi.id}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Info transaksi
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Tagihan: Rp ${_formatCurrency(transaksi.totalHarga)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sudah Dibayar: Rp ${_formatCurrency(totalSudahDibayar)}',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sisa Bayar: Rp ${_formatCurrency(sisaBayar)}',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Jumlah pembayaran
                        TextFormField(
                          controller: jumlahController,
                          decoration: const InputDecoration(
                            labelText: 'Jumlah Pembayaran *',
                            hintText: 'Masukkan jumlah pembayaran',
                            prefixIcon: Icon(Icons.attach_money),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Jumlah pembayaran harus diisi';
                            }
                            final jumlah = double.tryParse(value);
                            if (jumlah == null || jumlah <= 0) {
                              return 'Jumlah harus lebih dari 0';
                            }
                            if (jumlah > sisaBayar) {
                              return 'Jumlah tidak boleh melebihi sisa bayar';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Metode pembayaran
                        DropdownButtonFormField<String>(
                          value: metodePembayaran,
                          decoration: const InputDecoration(
                            labelText: 'Metode Pembayaran *',
                            prefixIcon: Icon(Icons.payment),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'cash',
                              child: Text('Cash (Tunai)'),
                            ),
                            DropdownMenuItem(
                              value: 'transfer',
                              child: Text('Transfer Bank'),
                            ),
                            DropdownMenuItem(
                              value: 'qris',
                              child: Text('QRIS'),
                            ),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              metodePembayaran = value;
                              // Reset bukti jika metode cash
                              if (value == 'cash') {
                                buktiPembayaranPath = null;
                              }
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Metode pembayaran harus dipilih';
                            }
                            return null;
                          },
                        ),
                        // Upload bukti pembayaran (untuk transfer/qris)
                        if (metodePembayaran != 'cash') ...[
                          const SizedBox(height: 16),
                          Text(
                            'Bukti Pembayaran ${metodePembayaran == 'transfer' ? '(Transfer Bank)' : '(QRIS)'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    try {
                                      final ImagePicker picker = ImagePicker();
                                      final XFile? image = await picker.pickImage(
                                        source: ImageSource.camera,
                                      );
                                      if (image != null) {
                                        final storedPath = await _storeImage(
                                          image,
                                          'bukti_pembayaran',
                                          'bukti_pembayaran',
                                          prefix: 'bukti',
                                        );
                                        setDialogState(() {
                                          buktiPembayaranPath = storedPath;
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Bukti pembayaran berhasil diambil'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.camera_alt, size: 18),
                                  label: const Text('Ambil Foto'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    try {
                                      final ImagePicker picker = ImagePicker();
                                      final XFile? image = await picker.pickImage(
                                        source: ImageSource.gallery,
                                      );
                                      if (image != null) {
                                        final storedPath = await _storeImage(
                                          image,
                                          'bukti_pembayaran',
                                          'bukti_pembayaran',
                                          prefix: 'bukti',
                                        );
                                        setDialogState(() {
                                          buktiPembayaranPath = storedPath;
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Bukti pembayaran berhasil dipilih'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.photo_library, size: 18),
                                  label: const Text('Pilih dari Galeri'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (buktiPembayaranPath != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green[800], size: 16),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Bukti tersedia',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green[800],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                                    onPressed: () {
                                      setDialogState(() {
                                        buktiPembayaranPath = null;
                                      });
                                    },
                                    tooltip: 'Hapus Bukti',
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (metodePembayaran != 'cash' && buktiPembayaranPath == null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Bukti pembayaran wajib diupload untuk ${metodePembayaran == 'transfer' ? 'transfer bank' : 'QRIS'}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange[700],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                  // Footer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }
                            
                            // Validasi bukti untuk transfer/qris
                            if (metodePembayaran != 'cash' && buktiPembayaranPath == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Bukti pembayaran wajib diupload untuk ${metodePembayaran == 'transfer' ? 'transfer bank' : 'QRIS'}'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            try {
                              final jumlah = double.parse(jumlahController.text);
                              
                              // Buat pembayaran
                              final pembayaran = Pembayaran(
                                id: 'PAY_${DateTime.now().millisecondsSinceEpoch}',
                                transaksiId: transaksi.id,
                                jumlah: jumlah,
                                tanggalBayar: DateTime.now(),
                                metodePembayaran: metodePembayaran!,
                                status: 'lunas',
                                buktiPembayaran: buktiPembayaranPath,
                              );

                              // Simpan pembayaran dan update status transaksi jika lunas
                              await _transaksiService.createPembayaranAndUpdateStatus(pembayaran);

                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Pembayaran berhasil disimpan'),
                                  backgroundColor: Colors.green,
                                ),
                              );

                              // Reload data
                              _loadData();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error menyimpan pembayaran: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Simpan Pembayaran'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _cetakStruk(Transaksi transaksi) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Struk Transaksi'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ID: ${transaksi.id}'),
              Text('Customer: ${transaksi.customerName}'),
              Text('Telepon: ${transaksi.customerPhone}'),
              Text('Tanggal: ${_formatDateTime(transaksi.tanggalMasuk)}'),
              Text('Total: Rp ${_formatCurrency(transaksi.totalHarga)}'),
              if (transaksi.catatan != null)
                Text('Catatan: ${transaksi.catatan}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Struk berhasil dicetak')),
              );
            },
            icon: const Icon(Icons.print),
            label: const Text('Cetak'),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'diterima':
        return 'Diterima';
      case 'proses':
        return 'Sedang Diproses';
      case 'selesai':
        return 'Selesai';
      case 'dikirim':
        return 'Dikirim';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'diterima':
        return Colors.blue;
      case 'proses':
        return Colors.blue[700]!;
      case 'selesai':
        return Colors.green;
      case 'dikirim':
        return Colors.purple;
      default:
        return Colors.black;
    }
  }

  // Search and Filter UI
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Cari transaksi (ID, nama customer, no. telepon)',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 20),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
                _loadData();
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
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
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_alt, color: Colors.blue[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter Aktif:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (_filterStatus != null)
                      Chip(
                        label: Text('Status: ${_formatStatus(_filterStatus!)}'),
                        backgroundColor: Colors.blue[100],
                        labelStyle: const TextStyle(fontSize: 11),
                        onDeleted: () {
                          setState(() {
                            _filterStatus = null;
                            _checkFilterState();
                          });
                          _loadData();
                        },
                      ),
                    if (_filterStartDate != null || _filterEndDate != null)
                      Chip(
                        label: Text(
                          _filterStartDate != null && _filterEndDate != null
                              ? 'Tanggal: ${_formatDate(_filterStartDate!)} - ${_formatDate(_filterEndDate!)}'
                              : _filterStartDate != null
                                  ? 'Dari: ${_formatDate(_filterStartDate!)}'
                                  : 'Sampai: ${_formatDate(_filterEndDate!)}',
                        ),
                        backgroundColor: Colors.blue[100],
                        labelStyle: const TextStyle(fontSize: 11),
                        onDeleted: () {
                          setState(() {
                            _filterStartDate = null;
                            _filterEndDate = null;
                            _checkFilterState();
                          });
                          _loadData();
                        },
                      ),
                  ],
                ),
              ],
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

  void _checkFilterState() {
    _isFiltered = _filterStatus != null || _filterStartDate != null || _filterEndDate != null;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pencarian Transaksi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Cari (ID, Nama, No. Telepon)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _loadData();
              },
              child: const Text('Cari'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
              Navigator.pop(context);
              _loadData();
            },
            child: const Text('Hapus'),
          ),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter Status
                const Text(
                  'Status:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
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
                // Filter Tanggal
                const Text(
                  'Tanggal:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
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
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Dari Tanggal',
                            border: OutlineInputBorder(),
                            isDense: true,
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            startDate != null ? _formatDate(startDate!) : 'Pilih tanggal',
                            style: TextStyle(
                              color: startDate != null ? Colors.black : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDate ?? DateTime.now(),
                            firstDate: startDate ?? DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setDialogState(() {
                              endDate = date;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Sampai Tanggal',
                            border: OutlineInputBorder(),
                            isDense: true,
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            endDate != null ? _formatDate(endDate!) : 'Pilih tanggal',
                            style: TextStyle(
                              color: endDate != null ? Colors.black : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() {
                  selectedStatus = null;
                  startDate = null;
                  endDate = null;
                });
              },
              child: const Text('Reset'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _filterStatus = selectedStatus;
                  _filterStartDate = startDate;
                  _filterEndDate = endDate;
                  _checkFilterState();
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

  String _getDetailLabel(DetailLaundry detail) {
    String label = '';
    switch (detail.jenisLayanan) {
      case 'laundry_kiloan':
        String opsi = detail.jenisBarang.replaceAll('_', ' ').toUpperCase();
        label = 'Laundry Kiloan - $opsi';
        if (detail.berat != null) {
          label += ' (${detail.berat} kg)';
        }
        break;
      case 'sepatu':
        label = 'Sepatu ${detail.jenisBarang == 'kulit' ? 'Kulit' : 'Sneakers'}';
        break;
      case 'jaket':
        label = 'Jaket Kulit';
        break;
      case 'helm':
        label = 'Helm';
        break;
      case 'tas':
        label = 'Tas ${detail.ukuran?.toUpperCase() ?? ''}';
        break;
      case 'boneka':
        label = 'Boneka ${detail.ukuran?.toUpperCase() ?? ''}';
        break;
      case 'karpet':
        String jenis = detail.jenisBarang == 'tebal' ? 'Tebal/Mushola' : detail.jenisBarang.toUpperCase();
        label = 'Karpet $jenis';
        if (detail.luas != null) {
          label += ' (${detail.luas} m²)';
        }
        break;
      default:
        label = detail.jenisBarang.toUpperCase();
    }
    return '$label x${detail.jumlah}';
  }

  IconData _getIconForLayanan(String jenisLayanan) {
    switch (jenisLayanan) {
      case 'laundry_kiloan':
        return Icons.local_laundry_service;
      case 'sepatu':
        return Icons.checkroom;
      case 'jaket':
        return Icons.checkroom;
      case 'helm':
        return Icons.airplanemode_active;
      case 'tas':
        return Icons.backpack;
      case 'boneka':
        return Icons.toys;
      case 'karpet':
        return Icons.carpenter;
      default:
        return Icons.checkroom;
    }
  }
}


