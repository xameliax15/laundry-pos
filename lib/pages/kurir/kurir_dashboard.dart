import 'package:flutter/material.dart';
import '../../models/transaksi.dart';
import '../../models/pembayaran.dart';
import '../../models/order_kurir.dart';
import '../../core/routes.dart';
import '../../core/logger.dart';
import '../../services/transaksi_service.dart';
import '../../services/auth_service.dart';
import '../../services/map_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/sidebar_layout.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../core/constants.dart';
import 'kurir_mobile_view.dart';

// Extended model untuk order kurir dengan alamat
class OrderKurirViewData {
  final Transaksi transaksi;
  final String alamat;
  final bool isCOD;
  final String? buktiPembayaran;
  final String? customerPhone;

  OrderKurirViewData({
    required this.transaksi,
    required this.alamat,
    this.isCOD = false,
    this.buktiPembayaran,
    this.customerPhone,
  });
}

class KurirDashboard extends StatefulWidget {
  const KurirDashboard({super.key});

  @override
  State<KurirDashboard> createState() => _KurirDashboardState();
}

class _KurirDashboardState extends State<KurirDashboard> {
  bool isLoading = true;
  int jumlahOrderHariIni = 0;
  int orderBelumSelesai = 0;

  List<OrderKurirViewData> daftarOrder = [];

