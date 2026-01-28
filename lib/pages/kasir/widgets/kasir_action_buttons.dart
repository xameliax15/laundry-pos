import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class KasirActionButtons extends StatelessWidget {
  final VoidCallback onTerimaLaundry;
  final VoidCallback onInputPembayaran;
  final VoidCallback onDetailIsiLaundry;
  final VoidCallback onFilterPembayaran;
  final VoidCallback onCariCustomer;

  const KasirActionButtons({
    required this.onTerimaLaundry,
    required this.onInputPembayaran,
    required this.onDetailIsiLaundry,
    required this.onFilterPembayaran,
    required this.onCariCustomer,
  });

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTombol(
                'Terima Laundry',
                Icons.add_shopping_cart,
                AppColors.accentGreen,
                onTerimaLaundry,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTombol(
                'Input Pembayaran',
                Icons.payment,
                AppColors.brandBlue,
                onInputPembayaran,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTombol(
                'Detail Isi Laundry',
                Icons.list_alt,
                AppColors.accentOrange,
                onDetailIsiLaundry,
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
                onFilterPembayaran,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTombol(
                'Cari Customer',
                Icons.person_search,
                AppColors.deepBlue,
                onCariCustomer,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
