import 'package:flutter/material.dart';
import '../models/transaksi.dart';
import '../services/transaksi_service.dart';
import '../theme/app_colors.dart';

/// Simple notification model for local notifications
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String type; // order_new, order_update, payment, delivery
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });

  IconData get icon {
    switch (type) {
      case 'order_new':
        return Icons.add_shopping_cart;
      case 'order_update':
        return Icons.update;
      case 'payment':
        return Icons.payments;
      case 'delivery':
        return Icons.local_shipping;
      default:
        return Icons.notifications;
    }
  }

  Color get color {
    switch (type) {
      case 'order_new':
        return Colors.green;
      case 'order_update':
        return Colors.blue;
      case 'payment':
        return Colors.orange;
      case 'delivery':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

/// Service for managing local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final TransaksiService _transaksiService = TransaksiService();

  /// Generate notifications from recent transactions
  Future<List<NotificationItem>> getRecentNotifications() async {
    final notifications = <NotificationItem>[];
    
    try {
      // Get recent transactions (last 24 hours)
      final allTransaksi = await _transaksiService.getAllTransaksi();
      final now = DateTime.now();
      final oneDayAgo = now.subtract(const Duration(hours: 24));
      
      final recentTransaksi = allTransaksi.where((t) => 
        t.tanggalMasuk.isAfter(oneDayAgo)
      ).toList();

      // Sort by date (newest first)
      recentTransaksi.sort((a, b) => b.tanggalMasuk.compareTo(a.tanggalMasuk));

      // Generate notifications from recent transactions
      for (var transaksi in recentTransaksi.take(10)) {
        notifications.add(_createNotificationFromTransaksi(transaksi));
      }

      // Add delivery notifications
      final deliveryTransaksi = allTransaksi.where((t) => 
        t.isDelivery && t.status == 'dikirim'
      ).toList();

      for (var transaksi in deliveryTransaksi.take(5)) {
        notifications.add(NotificationItem(
          id: 'delivery_${transaksi.id}',
          title: 'Pengiriman Aktif',
          message: 'Pesanan ${transaksi.customerName} sedang dikirim',
          timestamp: transaksi.tanggalMasuk,
          type: 'delivery',
        ));
      }

      // Sort all by timestamp
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return notifications.take(15).toList();
    } catch (e) {
      return [];
    }
  }

  NotificationItem _createNotificationFromTransaksi(Transaksi transaksi) {
    String type = 'order_update';
    String title = 'Update Pesanan';
    String message = '';

    switch (transaksi.status) {
      case 'pending':
        type = 'order_new';
        title = 'Pesanan Baru';
        message = 'Pesanan dari ${transaksi.customerName}';
        break;
      case 'proses':
        title = 'Pesanan Diproses';
        message = 'Pesanan ${transaksi.customerName} sedang diproses';
        break;
      case 'selesai':
        title = 'Pesanan Selesai';
        message = 'Pesanan ${transaksi.customerName} siap diambil';
        break;
      case 'dikirim':
        type = 'delivery';
        title = 'Pesanan Dikirim';
        message = 'Pesanan ${transaksi.customerName} dalam pengiriman';
        break;
      case 'diterima':
        type = 'delivery';
        title = 'Pesanan Diterima';
        message = 'Pesanan ${transaksi.customerName} telah diterima';
        break;
      default:
        message = 'Status: ${transaksi.status}';
    }

    return NotificationItem(
      id: 'transaksi_${transaksi.id}',
      title: title,
      message: message,
      timestamp: transaksi.tanggalMasuk,
      type: type,
    );
  }

  /// Show notification dialog
  static Future<void> showNotificationsDialog(BuildContext context) async {
    final service = NotificationService();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications, color: Colors.white),
                    const SizedBox(width: 12),
                    const Text(
                      'Notifikasi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Notification List
              Flexible(
                child: FutureBuilder<List<NotificationItem>>(
                  future: service.getRecentNotifications(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final notifications = snapshot.data ?? [];

                    if (notifications.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notifications_off, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'Tidak ada notifikasi',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final notif = notifications[index];
                        return _buildNotificationItem(notif);
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

  static Widget _buildNotificationItem(NotificationItem notif) {
    final timeAgo = _formatTimeAgo(notif.timestamp);
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: notif.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(notif.icon, color: notif.color, size: 24),
      ),
      title: Text(
        notif.title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notif.message, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 2),
          Text(
            timeAgo,
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
      isThreeLine: true,
    );
  }

  static String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Baru saja';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else {
      return '${diff.inDays} hari lalu';
    }
  }
}
