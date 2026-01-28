import 'package:flutter/material.dart';
import '../../models/transaksi.dart';
import '../../models/pembayaran.dart';
import '../../models/order_kurir.dart';
import '../../core/routes.dart' as AppRoutes;
import '../../core/logger.dart';
import '../../services/transaksi_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/sidebar_layout.dart';

// Extended model untuk order kurir dengan alamat
class OrderKurir {
  final Transaksi transaksi;
  final String alamat;
  final bool isCOD;
  final String? buktiPembayaran;

  OrderKurir({
    required this.transaksi,
    required this.alamat,
    this.isCOD = false,
    this.buktiPembayaran,
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

  List<OrderKurir> daftarOrder = [];

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
      final orderList = <OrderKurir>[];
      for (var orderKurir in orderKurirList) {
        // Load transaksi berdasarkan ID
        final transaksi = await _transaksiService.getTransaksiById(orderKurir.transaksiId);
        if (transaksi == null) continue;
        
        // Tampilkan transaksi siap kirim atau sedang dikirim
        if (transaksi.status != 'selesai' && transaksi.status != 'dikirim') continue;
        
        // Load customer untuk mendapatkan alamat
        final customer = await _transaksiService.getCustomerByTransaksiId(transaksi.id);
        final alamat = customer?.fullAddress ?? orderKurir.alamatPengiriman ?? 'Alamat belum tersedia';
        
        // Load bukti pembayaran COD jika ada
        final pembayaranCOD = await _transaksiService.getPembayaranCODByTransaksiId(transaksi.id);
        final buktiPembayaran = pembayaranCOD?.buktiPembayaran;
        
        orderList.add(OrderKurir(
          transaksi: transaksi,
          alamat: alamat,
          isCOD: orderKurir.isCOD,
          buktiPembayaran: buktiPembayaran,
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
    return SidebarLayout(
      title: 'Dashboard Kurir',
      items: [
        SidebarItem(
          label: 'Dashboard',
          icon: Icons.dashboard_rounded,
          isActive: true,
          onTap: () => Navigator.of(context)
              .pushReplacementNamed(AppRoutes.AppRoutes.kurirDashboard),
        ),
        SidebarItem(
          label: 'Riwayat Pesanan',
          icon: Icons.history,
          onTap: () => Navigator.of(context)
              .pushNamed(AppRoutes.AppRoutes.kurirRiwayat),
        ),
        SidebarItem(
          label: 'Keluar',
          icon: Icons.logout,
          isDestructive: true,
          onTap: () => AppRoutes.AppRoutes.logout(context),
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

  Widget _buildOrderCard(OrderKurir order) {
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
                    color: statusColor.withOpacity(0.1),
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

  void _updateStatus(OrderKurir order, String newStatus) async {
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

  void _terimaPembayaranCOD(OrderKurir order) {
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

  void _uploadBuktiPembayaran(OrderKurir order) {
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
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Membuka kamera...')),
                    );
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Kamera'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Membuka galeri...')),
                    );
                    // Simulasi upload
                    setState(() {
                      final index = daftarOrder.indexOf(order);
                      if (index != -1) {
                        daftarOrder[index] = OrderKurir(
                          transaksi: order.transaksi,
                          alamat: order.alamat,
                          isCOD: order.isCOD,
                          buktiPembayaran: 'uploaded',
                        );
                      }
                    });
                  },
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
}

