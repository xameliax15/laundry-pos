import 'package:flutter/material.dart';
import '../../models/customer.dart';
import '../../services/customer_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'kasir_dashboard.dart';
import '../../core/routes.dart';

import '../../widgets/sidebar_layout.dart';

class KasirPelangganPage extends StatefulWidget {
  const KasirPelangganPage({super.key});

  @override
  State<KasirPelangganPage> createState() => _KasirPelangganPageState();
}

class _KasirPelangganPageState extends State<KasirPelangganPage> {
  final CustomerService _customerService = CustomerService();
  List<Customer> _customers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
      _onSearchChanged();
    });
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      final customers = await _customerService.getAllCustomers();
      setState(() {
        _customers = customers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _onSearchChanged() async {
    if (_searchQuery.isEmpty) {
      _loadCustomers();
      return;
    }
    setState(() => _isLoading = true);
    try {
      final results = await _customerService.searchCustomer(_searchQuery);
      setState(() {
        _customers = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddEditDialog([Customer? customer]) {
    final nameController = TextEditingController(text: customer?.name ?? '');
    final phoneController = TextEditingController(text: customer?.phone ?? '');
    final addressController = TextEditingController(text: customer?.alamat ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer == null ? 'Tambah Pelanggan' : 'Edit Pelanggan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'No. HP'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Alamat'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || phoneController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama dan No. HP wajib diisi')),
                );
                return;
              }
              
              Navigator.pop(context); // Close dialog first based on typical UX, then load
              
              // Show loading? Or just refresh after
              try {
                await _customerService.createOrUpdateCustomer(
                  name: nameController.text,
                  phone: phoneController.text,
                  alamat: addressController.text,
                );
                _loadCustomers(); // Reload list
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text(customer == null ? 'Pelanggan ditambahkan' : 'Data diperbarui')),
                  );
                }
              } catch (e) {
                if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
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
      title: 'Data Pelanggan',
      items: [
         SidebarItem(
          label: 'Dashboard',
          icon: Icons.dashboard_rounded,
          onTap: () => Navigator.of(context).pushReplacementNamed(AppRoutes.kasirDashboard),
        ),
        SidebarItem(
          label: 'Orders',
          icon: Icons.list_alt,
          onTap: () => Navigator.of(context).pushReplacementNamed(AppRoutes.kasirRiwayat, arguments: 'active'),
        ),
        SidebarItem(
          label: 'Customer',
          icon: Icons.people,
          isActive: true,
          onTap: () {}, // Already here
        ),
        SidebarItem(
          label: 'History',
          icon: Icons.history,
          onTap: () => Navigator.of(context).pushReplacementNamed(AppRoutes.kasirRiwayat, arguments: 'history'),
        ),
         SidebarItem(
          label: 'Keluar',
          icon: Icons.logout,
          isDestructive: true,
          onTap: () => AppRoutes.logout(context),
        ),
      ],
      headerActions: [
         IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _showAddEditDialog(),
          tooltip: 'Tambah Pelanggan',
        ),
      ],
      body: _buildContent(),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Pelanggan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _buildContent(),
      bottomNavigationBar: MobileBottomNavBar(
        currentIndex: 2, // Customers Index
        onTap: (index) {
          if (index == 0) {
             Navigator.of(context).pushReplacementNamed(AppRoutes.kasirDashboard);
          } else if (index == 1) {
             Navigator.of(context).pushReplacementNamed(AppRoutes.kasirOrders);
          } else if (index == 3) {
             Navigator.of(context).pushReplacementNamed(AppRoutes.kasirRiwayat);
          }
        },
        onFabTap: () => _showAddEditDialog(),
        fabIcon: Icons.person_add,
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
    return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama atau no. hp...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _customers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('Belum ada pelanggan', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _customers.length,
                        itemBuilder: (context, index) {
                          final cust = _customers[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.brandBlue.withValues(alpha: 0.1),
                              child: Text(
                                cust.name.isNotEmpty ? cust.name[0].toUpperCase() : '?',
                                style: TextStyle(color: AppColors.brandBlue),
                              ),
                            ),
                            title: Text(cust.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(cust.phone),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                              onPressed: () => _showAddEditDialog(cust),
                            ),
                            onTap: () => _showAddEditDialog(cust),
                          );
                        },
                      ),
          ),
        ],
      );
  }
}
