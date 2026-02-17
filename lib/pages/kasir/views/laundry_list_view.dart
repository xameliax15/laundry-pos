import 'package:flutter/material.dart';
import '../../../models/transaksi.dart';
import '../widgets/kasir_transaction_card.dart';
import '../widgets/empty_state_widget.dart';

class LaundryListView extends StatelessWidget {
  final List<Transaksi> transaksiList;
  final bool isLoading;
  final Function(Transaksi) onUpdateStatus;
  final Function(Transaksi) onShowDetail;
  final Function(Transaksi) onInputPembayaran;
  final Function(Transaksi) onCetakStruk;

  const LaundryListView({
    super.key,
    required this.transaksiList,
    required this.isLoading,
    required this.onUpdateStatus,
    required this.onShowDetail,
    required this.onInputPembayaran,
    required this.onCetakStruk,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (transaksiList.isEmpty) {
      return const EmptyStateWidget(
        message: 'Tidak ada laundry masuk',
        icon: Icons.inbox,
      );
    }

    return Column(
      children: transaksiList.map((transaksi) {
        return KasirTransactionCard(
          transaksi: transaksi,
          showActions: true,
          onUpdateStatus: onUpdateStatus,
          onShowDetail: onShowDetail,
          onInputPembayaran: onInputPembayaran,
          onCetakStruk: onCetakStruk,
        );
      }).toList(),
    );
  }
}
