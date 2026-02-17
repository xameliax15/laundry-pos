import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/app_providers.dart';
import 'components/dashboard_header.dart';
import 'widgets/kasir_stats_card.dart';
import 'widgets/kasir_action_buttons.dart';
import 'views/laundry_list_view.dart';
import '../../widgets/section_header.dart'; // Assuming this exists or I should create it/use generic Text
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
import '../../services/print_service.dart';
import '../../core/constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../theme/app_colors.dart';
import '../../widgets/sidebar_layout.dart';
import '../../widgets/qris_payment_dialog.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'kasir_mobile_view.dart';

class KasirDashboard extends StatefulWidget {
  const KasirDashboard({super.key});

  @override
  State<KasirDashboard> createState() => _KasirDashboardState();
}

class _KasirDashboardState extends State<KasirDashboard> {
  // Services
  final TransaksiService _transaksiService = TransaksiService();
  final CustomerService _customerService = CustomerService();
  final SupabaseClient _supabase = Supabase.instance.client;

  // Search Controller
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransaksiProvider>().loadDashboardData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransaksiProvider>(
      builder: (context, provider, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 768;
            
            if (isMobile) {
              return _buildMobileLayout(provider);
            } else {
              return _buildDesktopLayout(provider);
            }
          },
        );
      },
    );
  }

  Widget _buildMobileLayout(TransaksiProvider provider) {
    final user = context.read<AuthProvider>().currentUser;
    final userName = user?.username ?? 'Kasir';
    
    // Get pending payments (transaksi with pending payment status)
    // Filter out transactions that are already paid
    final pendingPayments = provider.transaksi
        .where((t) => (t.status == 'pending' || t.status == 'proses') && !provider.isPaid(t.id))
        .toList();
    
    // Get ready for pickup (selesai status)
    final readyForPickup = provider.transaksi
        .where((t) => t.status == 'selesai')
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : KasirMobileView(
                userName: userName,
                pendingCount: provider.transaksi.where((t) => t.status == 'pending').length,
                prosesCount: provider.transaksi.where((t) => t.status == 'proses').length,
                selesaiCount: provider.transaksi.where((t) => t.status == 'selesai').length,
                todayRevenue: provider.totalPendapatanHariIni,
                todayTransactions: provider.totalTransaksiHariIni,
                pendingPayments: pendingPayments,
                readyForPickup: readyForPickup,
                onNewOrder: _buatTransaksiBaru,
                onPayment: _inputPembayaran,
                onFindCustomer: _showSearchCustomerDialog,
                onViewAllPending: () => Navigator.of(context).pushNamed(AppRoutes.kasirRiwayat, arguments: 'pending'),
                onViewAllReady: () => Navigator.of(context).pushNamed(AppRoutes.kasirRiwayat, arguments: 'selesai'),
                onProcessPayment: (trx) => _pembayaranDiTempat(trx),
                onTapOrder: (trx) => _showDetailLaundry(trx),
                onPrintStruk: _cetakStruk, // New
                onRefresh: () => provider.refresh(),

                onLogout: () => AppRoutes.logout(context),
                onSearchChanged: (val) {
                  provider.setSearch(val);
                },
                onFilterTap: _showFilterDialog,
                isSearching: provider.searchQuery.isNotEmpty,
                searchResults: provider.transaksi,
              ),
      ),
      bottomNavigationBar: MobileBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).pushNamed(AppRoutes.kasirOrders); // Orders Page
          } else if (index == 2) {
            Navigator.of(context).pushNamed(AppRoutes.kasirPelanggan);
          } else if (index == 3) {
            Navigator.of(context).pushNamed(AppRoutes.kasirRiwayat); // History Page
          }
        },
        onFabTap: _buatTransaksiBaru,
        items: const [
          MobileNavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
          MobileNavItem(icon: Icons.shopping_bag_outlined, activeIcon: Icons.shopping_bag, label: 'Orders'),
          MobileNavItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Customers'),
          MobileNavItem(icon: Icons.history_outlined, activeIcon: Icons.history, label: 'History'),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(TransaksiProvider provider) {
    return SidebarLayout(
      title: 'Dashboard Kasir',
      headerActions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilterPembayaranDialog,
          tooltip: 'Filter',
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
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => provider.refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DashboardHeader(),
                    const SizedBox(height: 16),
                    // Search Bar
                    _buildSearchBar(provider),
                    const SizedBox(height: 16),

                    // Filter Info
                    if (provider.filterStatus != null || provider.filterStartDate != null || provider.filterEndDate != null)
                       _buildFilterInfo(provider),

                    // Statistik Card
                    KasirStatsCard(
                      totalTransaksi: provider.totalTransaksiHariIni,
                      totalPendapatan: provider.totalPendapatanHariIni,
                    ),
                    const SizedBox(height: 20),

                    // Tombol Utama
                    KasirActionButtons(
                      onTerimaLaundry: _terimaLaundry,
                      onInputPembayaran: _inputPembayaran,
                      onDetailIsiLaundry: _detailIsiLaundry,
                      onFilterPembayaran: _showFilterPembayaranDialog,
                      onCariCustomer: _showSearchCustomerDialog,
                    ),
                    const SizedBox(height: 20),

                    // Daftar Laundry Masuk
                    const SectionHeader(title: '📦 Daftar Laundry Masuk'),
                    const SizedBox(height: 12),
                    LaundryListView(
                      transaksiList: provider.transaksi,
                      isLoading: provider.isLoading,
                      onUpdateStatus: _showUpdateStatusDialog,
                      onShowDetail: _showDetailLaundry,
                      onInputPembayaran: _pembayaranDiTempat,
                      onCetakStruk: _cetakStruk,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSearchBar(TransaksiProvider provider) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Cari transaksi...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  provider.setSearch('');
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onChanged: (value) => provider.setSearch(value),
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
            constraints: BoxConstraints(
              maxWidth: 600,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
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
                                id: '${transaksiId}_$index',
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
                            await context.read<TransaksiProvider>().loadDashboardData();
                            
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
              isExpanded: true,
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
                  child: Text(
                    '${opsi['label']} - Rp ${(opsi['harga'] as double).toStringAsFixed(0)}/kg',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
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
                labelText: 'Berat (kg)',
                prefixIcon: const Icon(Icons.scale),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
                helperText: 'Bisa menggunakan koma (,) atau titik (.)',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                  if (value.isNotEmpty) {
                    final normalizedValue = value.replaceAll(',', '.');
                    final berat = double.tryParse(normalizedValue);
                    if (berat != null) {
                      item['berat'] = berat;
                      updateHarga();
                    }
                  }
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
                  child: Text('Standar - Rp ${PriceList.karpetStandar.toStringAsFixed(0)}/mÂ²'),
                ),
                DropdownMenuItem(
                  value: 'tipis',
                  child: Text('Tipis - Rp ${PriceList.karpetTipis.toStringAsFixed(0)}/mÂ²'),
                ),
                DropdownMenuItem(
                  value: 'tebal',
                  child: Text('Tebal/Mushola - Rp ${PriceList.karpetTebal.toStringAsFixed(0)}/mÂ²'),
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
            // Luas (mÂ²)
            TextField(
              controller: luasController,
              decoration: InputDecoration(
                labelText: 'Luas (mÂ²)',
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



  void _showFilterDialog() {
    final provider = context.read<TransaksiProvider>();
    String? selectedStatus = provider.filterStatus;
    DateTime? startDate = provider.filterStartDate;
    DateTime? endDate = provider.filterEndDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Transaksi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Status Transaksi:', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: selectedStatus,
                isExpanded: true,
                hint: const Text('Semua Status'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Semua')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'proses', child: Text('Sedang Proses')),
                  DropdownMenuItem(value: 'selesai', child: Text('Selesai / Siap Ambil')),
                  DropdownMenuItem(value: 'diterima', child: Text('Diterima & Lunas')),
                ],
                onChanged: (val) {
                  setDialogState(() => selectedStatus = val);
                },
              ),
              const SizedBox(height: 16),
              const Text('Rentang Tanggal:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2023),
                    lastDate: DateTime.now(),
                    initialDateRange: startDate != null && endDate != null
                        ? DateTimeRange(start: startDate!, end: endDate!)
                        : null,
                  );
                  if (picked != null) {
                    setDialogState(() {
                      startDate = picked.start;
                      endDate = picked.end;
                    });
                  }
                },
                icon: const Icon(Icons.date_range),
                label: Text(
                  startDate != null && endDate != null
                      ? '${DateFormat('dd/MM').format(startDate!)} - ${DateFormat('dd/MM').format(endDate!)}'
                      : 'Pilih Tanggal',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                 // Reset
                 provider.clearFilters();
                 Navigator.pop(context);
              },
              child: const Text('Reset', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                provider.setFilters(
                  status: selectedStatus,
                  startDate: startDate,
                  endDate: endDate,
                );
                Navigator.pop(context);
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
    final provider = context.read<TransaksiProvider>();
    if (provider.transaksi.isEmpty) {
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
            itemCount: provider.transaksi.length,
            itemBuilder: (context, index) {
              final transaksi = provider.transaksi[index];
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
    // Load detail dari provider atau database
    final provider = context.read<TransaksiProvider>();
    List<DetailLaundry> detailList = provider.getDetailsFor(transaksi.id);
    
    // Jika belum ada di provider (misal riwayat lama), load dari database
    if (detailList.isEmpty) {
      try {
        detailList = await _transaksiService.getDetailLaundryByTransaksiId(transaksi.id);
      } catch (e) {
        print('Error loading detail: $e');
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
                              color: Colors.white.withValues(alpha: 0.9),
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
                                                    'Luas: ${detail.luas} mÂ²',
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
                        await context.read<TransaksiProvider>().loadDashboardData();
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
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
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
                                  color: Colors.white.withValues(alpha: 0.9),
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
                        // Info QRIS gateway
                        if (metodePembayaran == 'qris') ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.qr_code_2, color: Colors.green[700]),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pembayaran QRIS',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[800],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'QR code akan ditampilkan setelah klik "Bayar dengan QRIS"',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // Upload bukti pembayaran (untuk transfer saja)
                        if (metodePembayaran == 'transfer') ...[
                          const SizedBox(height: 16),
                          Text(
                            'Bukti Pembayaran (Transfer Bank)',
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
                          if (metodePembayaran == 'transfer' && buktiPembayaranPath == null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Bukti pembayaran wajib diupload untuk transfer bank',
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
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }
                            
                            // Untuk QRIS, tampilkan QR Code dialog
                            if (metodePembayaran == 'qris') {
                              final jumlah = double.parse(jumlahController.text);
                              Navigator.pop(context); // Close payment form
                              
                              // Show QRIS payment dialog
                              final result = await showDialog<bool>(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => QrisPaymentDialog(
                                  transaksi: transaksi,
                                  amount: jumlah,
                                  onPaymentSuccess: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Pembayaran QRIS berhasil!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  },
                                ),
                              );
                              
                              // Reload data after QRIS dialog closes
                              if (result == true) {
                                await context.read<TransaksiProvider>().loadDashboardData();
                              }
                              return;
                            }
                            
                            // Validasi bukti untuk transfer
                            if (metodePembayaran == 'transfer' && buktiPembayaranPath == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Bukti pembayaran wajib diupload untuk transfer bank'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            try {
                              final jumlah = double.parse(jumlahController.text);
                              
                              // Buat pembayaran (untuk cash dan transfer)
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
                              await context.read<TransaksiProvider>().loadDashboardData();
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
                            backgroundColor: metodePembayaran == 'qris' 
                                ? Colors.green 
                                : Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          icon: Icon(metodePembayaran == 'qris' 
                              ? Icons.qr_code_2 
                              : Icons.payment),
                          label: Text(metodePembayaran == 'qris' 
                              ? 'Bayar dengan QRIS' 
                              : 'Simpan Pembayaran'),
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
    PrintService.showPrintDialog(context, transaksi);
  }



  Widget _buildFilterInfo(TransaksiProvider provider) {
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
                    if (provider.filterStatus != null)
                      Chip(
                        label: Text('Status: ${_formatStatus(provider.filterStatus!)}'),
                        backgroundColor: Colors.blue[100],
                        labelStyle: const TextStyle(fontSize: 11),
                        onDeleted: () {
                          provider.setFilters(
                             status: null, 
                             startDate: provider.filterStartDate, 
                             endDate: provider.filterEndDate
                          );
                        },
                      ),
                    if (provider.filterStartDate != null || provider.filterEndDate != null)
                      Chip(
                        label: Text(
                          provider.filterStartDate != null && provider.filterEndDate != null
                              ? 'Tanggal: ${_formatDate(provider.filterStartDate!)} - ${_formatDate(provider.filterEndDate!)}'
                              : provider.filterStartDate != null
                                  ? 'Dari: ${_formatDate(provider.filterStartDate!)}'
                                  : 'Sampai: ${_formatDate(provider.filterEndDate!)}',
                        ),
                        backgroundColor: Colors.blue[100],
                        labelStyle: const TextStyle(fontSize: 11),
                        onDeleted: () {
                          provider.setFilters(
                            status: provider.filterStatus,
                            startDate: null,
                            endDate: null,
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              provider.clearFilters();
            },
            child: const Text('Hapus Filter'),
          ),
        ],
      ),
    );
  }

  void _showFilterPembayaranDialog() async {
    final provider = context.read<TransaksiProvider>();
    String? selectedStatus = provider.filterStatus; 
    DateTime? startDate = provider.filterStartDate;
    DateTime? endDate = provider.filterEndDate;

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
                provider.setFilters(
                  status: selectedStatus,
                  startDate: startDate,
                  endDate: endDate,
                );
                Navigator.pop(context);
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
          label += ' (${detail.luas} mÂ²)';
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

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy HH:mm').format(date);
  }
  
  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return 'Pending';
      case 'proses': return 'Proses';
      case 'selesai': return 'Selesai';
      case 'diterima': return 'Diterima';
      case 'lunas': return 'Lunas';
      case 'belum_lunas': return 'Belum Lunas';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
     switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'proses': return Colors.blue;
      case 'selesai': return Colors.green;
      case 'diterima': return Colors.teal;
      case 'lunas': return Colors.green;
      case 'belum_lunas': return Colors.orange;
      default: return Colors.grey;
    }
  }
}


