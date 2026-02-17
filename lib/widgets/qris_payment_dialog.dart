import 'dart:async';
import 'package:flutter/material.dart';
import '../models/pembayaran.dart';
import '../models/transaksi.dart';
import '../services/qris_service.dart';

/// Dialog untuk menampilkan QR Code pembayaran QRIS
/// 
/// Dialog ini akan:
/// 1. Generate QRIS dari payment gateway
/// 2. Menampilkan QR Code
/// 3. Countdown timer sampai expired
/// 4. Listen real-time untuk status pembayaran
/// 5. Auto-close ketika pembayaran berhasil
class QrisPaymentDialog extends StatefulWidget {
  final Transaksi transaksi;
  final double amount;
  final VoidCallback? onPaymentSuccess;
  final VoidCallback? onPaymentExpired;
  final VoidCallback? onCancel;

  const QrisPaymentDialog({
    super.key,
    required this.transaksi,
    required this.amount,
    this.onPaymentSuccess,
    this.onPaymentExpired,
    this.onCancel,
  });

  @override
  State<QrisPaymentDialog> createState() => _QrisPaymentDialogState();
}

class _QrisPaymentDialogState extends State<QrisPaymentDialog> {
  final QrisService _qrisService = QrisService();
  
  QrisPaymentResponse? _qrisResponse;
  Pembayaran? _pembayaran;
  bool _isLoading = true;
  bool _isPaid = false;
  bool _isExpired = false;
  String? _errorMessage;
  
  Timer? _countdownTimer;
  Duration _remainingTime = Duration.zero;
  StreamSubscription? _paymentSubscription;

  @override
  void initState() {
    super.initState();
    _generateQris();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _paymentSubscription?.cancel();
    super.dispose();
  }

  Future<void> _generateQris() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Generate QRIS dari payment gateway
      final qrisResponse = await _qrisService.generateQris(
        transaksiId: widget.transaksi.id,
        amount: widget.amount,
        customerName: widget.transaksi.customerName,
        customerPhone: widget.transaksi.customerPhone,
      );

      // Simpan ke database
      final pembayaranId = 'PAY_${DateTime.now().millisecondsSinceEpoch}';
      final pembayaran = await _qrisService.saveQrisPayment(
        pembayaranId: pembayaranId,
        transaksiId: widget.transaksi.id,
        qrisResponse: qrisResponse,
      );

      setState(() {
        _qrisResponse = qrisResponse;
        _pembayaran = pembayaran;
        _isLoading = false;
        _remainingTime = qrisResponse.expiredAt.difference(DateTime.now());
      });

      // Start countdown timer
      _startCountdownTimer();

      // Listen for payment status updates
      _listenPaymentStatus(qrisResponse.qrisId);

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_qrisResponse == null) return;
      
      final remaining = _qrisResponse!.expiredAt.difference(DateTime.now());
      
      if (remaining.isNegative || remaining == Duration.zero) {
        setState(() {
          _isExpired = true;
          _remainingTime = Duration.zero;
        });
        timer.cancel();
        _handleExpired();
      } else {
        setState(() {
          _remainingTime = remaining;
        });
      }
    });
  }

  void _listenPaymentStatus(String qrisId) {
    _paymentSubscription = _qrisService
        .listenPaymentStatus(qrisId)
        .listen((pembayaran) {
          if (pembayaran != null && pembayaran.status == 'lunas') {
            setState(() {
              _isPaid = true;
              _pembayaran = pembayaran;
            });
            _handlePaymentSuccess();
          }
        });
  }

  void _handlePaymentSuccess() {
    _countdownTimer?.cancel();
    _paymentSubscription?.cancel();
    
    // Show success for 2 seconds before closing
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop(true);
        widget.onPaymentSuccess?.call();
      }
    });
  }

  void _handleExpired() {
    _paymentSubscription?.cancel();
    
    if (_pembayaran != null) {
      _qrisService.markAsExpired(_qrisResponse!.qrisId);
    }
    
    widget.onPaymentExpired?.call();
  }

  void _handleCancel() {
    if (_pembayaran != null && !_isPaid) {
      _qrisService.cancelQrisPayment(_qrisResponse!.qrisId);
    }
    Navigator.of(context).pop(false);
    widget.onCancel?.call();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildContent(),
              ),
            ),
            
            // Footer
            if (!_isPaid) _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isPaid 
              ? [Colors.green.shade600, Colors.green.shade400]
              : [Colors.blue.shade600, Colors.blue.shade400],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Icon(
            _isPaid ? Icons.check_circle : Icons.qr_code_2,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            _isPaid ? 'Pembayaran Berhasil!' : 'Scan untuk Bayar',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rp ${_formatCurrency(widget.amount)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generating QR Code...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 64),
            const SizedBox(height: 16),
            Text(
              'Gagal membuat QRIS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _generateQris,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_isPaid) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
                size: 80,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Pembayaran Diterima',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Terima kasih! Transaksi Anda telah berhasil.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    if (_isExpired) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.timer_off, color: Colors.orange.shade400, size: 64),
            const SizedBox(height: 16),
            const Text(
              'QR Code Expired',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Waktu pembayaran telah habis. Silakan generate QR baru.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _generateQris,
              icon: const Icon(Icons.refresh),
              label: const Text('Generate QR Baru'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // QR Code Display
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: _qrisResponse?.qrisUrl != null && _qrisResponse!.qrisUrl.isNotEmpty
              ? Image.network(
                  _qrisResponse!.qrisUrl,
                  width: 250,
                  height: 250,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      width: 250,
                      height: 250,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback: tampilkan QR string jika image gagal load
                    return Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code, size: 100, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              'QR Code tersedia',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
              : Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('QR Code tidak tersedia'),
                  ),
                ),
        ),
        
        const SizedBox(height: 20),
        
        // Countdown Timer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: _remainingTime.inMinutes < 2 
                ? Colors.red.shade50 
                : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer,
                size: 20,
                color: _remainingTime.inMinutes < 2 
                    ? Colors.red.shade700 
                    : Colors.blue.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Berlaku: ${_formatDuration(_remainingTime)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _remainingTime.inMinutes < 2 
                      ? Colors.red.shade700 
                      : Colors.blue.shade700,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Supported E-wallets
        Text(
          'Scan dengan aplikasi e-wallet atau mobile banking',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _buildEwalletBadge('GoPay', Colors.green),
            _buildEwalletBadge('OVO', Colors.purple),
            _buildEwalletBadge('DANA', Colors.blue),
            _buildEwalletBadge('ShopeePay', Colors.orange),
            _buildEwalletBadge('LinkAja', Colors.red),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Waiting indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.blue.shade400,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Menunggu pembayaran...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEwalletBadge(String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withAlpha(25), Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color.alphaBlend(color.withAlpha(76), Colors.white)),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _getDarkerColor(color),
        ),
      ),
    );
  }

  Color _getDarkerColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).toColor();
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: _handleCancel,
            icon: const Icon(Icons.close),
            label: const Text('Batal'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
            ),
          ),
          if (!_isExpired && _qrisResponse != null)
            ElevatedButton.icon(
              onPressed: () async {
                // Manual check status
                final status = await _qrisService.checkPaymentStatus(
                  _qrisResponse!.qrisId,
                );
                if (status == 'lunas') {
                  setState(() => _isPaid = true);
                  _handlePaymentSuccess();
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pembayaran belum diterima'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Cek Status'),
            ),
        ],
      ),
    );
  }
}
