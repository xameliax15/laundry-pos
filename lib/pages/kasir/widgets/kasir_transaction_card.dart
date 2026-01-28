import 'package:flutter/material.dart';
import '../../../models/transaksi.dart';
import '../../../theme/app_colors.dart';

class KasirTransactionCard extends StatelessWidget {
  final Transaksi transaksi;
  final double totalPembayaran;
  final bool showActions;
  final Function(Transaksi)? onUpdateStatus;
  final Function(Transaksi)? onShowDetail;
  final Function(Transaksi)? onInputPembayaran;

  const KasirTransactionCard({
    required this.transaksi,
    required this.totalPembayaran,
    required this.showActions,
    this.onUpdateStatus,
    this.onShowDetail,
    this.onInputPembayaran,
  });

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

  String _formatStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'proses':
        return 'Diproses';
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatCurrency(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor = _getStatusColor(transaksi.status);
    final sisaBayar = transaksi.totalHarga - totalPembayaran;
    final isLunas = totalPembayaran >= transaksi.totalHarga;

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
            // Header
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

            // Time info
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

            // Catatan if exists
            if (transaksi.catatan != null && transaksi.catatan!.isNotEmpty) ...[
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

            // Payment status
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

            // Total price and actions
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
                      if (transaksi.status == 'pending' ||
                          transaksi.status == 'proses' ||
                          (transaksi.status == 'selesai' && !transaksi.isDelivery))
                        IconButton(
                          icon: const Icon(Icons.update, color: Colors.blue),
                          onPressed: () => onUpdateStatus?.call(transaksi),
                          tooltip: 'Update Status',
                        ),
                      IconButton(
                        icon: const Icon(Icons.list_alt, color: Colors.purple),
                        onPressed: () => onShowDetail?.call(transaksi),
                        tooltip: 'Detail',
                      ),
                      if (!isLunas)
                        IconButton(
                          icon: const Icon(Icons.payment, color: Colors.green),
                          onPressed: () => onInputPembayaran?.call(transaksi),
                          tooltip: 'Pembayaran',
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
}
