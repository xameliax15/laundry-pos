import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pembayaran.dart';
import '../core/logger.dart';

/// Response dari pembuatan QRIS payment
class QrisPaymentResponse {
  final String qrisId;
  final String qrisString;
  final String qrisUrl;
  final DateTime expiredAt;
  final String orderId;
  final double amount;

  QrisPaymentResponse({
    required this.qrisId,
    required this.qrisString,
    required this.qrisUrl,
    required this.expiredAt,
    required this.orderId,
    required this.amount,
  });

  factory QrisPaymentResponse.fromMidtransJson(Map<String, dynamic> json) {
    final actions = json['actions'] as List<dynamic>?;
    String qrUrl = '';
    String qrString = '';
    
    if (actions != null) {
      for (final action in actions) {
        if (action['name'] == 'generate-qr-code') {
          qrUrl = action['url'] as String? ?? '';
        }
      }
    }
    
    // QR string from qr_string field
    qrString = json['qr_string'] as String? ?? '';

    return QrisPaymentResponse(
      qrisId: json['transaction_id'] as String? ?? json['order_id'] as String,
      qrisString: qrString,
      qrisUrl: qrUrl,
      expiredAt: DateTime.now().add(const Duration(minutes: 15)), // Default 15 minutes
      orderId: json['order_id'] as String,
      amount: (json['gross_amount'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'qris_id': qrisId,
    'qris_string': qrisString,
    'qris_url': qrisUrl,
    'expired_at': expiredAt.toIso8601String(),
    'order_id': orderId,
    'amount': amount,
  };
}

/// Service untuk mengelola pembayaran QRIS via Midtrans
class QrisService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Server key dari environment - akan diset di constructor atau via env
  QrisService();
  
  /// Initialize service dengan config dari Supabase
  Future<void> initialize() async {
    try {
      final response = await _supabase
          .from('payment_gateway_config')
          .select()
          .eq('gateway_name', 'midtrans')
          .eq('is_active', true)
          .maybeSingle();
      
      // Keys are handled by Edge Function, no need to store here
      // if (response != null) {
      //   _serverKey = response['server_key'] as String?;
      //   _clientKey = response['client_key'] as String?;
      // }
    } catch (e) {
      logError('Error loading payment gateway config: $e');
    }
  }

  /// Generate QRIS untuk pembayaran via Supabase Edge Function
  /// 
  /// Menggunakan Edge Function untuk menyembunyikan server key
  Future<QrisPaymentResponse> generateQris({
    required String transaksiId,
    required double amount,
    required String customerName,
    String? customerPhone,
    String? customerEmail,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'create-qris',
        body: {
          'transaksi_id': transaksiId,
          'amount': amount.toInt(), // Midtrans requires integer amount
          'customer_name': customerName,
          'customer_phone': customerPhone,
          'customer_email': customerEmail,
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to generate QRIS: ${response.data}');
      }

      final data = response.data as Map<String, dynamic>;
      return QrisPaymentResponse(
        qrisId: data['qris_id'] as String,
        qrisString: data['qris_string'] as String,
        qrisUrl: data['qris_url'] as String,
        expiredAt: DateTime.parse(data['expired_at'] as String),
        orderId: data['order_id'] as String,
        amount: (data['amount'] as num).toDouble(),
      );
    } catch (e) {
      throw Exception('Error generating QRIS: $e');
    }
  }

  /// Simpan data QRIS ke database
  Future<Pembayaran> saveQrisPayment({
    required String pembayaranId,
    required String transaksiId,
    required QrisPaymentResponse qrisResponse,
  }) async {
    final pembayaranData = {
      'id': pembayaranId,
      'transaksi_id': transaksiId,
      'jumlah': qrisResponse.amount,
      'tanggal_bayar': DateTime.now().toIso8601String(),
      'metode_pembayaran': 'qris',
      'status': 'pending',
      'qris_id': qrisResponse.qrisId,
      'qris_string': qrisResponse.qrisString,
      'qris_url': qrisResponse.qrisUrl,
      'qris_expired_at': qrisResponse.expiredAt.toIso8601String(),
      'payment_gateway': 'midtrans',
    };

    await _supabase.from('pembayaran').insert(pembayaranData);
    
    return Pembayaran.fromJson(pembayaranData);
  }

  /// Listen untuk status pembayaran real-time via Supabase Realtime
  Stream<Pembayaran?> listenPaymentStatus(String qrisId) {
    return _supabase
        .from('pembayaran')
        .stream(primaryKey: ['id'])
        .eq('qris_id', qrisId)
        .map((data) {
          if (data.isEmpty) return null;
          return Pembayaran.fromJson(data.first);
        });
  }

  /// Check status pembayaran dari database
  Future<String?> checkPaymentStatus(String qrisId) async {
    try {
      final response = await _supabase
          .from('pembayaran')
          .select('status')
          .eq('qris_id', qrisId)
          .maybeSingle();
      
      return response?['status'] as String?;
    } catch (e) {
      logError('Error checking payment status: $e');
      return null;
    }
  }

  /// Check status pembayaran dari Midtrans API (via Edge Function)
  Future<Map<String, dynamic>?> checkMidtransStatus(String orderId) async {
    try {
      final response = await _supabase.functions.invoke(
        'check-payment-status',
        body: {'order_id': orderId},
      );

      if (response.status == 200) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      logError('Error checking Midtrans status: $e');
      return null;
    }
  }

  /// Cancel QRIS payment yang belum dibayar
  Future<bool> cancelQrisPayment(String qrisId) async {
    try {
      await _supabase
          .from('pembayaran')
          .update({'status': 'cancelled'})
          .eq('qris_id', qrisId)
          .eq('status', 'pending');
      return true;
    } catch (e) {
      logError('Error cancelling QRIS payment: $e');
      return false;
    }
  }

  /// Update status pembayaran setelah expired
  Future<void> markAsExpired(String qrisId) async {
    try {
      await _supabase
          .from('pembayaran')
          .update({'status': 'expired'})
          .eq('qris_id', qrisId)
          .eq('status', 'pending');
    } catch (e) {
      logError('Error marking payment as expired: $e');
    }
  }

  /// Generate signature untuk verifikasi webhook Midtrans
  static String generateMidtransSignature({
    required String orderId,
    required String statusCode,
    required String grossAmount,
    required String serverKey,
  }) {
    final signatureKey = '$orderId$statusCode$grossAmount$serverKey';
    final bytes = utf8.encode(signatureKey);
    final digest = sha512.convert(bytes);
    return digest.toString();
  }

  /// Verify webhook signature dari Midtrans
  static bool verifyMidtransSignature({
    required String orderId,
    required String statusCode,
    required String grossAmount,
    required String serverKey,
    required String receivedSignature,
  }) {
    final expectedSignature = generateMidtransSignature(
      orderId: orderId,
      statusCode: statusCode,
      grossAmount: grossAmount,
      serverKey: serverKey,
    );
    return expectedSignature == receivedSignature;
  }
}