  // Service
  final TransaksiService _transaksiService = TransaksiService();
  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;

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
      // Get current user (kurir)
      final currentUser = AuthService().getCurrentUser();
      if (currentUser == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Load order kurir yang di-assign ke kurir ini
      final orderKurirList = await _transaksiService.getOrderKurirByKurirId(currentUser.id);
      
      // Filter transaksi yang di-assign ke kurir ini
      final orderList = <OrderKurirViewData>[];
      for (var orderKurir in orderKurirList) {
        // Load transaksi berdasarkan ID
        final transaksi = await _transaksiService.getTransaksiById(orderKurir.transaksiId);
        if (transaksi == null) continue;
        
        // REMOVED FILTER: Tampilkan SEMUA order yang ada di tabel order_kurir
        // Logikanya: Kalau sudah ada di tabel order_kurir, berarti tugas kurir.
        // if (transaksi.status != 'selesai' && transaksi.status != 'dikirim') continue;
        
        // Load customer untuk mendapatkan alamat
        final customer = await _transaksiService.getCustomerByTransaksiId(transaksi.id);
        final alamat = customer?.fullAddress ?? orderKurir.alamatPengiriman ?? 'Alamat belum tersedia';
        
        // Load bukti pembayaran COD jika ada
        final pembayaranCOD = await _transaksiService.getPembayaranCODByTransaksiId(transaksi.id);
        final buktiPembayaran = pembayaranCOD?.buktiPembayaran;
        
        orderList.add(OrderKurirViewData(
          transaksi: transaksi,
          alamat: alamat,
          isCOD: orderKurir.isCOD,
          buktiPembayaran: buktiPembayaran,
          customerPhone: customer?.phone,
        ));
      }

      // Load transaksi hari ini untuk statistik
      final transaksiHariIni = await _transaksiService.getTransaksiHariIni();

      setState(() {
        daftarOrder = orderList;
        jumlahOrderHariIni = transaksiHariIni.length;
        orderBelumSelesai = orderList
            .where((o) => o.transaksi.status != 'diterima')
            .length;
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

  Widget _buildMobileLayout() {
    final currentUser = AuthService().getCurrentUser();
    final userName = currentUser?.username ?? 'Kurir';
    
    // Count completed and pending COD
    final completedOrders = daftarOrder.where((o) => o.transaksi.status == 'diterima').length;
    final pendingCOD = daftarOrder.where((o) => o.isCOD && o.buktiPembayaran == null).length;
    
    // Convert orders to Map for mobile view (FILTER diterima orders)
    final orderMaps = daftarOrder
        .where((o) => o.transaksi.status != 'diterima')
        .map((o) => {
      'id': o.transaksi.id,
      'customer_name': o.transaksi.customerName,
      'status': o.transaksi.status,
      'alamat_pengiriman': o.alamat,
      'customer_phone': o.customerPhone,
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : KurirMobileView(
                userName: userName,
                activeOrders: orderBelumSelesai,
                completedOrders: completedOrders,
                pendingCOD: pendingCOD,
                orders: orderMaps,
                onHistory: () => Navigator.of(context).pushNamed(AppRoutes.kurirRiwayat, arguments: 'history'),
                onReceivePayment: _terimaPembayaran,
                onSettings: () {},
                onSeeAllOrders: () => Navigator.of(context).pushNamed(AppRoutes.kurirOrders),
                onTapOrder: (order) {
                  // Find matching OrderKurir
                  final orderKurir = daftarOrder.firstWhere(
                    (o) => o.transaksi.id == order['id'],
                    orElse: () => daftarOrder.first,
                  );
                  _showOrderDetail(orderKurir);
                },
                onUpdateStatus: (order) {
                  final orderKurir = daftarOrder.firstWhere(
                    (o) => o.transaksi.id == order['id'],
                    orElse: () => daftarOrder.first,
                  );
                  final status = orderKurir.transaksi.status;
                  _updateStatus(orderKurir, status == 'selesai' ? 'dikirim' : 'diterima');
                },
                onRefresh: _loadData,
                onLogout: () => AppRoutes.logout(context),
              ),
      ),
      bottomNavigationBar: MobileBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            // Orders - pesanan yang sedang diproses
             Navigator.of(context).pushNamed(AppRoutes.kurirOrders);
          } else if (index == 2) {
            // History - pesanan yang sudah selesai
            Navigator.of(context).pushNamed(AppRoutes.kurirRiwayat);
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

  void _showOrderDetail(OrderKurirViewData order) {
    // Simple detail dialog for now
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(order.transaksi.customerName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alamat: ${order.alamat}'),
            Text('Status: ${order.transaksi.status}'),
            Text('Total: Rp ${_formatCurrency(order.transaksi.totalHarga)}'),
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

  Widget _buildDesktopLayout() {
    return SidebarLayout(
      title: 'Dashboard Kurir',
      items: [
        SidebarItem(
          label: 'Dashboard',
          icon: Icons.dashboard_rounded,
          isActive: true,
          onTap: () => Navigator.of(context)
              .pushReplacementNamed(AppRoutes.kurirDashboard),
        ),
        SidebarItem(
          label: 'Orders',
          icon: Icons.local_shipping_outlined,
          onTap: () => _showActiveOrdersDialog(),
        ),
        SidebarItem(
          label: 'Riwayat Pesanan',
          icon: Icons.history,
          onTap: () => Navigator.of(context)
              .pushNamed(AppRoutes.kurirRiwayat, arguments: 'history'),
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
                    // Statistik Card
                    _buildStatistikCard(),
                    const SizedBox(height: 20),

                    // Tombol Utama
                    _buildTombolUtama(),
                    const SizedBox(height: 20),

                    // Daftar Order yang Diantar
                    _buildSectionTitle('🚚 Daftar Order yang Diantar'),
                    const SizedBox(height: 12),
                    _buildDaftarOrder(),
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
              'Jumlah Order Hari Ini',
              jumlahOrderHariIni.toString(),
              Icons.local_shipping,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: const Color(0x4DFFFFFF),
          ),
          Expanded(
            child: _buildStatItem(
              'Order Belum Selesai',
              orderBelumSelesai.toString(),
              Icons.pending_actions,
              isWarning: orderBelumSelesai > 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, {bool isWarning = false}) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: isWarning ? AppColors.accentOrange : Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xE6FFFFFF),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTombolUtama() {
    return Row(
      children: [
        Expanded(
          child: _buildTombol(
            'Terima Pembayaran',
            Icons.payment,
            AppColors.accentGreen,
            _terimaPembayaran,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTombol(
            'Selesaikan Order',
            Icons.check_circle,
            AppColors.brandBlue,
            _selesaikanOrder,
          ),
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
                  'Ringkasan Kurir',
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
              Icons.local_shipping,
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

  Widget _buildDaftarOrder() {
    if (daftarOrder.isEmpty) {
      return _buildEmptyState('Tidak ada order yang perlu diantar');
    }

    return Column(
      children: daftarOrder.map((order) {
        return _buildOrderCard(order);
      }).toList(),
    );
  }

  Widget _buildOrderCard(OrderKurirViewData order) {
    Color statusColor = _getStatusColor(order.transaksi.status);
    final status = order.transaksi.status;
    final isSelesai = status == 'selesai';
    final isDikirim = status == 'dikirim';
    final isDiterima = status == 'diterima';
    bool hasBuktiPembayaran = order.buktiPembayaran != null;

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
            // Header dengan status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.transaksi.customerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            order.transaksi.customerPhone,
                            style: TextStyle(
                              fontSize: 14,
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
                    _formatStatus(order.transaksi.status),
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
            
            // Alamat
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📍 Alamat Pelanggan',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.alamat,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Info Order
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(order.transaksi.tanggalMasuk),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (order.isCOD) ...[
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.money, size: 12, color: Colors.orange[800]),
                        const SizedBox(width: 4),
                        Text(
                          'COD',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            if (order.transaksi.catatan != null) ...[
              const SizedBox(height: 8),
              Text(
                'Catatan: ${order.transaksi.catatan}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const Divider(height: 24),
            
            // Total dan Bukti Pembayaran
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: Rp ${_formatCurrency(order.transaksi.totalHarga)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                if (hasBuktiPembayaran)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green[800]),
                        const SizedBox(width: 4),
                        Text(
                          'Bukti Terupload',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[800],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Action Buttons
            if (!isDiterima) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (order.isCOD && !hasBuktiPembayaran) ? null : () => _updateStatus(
                        order,
                        isSelesai ? 'dikirim' : 'diterima',
                      ),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: Text(isSelesai ? 'Mulai Pengiriman' : 'Diterima'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (order.isCOD && !hasBuktiPembayaran) ? Colors.grey : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            
            // Tombol Pembayaran dan Upload
            if (order.isCOD && isDikirim) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _terimaPembayaranCOD(order),
                      icon: const Icon(Icons.payment, size: 18),
                      label: const Text('Terima Pembayaran COD'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: BorderSide(color: Colors.green),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            
            if (isDikirim && order.isCOD && !hasBuktiPembayaran) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _uploadBuktiPembayaran(order),
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: const Text('Upload Bukti Pembayaran'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
            Icon(Icons.local_shipping_outlined, size: 48, color: Colors.grey[400]),
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
  void _showActiveOrdersDialog() {
    // Filter only active orders (not completed/cancelled)
    final activeOrders = daftarOrder.where((order) {
      final status = order.transaksi.status.toLowerCase();
      return status != 'selesai' && 
             status != 'completed' && 
             status != 'cancelled' && 
             status != 'dibatalkan';
    }).toList();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_shipping, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Orders Aktif',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${activeOrders.length} Order',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Body - List of orders
              Expanded(
                child: activeOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada order aktif',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: activeOrders.length,
                        itemBuilder: (context, index) {
                          final order = activeOrders[index];
                          return _buildActiveOrderItem(order);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveOrderItem(OrderKurirViewData order) {
    final statusColor = _getStatusColor(order.transaksi.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Order icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.brandBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_shipping,
                color: AppColors.brandBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Order details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ORD-${order.transaksi.id.substring(0, 8)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.transaksi.customerName,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          order.alamat,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Open in Maps button
                  GestureDetector(
                    onTap: () => MapService.showMapOptions(
                      context, 
                      order.alamat,
                      customerName: order.transaksi.customerName,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.navigation, size: 14, color: AppColors.brandBlue),
                        const SizedBox(width: 4),
                        Text(
                          'Buka di Maps',
                          style: TextStyle(
                            color: AppColors.brandBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _formatStatus(order.transaksi.status),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Total
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rp ${_formatCurrency(order.transaksi.totalHarga)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.brandBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order.isCOD ? 'COD' : 'Transfer',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _terimaPembayaran() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terima Pembayaran'),
        content: const Text('Pilih order yang akan menerima pembayaran.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _selesaikanOrder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selesaikan Order'),
        content: const Text('Pilih order yang akan diselesaikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _updateStatus(OrderKurirViewData order, String newStatus) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: Text('Update status order menjadi "${_formatStatus(newStatus)}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Update status menggunakan method yang sudah ada validasi
                await _transaksiService.updateStatusTransaksi(
                  order.transaksi.id,
                  newStatus,
                );
                
                Navigator.pop(context);
                
                // Reload data dari database
                await _loadData();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Status berhasil diupdate menjadi ${_formatStatus(newStatus)}'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
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
    );
  }

  void _terimaPembayaranCOD(OrderKurirViewData order) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terima Pembayaran COD'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Order ID: ${order.transaksi.id}'),
            Text('Customer: ${order.transaksi.customerName}'),
            Text('Total: Rp ${_formatCurrency(order.transaksi.totalHarga)}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Jumlah yang Diterima',
                hintText: 'Masukkan jumlah pembayaran',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pembayaran COD berhasil diterima')),
              );
            },
            child: const Text('Terima'),
          ),
        ],
      ),
    );
  }

  void _uploadBuktiPembayaran(OrderKurirViewData order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Bukti Pembayaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Order ID: ${order.transaksi.id}'),
            const SizedBox(height: 16),
            const Text('Pilih sumber foto:'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _processUpload(order, ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Kamera'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _processUpload(order, ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galeri'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  Future<void> _processUpload(OrderKurirViewData order, ImageSource source) async {
    Navigator.pop(context); // Close dialog
    
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 70, 
        maxWidth: 1024,
      );

      if (image != null) {
        // Show loading
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mengupload bukti pembayaran...')),
        );

        // Upload image
        final storedPath = await _storeImage(
          image,
          'bukti_pembayaran',
          'bukti_pembayaran', // Remote folder name
          prefix: 'bukti',
        );

        // Save payment record
        final pembayaran = Pembayaran(
          id: '', // Will be generated by service
          transaksiId: order.transaksi.id,
          jumlah: order.transaksi.totalHarga, // Assuming full payment
          tanggalBayar: DateTime.now(),
          metodePembayaran: 'transfer', 
          status: 'lunas', 
          buktiPembayaran: storedPath,
        );
        
        await _transaksiService.createPembayaran(pembayaran);

        // Update UI
        if (!mounted) return;
        setState(() {
          final index = daftarOrder.indexOf(order);
          if (index != -1) {
            daftarOrder[index] = OrderKurirViewData(
              transaksi: order.transaksi,
              alamat: order.alamat,
              isCOD: false, // Update to paid
              buktiPembayaran: storedPath,
            );
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bukti pembayaran berhasil diupload'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error upload: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  Future<String> _uploadImageToSupabase(XFile image, String folder) async {
    final bytes = await image.readAsBytes();
    final ext = path.extension(image.name.isNotEmpty ? image.name : image.path);
    final safeExt = ext.isNotEmpty ? ext : '.jpg';
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$safeExt';
    final filePath = '$folder/$fileName';

    await _supabase.storage.from('images').uploadBinary(
          filePath,
          bytes,
          fileOptions: supabase.FileOptions(
            contentType: image.mimeType,
            upsert: false,
          ),
        );

    // Get public URL using the full file path including folder prefix
    // Supabase bucket is 'images', path is 'bukti_pembayaran/filename.jpg'
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
    // Fallback for local storage
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
    final savedImage = File(path.join(appDir.path, localFolder, fileName));
    await savedImage.parent.create(recursive: true);
    await File(image.path).copy(savedImage.path);
    return savedImage.path;
  }
}

