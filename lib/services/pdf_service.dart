import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfService {
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Generate and show PDF laporan
  Future<void> generateLaporanPdf({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required int totalOrders,
    required int totalPendapatan,
    required int ordersSelesai,
    required int ordersDiproses,
    required int ordersPending,
    List<Map<String, dynamic>>? detailTransaksi,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(title, startDate, endDate, dateFormat),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 20),
          
          // Summary Cards
          _buildSummarySection(
            totalOrders: totalOrders,
            totalPendapatan: totalPendapatan,
            ordersSelesai: ordersSelesai,
            ordersDiproses: ordersDiproses,
            ordersPending: ordersPending,
          ),
          
          pw.SizedBox(height: 30),
          
          // Detail Table if available
          if (detailTransaksi != null && detailTransaksi.isNotEmpty) ...[
            _buildDetailSection(detailTransaksi),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Laporan_${DateFormat('yyyyMMdd').format(startDate)}_${DateFormat('yyyyMMdd').format(endDate)}',
    );
  }

  pw.Widget _buildHeader(
    String title,
    DateTime startDate,
    DateTime endDate,
    DateFormat dateFormat,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'TRIAS LAUNDRY',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Periode:',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
              pw.Text(
                '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Dicetak: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Halaman ${context.pageNumber} dari ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
      ),
    );
  }

  pw.Widget _buildSummarySection({
    required int totalOrders,
    required int totalPendapatan,
    required int ordersSelesai,
    required int ordersDiproses,
    required int ordersPending,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'RINGKASAN LAPORAN',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: [
              _buildSummaryRow('Total Pesanan', '$totalOrders pesanan'),
              pw.Divider(color: PdfColors.grey300),
              _buildSummaryRow(
                'Total Pendapatan',
                _currencyFormat.format(totalPendapatan),
                isHighlight: true,
              ),
              pw.Divider(color: PdfColors.grey300),
              _buildSummaryRow('Pesanan Selesai', '$ordersSelesai pesanan', color: PdfColors.green700),
              pw.Divider(color: PdfColors.grey300),
              _buildSummaryRow('Pesanan Diproses', '$ordersDiproses pesanan', color: PdfColors.orange700),
              pw.Divider(color: PdfColors.grey300),
              _buildSummaryRow('Pesanan Pending', '$ordersPending pesanan', color: PdfColors.grey600),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSummaryRow(String label, String value, {bool isHighlight = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: isHighlight ? 14 : 11,
              fontWeight: isHighlight ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? (isHighlight ? PdfColors.blue800 : PdfColors.black),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDetailSection(List<Map<String, dynamic>> transactions) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'DETAIL TRANSAKSI',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(1),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1),
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blue50),
              children: [
                _buildTableCell('No. Order', isHeader: true),
                _buildTableCell('Pelanggan', isHeader: true),
                _buildTableCell('Total', isHeader: true),
                _buildTableCell('Status', isHeader: true),
              ],
            ),
            // Data rows
            ...transactions.take(20).map((tx) => pw.TableRow(
              children: [
                _buildTableCell(tx['order_number']?.toString() ?? '-'),
                _buildTableCell(tx['customer_name']?.toString() ?? '-'),
                _buildTableCell(_currencyFormat.format(tx['total'] ?? 0)),
                _buildTableCell(tx['status']?.toString() ?? '-'),
              ],
            )),
          ],
        ),
        if (transactions.length > 20)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 8),
            child: pw.Text(
              '... dan ${transactions.length - 20} transaksi lainnya',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
            ),
          ),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
