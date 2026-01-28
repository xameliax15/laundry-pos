import 'package:flutter/material.dart';
import '../../../models/transaksi.dart';
import '../../../models/detail_laundry.dart';
import '../../../theme/app_colors.dart';
import '../../../services/transaksi_service.dart';
import '../../../core/logger.dart';

class KasirStatsCard extends StatelessWidget {
  final int totalTransaksi;
  final double totalPendapatan;

  const KasirStatsCard({
    required this.totalTransaksi,
    required this.totalPendapatan,
  });

  String _formatCurrency(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
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
              totalTransaksi.toString(),
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
              'Rp ${_formatCurrency(totalPendapatan)}',
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
}
