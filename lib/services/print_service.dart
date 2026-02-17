import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/transaksi.dart';
import '../core/logger.dart';

/// Service for printing receipts/struk
class PrintService {
  static final PrintService _instance = PrintService._internal();
  factory PrintService() => _instance;
  PrintService._internal();

  /// Print receipt for a transaction
  Future<void> printReceipt(BuildContext context, Transaksi transaksi) async {
    try {
      final pdf = await _generateReceiptPdf(transaksi);
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Struk_${transaksi.id.substring(0, 8)}',
      );
      
      logger.i('✓ Receipt printed for transaction ${transaksi.id}');
    } catch (e) {
      logger.e('Error printing receipt', error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mencetak struk: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Preview receipt before printing
  Future<void> previewReceipt(BuildContext context, Transaksi transaksi) async {
    try {
      final pdf = await _generateReceiptPdf(transaksi);
      
      if (context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: const Text('Preview Struk'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.print),
                    onPressed: () => printReceipt(context, transaksi),
                    tooltip: 'Print',
                  ),
                ],
              ),
              body: PdfPreview(
                build: (format) => pdf.save(),
                canChangePageFormat: false,
                canDebug: false,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      logger.e('Error previewing receipt', error: e);
    }
  }

  Future<pw.Document> _generateReceiptPdf(Transaksi transaksi) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(8),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Header
              pw.Text(
                'TRIAS LAUNDRY',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Jl. Contoh No. 123',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'Telp: 0812-3456-7890',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 8),
              
              // Transaction Info
              _buildInfoRow('No. Order', 'ORD-${transaksi.id.substring(0, 8)}'),
              _buildInfoRow('Tanggal', _formatDate(transaksi.tanggalMasuk)),
              _buildInfoRow('Pelanggan', transaksi.customerName),
              if (transaksi.customerPhone.isNotEmpty)
                _buildInfoRow('Telepon', transaksi.customerPhone),
              
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 8),
              
              // Notes if available
              if (transaksi.catatan != null && transaksi.catatan!.isNotEmpty) ...[
                pw.Text(
                  'CATATAN',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  transaksi.catatan!,
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 4),
              ],
              
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 4),
              
              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Rp ${_formatCurrency(transaksi.totalHarga)}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              pw.SizedBox(height: 8),
              _buildInfoRow('Status', transaksi.status.toUpperCase()),
              if (transaksi.isDelivery)
                _buildInfoRow('Tipe', 'DELIVERY'),
              
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 8),
              
              // Footer
              pw.Text(
                'Terima kasih telah mempercayakan',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                'laundry Anda kepada kami!',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                _formatDateTime(DateTime.now()),
                style: const pw.TextStyle(fontSize: 8),
              ),
            ],
          );
        },
      ),
    );
    
    return pdf;
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  /// Show print options dialog
  static Future<void> showPrintDialog(BuildContext context, Transaksi transaksi) async {
    final service = PrintService();
    
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Cetak Struk',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.preview, color: Colors.blue),
              ),
              title: const Text('Preview'),
              subtitle: const Text('Lihat struk sebelum cetak'),
              onTap: () {
                Navigator.pop(context);
                service.previewReceipt(context, transaksi);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.print, color: Colors.green),
              ),
              title: const Text('Print Langsung'),
              subtitle: const Text('Cetak ke printer'),
              onTap: () {
                Navigator.pop(context);
                service.printReceipt(context, transaksi);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
