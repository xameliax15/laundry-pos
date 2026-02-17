import 'package:flutter/material.dart';
import '../../models/transaksi.dart';
import '../../models/pembayaran.dart';
import '../../models/user.dart';
import '../../core/routes.dart';
import '../../core/logger.dart';
import '../../services/transaksi_service.dart';
import 'user_management_page.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/sidebar_layout.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../services/pdf_service.dart';
import 'owner_mobile_view.dart';
import '../kasir/kasir_riwayat.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  String selectedPeriod = 'Harian'; // Harian atau Bulanan
  bool isLoading = true;
  double totalOmzet = 0.0;
  double pendapatanHarian = 0.0;
  double pendapatanBulanan = 0.0;

  int transaksiCODBelumDiverifikasi = 0;
  int totalTransaksiCount = 0; // New state

  // Data untuk grafik (7 hari terakhir)
  List<Map<String, dynamic>> grafikPendapatan = [];

  // Data transaksi COD belum diverifikasi
  List<Map<String, dynamic>> transaksiCOD = [];

  // Data monitoring kasir & kurir (untuk sekarang masih dummy, bisa diimplementasikan nanti)
  List<Map<String, dynamic>> dataKasir = [
    {'nama': 'Kasir 1', 'transaksiHariIni': 0, 'status': 'Aktif'},
    {'nama': 'Kasir 2', 'transaksiHariIni': 0, 'status': 'Aktif'},
  ];

  List<Map<String, dynamic>> dataKurir = [
    {'nama': 'Kurir 1', 'orderHariIni': 0, 'status': 'Aktif'},
    {'nama': 'Kurir 2', 'orderHariIni': 0, 'status': 'Aktif'},
  ];

  // Service
  final TransaksiService _transaksiService = TransaksiService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Load total omzet
      final omzet = await _transaksiService.getTotalOmzet();
      
      // Load pendapatan harian
      final pendapatanHari = await _transaksiService.getTotalPendapatanHariIni();
      
      // Load pendapatan bulanan (bulan ini)
      final now = DateTime.now();
      final pendapatanBulan = await _transaksiService.getPendapatanBulanan(now.year, now.month);
      
      // Load total transaksi count
      final trxCount = await _transaksiService.getTotalTransaksiCount();

      // Load grafik pendapatan 7 hari terakhir
      // Load grafik pendapatan 7 hari terakhir
      final grafik = await _loadGrafikPendapatan();

      // Load transaksi COD belum diverifikasi (transaksi selesai dan belum diterima)
      final transaksiSelesai = await _transaksiService.getTransaksiByStatus('selesai');
      final codList = <Map<String, dynamic>>[];
      
      for (var t in transaksiSelesai) {
        // Load order kurir untuk mendapatkan kurir ID
        final orderKurir = await _transaksiService.getOrderKurirByTransaksiId(t.id);
        String kurirName = 'Belum diassign';
        if (orderKurir != null) {
          final kurir = await _transaksiService.getUserById(orderKurir.kurirId);
          kurirName = kurir?.username ?? 'Kurir tidak ditemukan';
        }
        
        // Load bukti pembayaran COD
        final pembayaranCOD = await _transaksiService.getPembayaranCODByTransaksiId(t.id);
        
        codList.add({
          'id': t.id,
          'customerName': t.customerName,
          'jumlah': t.totalHarga,
          'tanggal': t.tanggalMasuk,
          'kurir': kurirName,
          'buktiPembayaran': pembayaranCOD?.buktiPembayaran,
        });
      }
      // Load monitoring kasir & kurir
      final kasirList = await _transaksiService.getUsersByRole('kasir');
      final kurirList = await _transaksiService.getUsersByRole('kurir');
      
      final dataKasirList = <Map<String, dynamic>>[];
      for (var kasir in kasirList) {
        // Note: Untuk filtering per kasir, diperlukan field kasir_id di table transaksi
        // Fitur ini akan ditambahkan di fase selanjutnya
        final transaksiHariIni = await _transaksiService.getTotalTransaksiHariIni();
        dataKasirList.add({
          'nama': kasir.username,
          'transaksiHariIni': transaksiHariIni,
          'status': 'Aktif',
        });
      }
      
      final dataKurirList = <Map<String, dynamic>>[];
      for (var kurir in kurirList) {
        // Hitung order hari ini per kurir
        final orderKurirList = await _transaksiService.getOrderKurirByKurirId(kurir.id);
        final orderHariIni = orderKurirList.where((o) {
          final today = DateTime.now();
          return o.tanggalAssign != null &&
              o.tanggalAssign!.year == today.year &&
              o.tanggalAssign!.month == today.month &&
              o.tanggalAssign!.day == today.day;
        }).length;
        
        dataKurirList.add({
          'nama': kurir.username,
          'orderHariIni': orderHariIni,
          'status': 'Aktif',
        });
      }

      setState(() {
        totalOmzet = omzet;
        pendapatanHarian = pendapatanHari;
        pendapatanBulanan = pendapatanBulan;
        grafikPendapatan = grafik;
        totalTransaksiCount = trxCount; // Update state
        transaksiCOD = codList;
        transaksiCODBelumDiverifikasi = codList.length;
        dataKasir = dataKasirList;
        dataKurir = dataKurirList;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadGrafikPendapatan() async {
    final now = DateTime.now();
    final List<Map<String, dynamic>> grafik = [];
    final List<String> hariNama = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    // Ambil 7 hari terakhir
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final pendapatan = await _transaksiService.getPendapatanByDate(date);

      grafik.add({
        'hari': hariNama[date.weekday % 7],
        'pendapatan': pendapatan.toInt(),
      });
    }

    return grafik;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        
        if (isMobile) {
          return _buildMobileLayout();
        } else {
          return _buildDesktopLayout();
        }
      },
    );
  }

  // State for mobile tabs
  int _mobileTabIndex = 0;

  Widget _buildMobileLayout() {
    final authService = AuthService();
    final user = authService.getCurrentUser();
    final userName = user?.username ?? 'Owner';
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : IndexedStack(
                index: _mobileTabIndex,
                children: [
                  // Tab 0: Dashboard
                  OwnerMobileView(
                    userName: userName,
                    totalOmzet: totalOmzet,
                    pendapatanHariIni: pendapatanHarian,
                    totalTransaksi: totalTransaksiCount,
                    grafikPendapatan: grafikPendapatan,
                    transaksiCODCount: transaksiCODBelumDiverifikasi,
                    transaksiCOD: transaksiCOD.map((t) => {
                      'id': t['id'],
                      'customer_name': t['customerName'],
                      'total_harga': t['jumlah'],
                    }).toList(),
                    onViewReport: () {
                      setState(() => _mobileTabIndex = 1);
                    },
                    onManageUsers: () {
                      setState(() => _mobileTabIndex = 2);
                    },
                    onVerifyPayments: () {
                      setState(() => _mobileTabIndex = 3);
                    },
                    onSettings: () {},
                    onSeeAllCOD: () {
                      setState(() => _mobileTabIndex = 3);
                    },
                    onVerifyCOD: (trx) {
                      final originalTrx = transaksiCOD.firstWhere(
                        (t) => t['id'] == trx['id'],
                        orElse: () => trx,
                      );
                      _verifikasiTransaksiCOD(originalTrx);
                    },
                    onDeleteHistory: _showResetRiwayatDialog,
                    currentIndex: _mobileTabIndex,
                    onTabChanged: (index) {
                      setState(() => _mobileTabIndex = index);
                    },
                    onRefresh: _loadData,
                    onLogout: () => AppRoutes.logout(context),
                  ),

                  // Tab 1: Laporan View (Embed content of _lihatLaporan)
                  _buildLaporanEmbed(),

                  // Tab 2: User Management
                  const UserManagementPage(isEmbedded: true), 

                  // Tab 3: Riwayat Pesanan
                  const KasirRiwayat(isEmbedded: true),
                ],
              ),
      ),
      bottomNavigationBar: MobileBottomNavBar(
        currentIndex: _mobileTabIndex,
        onTap: (index) {
          setState(() {
            _mobileTabIndex = index;
          });
          // Refresh data if switching to dashboard
          if (index == 0) _loadData();
        },
        onFabTap: () {
          // Tombol tengah untuk verifikasi pembayaran COD
          _verifikasiPembayaran();
        },
        fabIcon: Icons.verified,
        items: const [
          MobileNavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
          MobileNavItem(icon: Icons.assessment_outlined, activeIcon: Icons.assessment, label: 'Reports'),
          MobileNavItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Users'),
          MobileNavItem(icon: Icons.history_outlined, activeIcon: Icons.history, label: 'Riwayat'),
        ],
      ),
    );
  }

  Widget _buildLaporanEmbed() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Laporan FMS',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandBlue,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: 'Download PDF',
                onPressed: _downloadLaporanPdf,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Period Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedPeriod,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'Harian', child: Text('Laporan Harian')),
                  DropdownMenuItem(value: 'Bulanan', child: Text('Laporan Bulanan')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedPeriod = value;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildLaporanItem('Total Omzet', 'Rp ${_formatCurrency(totalOmzet)}'),
          if (selectedPeriod == 'Harian')
             _buildLaporanItem('Pendapatan Harian', 'Rp ${_formatCurrency(pendapatanHarian)}'),
          if (selectedPeriod == 'Bulanan')
             _buildLaporanItem('Pendapatan Bulanan', 'Rp ${_formatCurrency(pendapatanBulanan)}'),
          _buildLaporanItem('Transaksi COD Belum Diverifikasi', transaksiCODBelumDiverifikasi.toString()),
          _buildLaporanItem('Total Kasir Aktif', dataKasir.length.toString()),
          _buildLaporanItem('Total Kurir Aktif', dataKurir.length.toString()),
          
          const SizedBox(height: 24),
          const Text(
            'Detail Kasir',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...dataKasir.map((kasir) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(kasir['username'] ?? 'Unknown'),
              subtitle: Text(kasir['email'] ?? ''),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildVerificationEmbed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Verifikasi Pembayaran COD',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadData,
              ),
            ],
          ),
        ),
        Expanded(
          child: transaksiCOD.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: Colors.green[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Semua transaksi COD lunas!',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: transaksiCOD.length,
                  itemBuilder: (context, index) {
                    final trx = transaksiCOD[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  trx['customerName'] ?? 'Pelanggan',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Perlu Verifikasi',
                                    style: TextStyle(color: Colors.orange, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('ID: ${trx['id']}'),
                            const SizedBox(height: 4),
                            Text(
                              'Total: Rp ${_formatCurrency(trx['jumlah'])}',
                              style: const TextStyle(
                                color: AppColors.brandBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _verifikasiTransaksiCOD(trx),
                                icon: const Icon(Icons.verified),
                                label: const Text('Verifikasi Pembayaran'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.brandBlue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return SidebarLayout(
      title: 'Dashboard Owner',
      items: [
        SidebarItem(
          label: 'Dashboard',
          icon: Icons.dashboard_rounded,
          isActive: true,
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
            ).then((_) => _loadData());
          },
        ),

        SidebarItem(
          label: 'Riwayat Pesanan',
          icon: Icons.history,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const KasirRiwayat(userRole: 'owner'),
              ),
            );
          },
        ),
        SidebarItem(
          label: 'Keluar',
          icon: Icons.logout,
          isDestructive: true,
          onTap: () => AppRoutes.logout(context),
        ),
      ],
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
                    // Total Omzet Card
                    _buildTotalOmzetCard(),
                    const SizedBox(height: 20),

                    // Pendapatan Harian/Bulanan
                    _buildPendapatanCard(),
                    const SizedBox(height: 20),

                    // Tombol Utama
                    _buildTombolUtama(),
                    const SizedBox(height: 20),

                    // Grafik Pendapatan
                    _buildSectionTitle('📈 Grafik Pendapatan'),
                    const SizedBox(height: 12),
                    _buildGrafikPendapatan(),
                    const SizedBox(height: 20),

                    // Transaksi COD Belum Diverifikasi
                    _buildSectionTitle('✅ Verifikasi Pembayaran Kurir'),
                    const SizedBox(height: 8),
                    _buildTransaksiCODCard(),
                    const SizedBox(height: 20),

                    // Monitoring Kasir & Kurir
                    _buildSectionTitle('👥 Monitoring Kasir & Kurir'),
                    const SizedBox(height: 12),
                    _buildMonitoringSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTotalOmzetCard() {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Omzet',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${_formatCurrency(totalOmzet)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendapatanCard() {
    return Card(
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
                const Text(
                  'Pendapatan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value: selectedPeriod,
                    underline: const SizedBox(),
                    isDense: true,
                    items: ['Harian', 'Bulanan'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedPeriod = newValue;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPendapatanItem(
                    selectedPeriod == 'Harian' ? 'Hari Ini' : 'Bulan Ini',
                    selectedPeriod == 'Harian' ? pendapatanHarian : pendapatanBulanan,
                    Icons.today,
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: Colors.grey[300],
                ),
                Expanded(
                  child: _buildPendapatanItem(
                    'COD Belum Diverifikasi',
                    transaksiCODBelumDiverifikasi.toString(),
                    Icons.pending,
                    isWarning: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendapatanItem(String label, dynamic value, IconData icon, {bool isWarning = false}) {
    return Column(
      children: [
        Icon(
          icon,
          color: isWarning ? AppColors.accentOrange : AppColors.brandBlue,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          isWarning ? value : 'Rp ${_formatCurrency(value)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isWarning ? AppColors.accentOrange : AppColors.accentGreen,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                'Manajemen User',
                Icons.people,
                AppColors.accentPurple,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserManagementPage(),
                    ),
                  ).then((_) => _loadData());
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTombol(
                'Lihat Laporan',
                Icons.description,
                AppColors.brandBlue,
                _lihatLaporan,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTombol(
                'Verifikasi Pembayaran',
                Icons.verified,
                AppColors.accentGreen,
                _verifikasiPembayaran,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTombol(
                'Reset Riwayat',
                Icons.delete_sweep,
                const Color(0xFFE24A4A),
                _showResetRiwayatDialog,
              ),
            ),
          ],
        ),
      ],
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
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
                  'Ringkasan Owner',
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
              Icons.stacked_bar_chart,
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

  Widget _buildGrafikPendapatan() {
    if (grafikPendapatan.isEmpty) {
      return _buildEmptyState('Belum ada data pendapatan');
    }

    final maxPendapatan = grafikPendapatan
        .map((e) => e['pendapatan'] as int)
        .fold<int>(0, (max, value) => value > max ? value : max)
        .toDouble();
    final safeMax = maxPendapatan == 0 ? 1.0 : maxPendapatan;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pendapatan 7 Hari Terakhir',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: grafikPendapatan.map((data) {
                  double height = (data['pendapatan'] as int) / safeMax * 160;
                  // Ensure minimum height for visibility
                  if (height < 4) height = 4;
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 35,
                          height: height.clamp(4.0, 160.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Flexible(
                          child: Text(
                            data['hari'],
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Flexible(
                          child: Text(
                            '${((data['pendapatan'] as int) / 1000).toStringAsFixed(0)}k',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
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

  Widget _buildTransaksiCODCard() {
    if (transaksiCOD.isEmpty) {
      return _buildEmptyState('Tidak ada transaksi COD yang perlu diverifikasi');
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: transaksiCOD.map((transaksi) {
          return _buildTransaksiCODItem(transaksi);
        }).toList(),
      ),
    );
  }

  Widget _buildTransaksiCODItem(Map<String, dynamic> transaksi) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
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
                      transaksi['customerName'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Kurir: ${transaksi['kurir']}',
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
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Belum Diverifikasi',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jumlah: Rp ${_formatCurrency(transaksi['jumlah'])}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tanggal: ${_formatDate(transaksi['tanggal'])}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (transaksi['buktiPembayaran'] != null)
                    IconButton(
                      icon: const Icon(Icons.image, color: Colors.blue),
                      onPressed: () => _lihatBuktiPembayaran(transaksi),
                      tooltip: 'Lihat Bukti',
                    ),
                  ElevatedButton.icon(
                    onPressed: () => _verifikasiTransaksiCOD(transaksi),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Verifikasi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringSection() {
    return Column(
      children: [
        // Monitoring Kasir
        Card(
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
                  children: [
                    Icon(Icons.point_of_sale, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Kasir',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...dataKasir.map((kasir) => _buildMonitoringItem(
                      kasir['nama'],
                      '${kasir['transaksiHariIni']} transaksi hari ini',
                      kasir['status'],
                    )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Monitoring Kurir
        Card(
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
                  children: [
                    Icon(Icons.local_shipping, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Kurir',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...dataKurir.map((kurir) => _buildMonitoringItem(
                      kurir['nama'],
                      '${kurir['orderHariIni']} order hari ini',
                      kurir['status'],
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonitoringItem(String nama, String info, String status) {
    Color statusColor = status == 'Aktif' ? Colors.green : Colors.grey;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  info,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
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
  Future<void> _downloadLaporanPdf() async {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    if (selectedPeriod == 'Harian') {
      startDate = DateTime(now.year, now.month, now.day);
    } else {
      // Bulanan
      startDate = DateTime(now.year, now.month, 1);
    }

    try {
      // Calculate totals based on period
      final double revenue = selectedPeriod == 'Harian' ? pendapatanHarian : pendapatanBulanan;
      
      await PdfService().generateLaporanPdf(
        title: 'Laporan FMS ($selectedPeriod)',
        startDate: startDate,
        endDate: endDate,
        // Note: Use total count from state if available, otherwise estimate or 0
        totalOrders: totalTransaksiCount, 
        totalPendapatan: revenue.toInt(),
        ordersSelesai: 0, // Placeholder as we don't have exact count for period
        ordersDiproses: transaksiCODBelumDiverifikasi,
        ordersPending: 0,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _lihatLaporan() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Laporan FMS'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLaporanItem('Total Omzet', 'Rp ${_formatCurrency(totalOmzet)}'),
              _buildLaporanItem('Pendapatan Harian', 'Rp ${_formatCurrency(pendapatanHarian)}'),
              _buildLaporanItem('Pendapatan Bulanan', 'Rp ${_formatCurrency(pendapatanBulanan)}'),
              _buildLaporanItem('Transaksi COD Belum Diverifikasi', transaksiCODBelumDiverifikasi.toString()),
              _buildLaporanItem('Total Kasir Aktif', dataKasir.length.toString()),
              _buildLaporanItem('Total Kurir Aktif', dataKurir.length.toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              
              // Get date range for report
              final now = DateTime.now();
              final startDate = DateTime(now.year, now.month, 1);
              final endDate = now;
              
              try {
                await PdfService().generateLaporanPdf(
                  title: 'Laporan FMS',
                  startDate: startDate,
                  endDate: endDate,
                  totalOrders: dataKasir.fold<int>(0, (sum, k) => sum + ((k['transaksiHariIni'] as int?) ?? 0)),
                  totalPendapatan: totalOmzet.toInt(),
                  ordersSelesai: (totalOmzet / 50000).round(),
                  ordersDiproses: transaksiCODBelumDiverifikasi,
                  ordersPending: 0,
                );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            icon: const Icon(Icons.download),
            label: const Text('Ekspor PDF'),
          ),
        ],
      ),
    );
  }

  Widget _buildLaporanItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _verifikasiPembayaran() {
    if (transaksiCOD.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada pembayaran yang perlu diverifikasi')),
      );
      return;
    }
    // Scroll ke section verifikasi
  }

  void _verifikasiTransaksiCOD(Map<String, dynamic> transaksi) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verifikasi Pembayaran COD'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID Transaksi: ${transaksi['id']}'),
            Text('Customer: ${transaksi['customerName']}'),
            Text('Kurir: ${transaksi['kurir']}'),
            Text('Jumlah: Rp ${_formatCurrency(transaksi['jumlah'])}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _prosesVerifikasiCOD(transaksi);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Verifikasi'),
          ),
        ],
      ),
    );
  }

  Future<void> _prosesVerifikasiCOD(Map<String, dynamic> transaksi) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Memverifikasi pembayaran...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final transaksiId = transaksi['id'] as String;
      final jumlah = (transaksi['jumlah'] as num).toDouble();

      // 1. Create pembayaran record with status 'lunas' for COD
      final pembayaran = Pembayaran(
        id: 'PBY_${DateTime.now().millisecondsSinceEpoch}',
        transaksiId: transaksiId,
        jumlah: jumlah,
        tanggalBayar: DateTime.now(),
        metodePembayaran: 'cod',
        status: 'lunas',
        buktiPembayaran: transaksi['buktiPembayaran'] as String?,
      );
      await _transaksiService.createPembayaran(pembayaran);

      // 2. Update transaksi status to 'diterima'
      await _transaksiService.updateStatusTransaksi(
        transaksiId,
        'diterima',
      );

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // 3. Update local state
      setState(() {
        transaksiCOD.removeWhere((t) => t['id'] == transaksiId);
        transaksiCODBelumDiverifikasi = transaksiCOD.length;
      });

      // 4. Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran COD berhasil diverifikasi'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // 5. Reload data to ensure sync
      await _loadData();

    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      logger.e('Error verifying COD payment', error: e);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal verifikasi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  void _lihatBuktiPembayaran(Map<String, dynamic> transaksi) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bukti Pembayaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.image, size: 64, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Text('Transaksi: ${transaksi['id']}'),
            Text('Customer: ${transaksi['customerName']}'),
          ],
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

  // Helper Methods
  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Reset Riwayat Transaksi
  void _showResetRiwayatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[700], size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Reset Riwayat Transaksi',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: FutureBuilder<int>(
          future: _transaksiService.getTotalTransaksiCount(),
          builder: (context, snapshot) {
            final totalCount = snapshot.data ?? 0;
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.red[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tindakan ini akan menghapus SEMUA riwayat transaksi dan tidak dapat dibatalkan!',
                            style: TextStyle(
                              color: Colors.red[800],
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Data yang akan dihapus:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildResetInfoItem('Total Transaksi', '$totalCount transaksi'),
                  _buildResetInfoItem('Detail Laundry', 'Semua detail laundry'),
                  _buildResetInfoItem('Pembayaran', 'Semua data pembayaran'),
                  _buildResetInfoItem('Order Kurir', 'Semua order kurir'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock_outline, color: Colors.orange[700], size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Data pelanggan (customer) TIDAK akan dihapus',
                            style: TextStyle(
                              color: Colors.orange[800],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _konfirmasiResetRiwayat();
            },
            icon: const Icon(Icons.delete_forever, size: 18),
            label: const Text('Hapus Semua'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[900],
            ),
          ),
        ],
      ),
    );
  }

  void _konfirmasiResetRiwayat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700], size: 28),
            const SizedBox(width: 12),
            const Text(
              'Konfirmasi Akhir',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Apakah Anda YAKIN ingin menghapus SEMUA riwayat transaksi?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tindakan ini TIDAK DAPAT DIBATALKAN!',
                      style: TextStyle(
                        color: Colors.red[800],
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => _resetRiwayatTransaksi(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetRiwayatTransaksi() async {
    try {
      // Close confirmation dialog
      Navigator.pop(context);

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Menghapus riwayat transaksi...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Delete all transactions
      await _transaksiService.deleteAllTransaksi();

      // Close loading
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Semua riwayat transaksi berhasil dihapus'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Reload data
      await _loadData();
    } catch (e) {
      // Close loading if still open
      if (mounted) Navigator.pop(context);

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}

