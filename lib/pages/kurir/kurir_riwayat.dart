import 'package:flutter/material.dart';
import '../../models/transaksi.dart';
import '../../core/routes.dart';
import '../../core/logger.dart';
import '../../services/transaksi_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/sidebar_layout.dart';

class KurirRiwayat extends StatefulWidget {
  const KurirRiwayat({super.key});

  @override
  State<KurirRiwayat> createState() => _KurirRiwayatState();
}

class _KurirRiwayatState extends State<KurirRiwayat> {
  bool isLoading = true;
  List<Transaksi> riwayatTransaksi = [];

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

      // Load semua transaksi yang sudah diterima (status diterima)
      final transaksiDiterima = await _transaksiService.getTransaksiByStatus('diterima');
      
      // Filter transaksi yang di-assign ke kurir ini
      // TODO: Implementasi filter berdasarkan kurir ID jika diperlukan
      
      setState(() {
        riwayatTransaksi = transaksiDiterima;
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
    return SidebarLayout(
      title: 'Riwayat Pengiriman',
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: riwayatTransaksi.isEmpty
                  ? Center(
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
                            'Belum ada riwayat pengiriman',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppColors.gray600,
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: riwayatTransaksi.length,
                      itemBuilder: (context, index) {
                        final transaksi = riwayatTransaksi[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.success,
                              child: const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              transaksi.customerName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Tanggal: ${_formatDate(transaksi.tanggalMasuk)}',
                            ),
                            trailing: Text(
                              'Rp ${_formatCurrency(transaksi.totalHarga)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.brandBlue,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}
