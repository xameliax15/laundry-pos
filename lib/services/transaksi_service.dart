import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../models/transaksi.dart';
import '../models/detail_laundry.dart';
import '../models/customer.dart';
import '../models/pembayaran.dart';
import '../models/order_kurir.dart';
import '../models/user.dart';
import '../database/database_helper.dart';
import '../core/constants.dart';
import '../core/transaction_fsm.dart';
import 'customer_service.dart';

class TransaksiService {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final CustomerService _customerService = CustomerService();
  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;

  DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    return DateTime.parse(value as String);
  }

  Transaksi _fromSupabase(Map<String, dynamic> json) {
    return Transaksi(
      id: json['id'] as String,
      customerId: json['customer_id'] as String?,
      customerName: json['customer_name'] as String,
      customerPhone: json['customer_phone'] as String? ?? '',
      tanggalMasuk: _parseDate(json['tanggal_masuk']),
      tanggalSelesai: json['tanggal_selesai'] != null
          ? _parseDate(json['tanggal_selesai'])
          : null,
      status: json['status'] as String,
      totalHarga: (json['total_harga'] as num).toDouble(),
      catatan: json['catatan'] as String?,
      isDelivery: json['is_delivery'] is bool
          ? json['is_delivery'] as bool
          : (json['is_delivery'] as int? ?? 0) == 1,
    );
  }

  DetailLaundry _detailFromSupabase(Map<String, dynamic> json) {
    return DetailLaundry(
      id: json['id'] as String,
      idTransaksi: json['id_transaksi'] as String,
      jenisLayanan: json['jenis_layanan'] as String,
      jenisBarang: json['jenis_barang'] as String,
      jumlah: (json['jumlah'] as num).toInt(),
      ukuran: json['ukuran'] as String?,
      berat: json['berat'] != null ? (json['berat'] as num).toDouble() : null,
      luas: json['luas'] != null ? (json['luas'] as num).toDouble() : null,
      catatan: json['catatan'] as String?,
      foto: json['foto'] as String?,
    );
  }

  Pembayaran _pembayaranFromSupabase(Map<String, dynamic> json) {
    return Pembayaran(
      id: json['id'] as String,
      transaksiId: json['transaksi_id'] as String,
      jumlah: (json['jumlah'] as num).toDouble(),
      tanggalBayar: _parseDate(json['tanggal_bayar']),
      metodePembayaran: json['metode_pembayaran'] as String,
      status: json['status'] as String,
      buktiPembayaran: json['bukti_pembayaran'] as String?,
    );
  }

  OrderKurir _orderKurirFromSupabase(Map<String, dynamic> json) {
    return OrderKurir(
      id: json['id'] as String,
      transaksiId: json['transaksi_id'] as String,
      kurirId: json['kurir_id'] as String,
      alamatPengiriman: json['alamat_pengiriman'] as String?,
      isCOD: json['is_cod'] == true || json['is_cod'] == 1,
      status: json['status'] as String,
      tanggalAssign: json['tanggal_assign'] != null
          ? _parseDate(json['tanggal_assign'])
          : null,
      tanggalSelesai: json['tanggal_selesai'] != null
          ? _parseDate(json['tanggal_selesai'])
          : null,
      catatan: json['catatan'] as String?,
    );
  }

  Map<String, dynamic> _toSupabase(Transaksi transaksi) {
    return {
      'id': transaksi.id,
      'customer_id': transaksi.customerId,
      'customer_name': transaksi.customerName,
      'customer_phone': transaksi.customerPhone,
      'tanggal_masuk': transaksi.tanggalMasuk.toIso8601String(),
      'tanggal_selesai': transaksi.tanggalSelesai?.toIso8601String(),
      'status': transaksi.status,
      'total_harga': transaksi.totalHarga,
      'catatan': transaksi.catatan,
      'is_delivery': transaksi.isDelivery,
    };
  }

  // Get all transactions
  Future<List<Transaksi>> getAllTransaksi() async {
    if (AppConstants.useSupabase) {
      final data = await _supabase
          .from('transaksi')
          .select()
          .order('tanggal_masuk', ascending: false);
      return data.map<Transaksi>((row) => _fromSupabase(row)).toList();
    }
    return await _db.getAllTransaksi();
  }

  // Get transaction by ID
  Future<Transaksi?> getTransaksiById(String id) async {
    if (AppConstants.useSupabase) {
      final data = await _supabase
          .from('transaksi')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (data == null) return null;
      return _fromSupabase(data);
    }
    return await _db.getTransaksiById(id);
  }

  // Get transactions by status
  Future<List<Transaksi>> getTransaksiByStatus(String status) async {
    if (AppConstants.useSupabase) {
      final data = await _supabase
          .from('transaksi')
          .select()
          .eq('status', status)
          .order('tanggal_masuk', ascending: false);
      return data.map<Transaksi>((row) => _fromSupabase(row)).toList();
    }
    return await _db.getTransaksiByStatus(status);
  }

  // Get transactions hari ini
  Future<List<Transaksi>> getTransaksiHariIni() async {
    if (AppConstants.useSupabase) {
      final start = DateTime.now();
      final startDay = DateTime(start.year, start.month, start.day);
      final endDay = DateTime(start.year, start.month, start.day, 23, 59, 59);
      final data = await _supabase
          .from('transaksi')
          .select()
          .gte('tanggal_masuk', startDay.toIso8601String())
          .lte('tanggal_masuk', endDay.toIso8601String())
          .order('tanggal_masuk', ascending: false);
      return data.map<Transaksi>((row) => _fromSupabase(row)).toList();
    }
    return await _db.getTransaksiHariIni();
  }

  // Create new transaction
  Future<Transaksi> createTransaksi(Transaksi transaksi) async {
    if (AppConstants.useSupabase) {
      await _supabase.from('transaksi').insert(_toSupabase(transaksi));
      return transaksi;
    }
    await _db.insertTransaksi(transaksi);
    return transaksi;
  }

  // Create transaction with detail laundry
  Future<Transaksi> createTransaksiWithDetail(
    Transaksi transaksi,
    List<DetailLaundry> detailList, {
    String? alamat,
    String? kelurahan,
    String? kecamatan,
    String? kota,
    String? kodePos,
  }) async {
    // Create or update customer
    final customer = await _customerService.createOrUpdateCustomer(
      name: transaksi.customerName,
      phone: transaksi.customerPhone,
      alamat: alamat,
      kelurahan: kelurahan,
      kecamatan: kecamatan,
      kota: kota,
      kodePos: kodePos,
    );

    // Update transaksi dengan customer_id
    final transaksiWithCustomer = Transaksi(
      id: transaksi.id,
      customerId: customer.id,
      customerName: transaksi.customerName,
      customerPhone: transaksi.customerPhone,
      tanggalMasuk: transaksi.tanggalMasuk,
      tanggalSelesai: transaksi.tanggalSelesai,
      status: transaksi.status,
      totalHarga: transaksi.totalHarga,
      catatan: transaksi.catatan,
      isDelivery: transaksi.isDelivery,
    );

    if (AppConstants.useSupabase) {
      await _supabase.from('transaksi').insert(_toSupabase(transaksiWithCustomer));
      if (detailList.isNotEmpty) {
        final detailPayload = detailList.map((detail) => detail.toJson()).toList();
        await _supabase.from('detail_laundry').insert(detailPayload);
      }
      return transaksiWithCustomer;
    }

    await _db.insertTransaksi(transaksiWithCustomer);
    for (var detail in detailList) {
      await _db.insertDetailLaundry(detail);
    }
    return transaksiWithCustomer;
  }

  // Get customer by transaksi ID
  Future<Customer?> getCustomerByTransaksiId(String transaksiId) async {
    if (AppConstants.useSupabase) {
      final transaksi = await getTransaksiById(transaksiId);
      final customerId = transaksi?.customerId;
      if (customerId == null || customerId.isEmpty) return null;
      final data = await _supabase
          .from('customer')
          .select()
          .eq('id', customerId)
          .maybeSingle();
      return data == null ? null : Customer.fromJson(data);
    }
    final transaksi = await _db.getTransaksiById(transaksiId);
    if (transaksi?.customerId != null) {
      return await _db.getCustomerById(transaksi!.customerId!);
    }
    return null;
  }

  // Get pembayaran by transaksi ID
  Future<List<Pembayaran>> getPembayaranByTransaksiId(String transaksiId) async {
    if (AppConstants.useSupabase) {
      final data = await _supabase
          .from('pembayaran')
          .select()
          .eq('transaksi_id', transaksiId)
          .order('tanggal_bayar', ascending: false);
      return data.map<Pembayaran>((row) => _pembayaranFromSupabase(row)).toList();
    }
    return await _db.getPembayaranByTransaksiId(transaksiId);
  }

  // Get pembayaran COD by transaksi ID
  Future<Pembayaran?> getPembayaranCODByTransaksiId(String transaksiId) async {
    if (AppConstants.useSupabase) {
      final data = await _supabase
          .from('pembayaran')
          .select()
          .eq('transaksi_id', transaksiId)
          .eq('metode_pembayaran', 'cod')
          .maybeSingle();
      return data == null ? null : _pembayaranFromSupabase(data);
    }
    return await _db.getPembayaranCODByTransaksiId(transaksiId);
  }

  // Create pembayaran
  Future<Pembayaran> createPembayaran(Pembayaran pembayaran) async {
    if (AppConstants.useSupabase) {
      await _supabase.from('pembayaran').insert(pembayaran.toJson());
      return pembayaran;
    }
    await _db.insertPembayaran(pembayaran);
    return pembayaran;
  }

  // Get order kurir by transaksi ID
  Future<OrderKurir?> getOrderKurirByTransaksiId(String transaksiId) async {
    if (AppConstants.useSupabase) {
      final data = await _supabase
          .from('order_kurir')
          .select()
          .eq('transaksi_id', transaksiId)
          .maybeSingle();
      return data == null ? null : _orderKurirFromSupabase(data);
    }
    return await _db.getOrderKurirByTransaksiId(transaksiId);
  }

  // Create order kurir
  Future<OrderKurir> createOrderKurir(OrderKurir orderKurir) async {
    if (AppConstants.useSupabase) {
      await _supabase.from('order_kurir').insert(orderKurir.toJson());
      return orderKurir;
    }
    await _db.insertOrderKurir(orderKurir);
    return orderKurir;
  }

  // Get users by role
  Future<List<User>> getUsersByRole(String role) async {
    if (AppConstants.useSupabase) {
      final data = await _supabase
          .from('users')
          .select()
          .eq('role', role)
          .order('username');
      return data.map<User>((row) => User.fromJson(row)).toList();
    }
    return await _db.getUsersByRole(role);
  }

  // Get user by ID
  Future<User?> getUserById(String id) async {
    if (AppConstants.useSupabase) {
      final data = await _supabase
          .from('users')
          .select()
          .eq('id', id)
          .maybeSingle();
      return data == null ? null : User.fromJson(data);
    }
    return await _db.getUserById(id);
  }

  // Get order kurir by kurir ID
  Future<List<OrderKurir>> getOrderKurirByKurirId(String kurirId) async {
    if (AppConstants.useSupabase) {
      final data = await _supabase
          .from('order_kurir')
          .select()
          .eq('kurir_id', kurirId)
          .order('tanggal_assign', ascending: false);
      return data.map<OrderKurir>((row) => _orderKurirFromSupabase(row)).toList();
    }
    return await _db.getOrderKurirByKurirId(kurirId);
  }

  // Update transaction
  Future<Transaksi> updateTransaksi(Transaksi transaksi) async {
    if (AppConstants.useSupabase) {
      final payload = _toSupabase(transaksi);
      payload.remove('id');
      await _supabase
          .from('transaksi')
          .update(payload)
          .eq('id', transaksi.id);
      return transaksi;
    }
    await _db.updateTransaksi(transaksi);
    return transaksi;
  }

  // Delete transaction
  Future<void> deleteTransaksi(String id) async {
    if (AppConstants.useSupabase) {
      // Delete related data first (cascade)
      await _supabase.from('detail_laundry').delete().eq('id_transaksi', id);
      await _supabase.from('pembayaran').delete().eq('transaksi_id', id);
      await _supabase.from('order_kurir').delete().eq('transaksi_id', id);
      // Delete transaction
      await _supabase.from('transaksi').delete().eq('id', id);
      return;
    }
    await _db.deleteDetailLaundryByTransaksiId(id);
    await _db.deleteTransaksi(id);
  }

  // Delete all transactions (Reset riwayat)
  // WARNING: This will delete ALL transactions and related data
  Future<void> deleteAllTransaksi() async {
    if (AppConstants.useSupabase) {
      // Get all transaction IDs first
      final transaksiList = await _supabase.from('transaksi').select('id');
      
      if (transaksiList.isNotEmpty) {
        final transaksiIds = transaksiList.map((t) => t['id'] as String).toList();
        
        // Delete all related data first
        for (var id in transaksiIds) {
          await _supabase.from('detail_laundry').delete().eq('id_transaksi', id);
          await _supabase.from('pembayaran').delete().eq('transaksi_id', id);
          await _supabase.from('order_kurir').delete().eq('transaksi_id', id);
        }
        
        // Delete all transactions
        for (var id in transaksiIds) {
          await _supabase.from('transaksi').delete().eq('id', id);
        }
      }
    } else {
      final db = await _db.database;
      // Delete all related data
      await db.delete('detail_laundry');
      await db.delete('pembayaran');
      await db.delete('order_kurir');
      // Delete all transactions
      await db.delete('transaksi');
    }
  }

  // Get total count of transactions
  Future<int> getTotalTransaksiCount() async {
    if (AppConstants.useSupabase) {
      // Get all transactions and count them
      final data = await _supabase.from('transaksi').select('id');
      return data.length;
    } else {
      final db = await _db.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM transaksi');
      return result.first['count'] as int? ?? 0;
    }
  }

  // Get detail laundry by transaksi ID
  Future<List<DetailLaundry>> getDetailLaundryByTransaksiId(String idTransaksi) async {
    if (AppConstants.useSupabase) {
      final data = await _supabase
          .from('detail_laundry')
          .select()
          .eq('id_transaksi', idTransaksi);
      return data.map<DetailLaundry>((row) => _detailFromSupabase(row)).toList();
    }
    return await _db.getDetailLaundryByTransaksiId(idTransaksi);
  }

  // Statistics
  Future<int> getTotalTransaksiHariIni() async {
    if (AppConstants.useSupabase) {
      final list = await getTransaksiHariIni();
      return list.length;
    }
    return await _db.getTotalTransaksiHariIni();
  }

  Future<double> getTotalPendapatanHariIni() async {
    if (AppConstants.useSupabase) {
      final list = await getTransaksiHariIni();
      return list.fold<double>(0.0, (sum, t) => sum + t.totalHarga);
    }
    return await _db.getTotalPendapatanHariIni();
  }

  Future<double> getTotalOmzet() async {
    if (AppConstants.useSupabase) {
      final list = await getAllTransaksi();
      return list.fold<double>(0.0, (sum, t) => sum + t.totalHarga);
    }
    return await _db.getTotalOmzet();
  }

  Future<double> getPendapatanByDate(DateTime date) async {
    if (AppConstants.useSupabase) {
      final start = DateTime(date.year, date.month, date.day);
      final end = DateTime(date.year, date.month, date.day, 23, 59, 59);
      final data = await _supabase
          .from('transaksi')
          .select()
          .gte('tanggal_masuk', start.toIso8601String())
          .lte('tanggal_masuk', end.toIso8601String());
      final list = data.map<Transaksi>((row) => _fromSupabase(row)).toList();
      return list.fold<double>(0.0, (sum, t) => sum + t.totalHarga);
    }
    return await _db.getPendapatanByDate(date);
  }

  Future<double> getPendapatanBulanan(int year, int month) async {
    if (AppConstants.useSupabase) {
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 0, 23, 59, 59);
      final data = await _supabase
          .from('transaksi')
          .select()
          .gte('tanggal_masuk', start.toIso8601String())
          .lte('tanggal_masuk', end.toIso8601String());
      final list = data.map<Transaksi>((row) => _fromSupabase(row)).toList();
      return list.fold<double>(0.0, (sum, t) => sum + t.totalHarga);
    }
    return await _db.getPendapatanBulanan(year, month);
  }

  // Get total pembayaran untuk transaksi
  Future<double> getTotalPembayaranByTransaksiId(String transaksiId) async {
    final pembayaranList = await getPembayaranByTransaksiId(transaksiId);
    double total = 0.0;
    for (var pembayaran in pembayaranList) {
      if (pembayaran.status == 'lunas') {
        total += pembayaran.jumlah;
      }
    }
    return total;
  }

  // Cek apakah transaksi sudah lunas
  Future<bool> isTransaksiLunas(String transaksiId) async {
    final transaksi = await getTransaksiById(transaksiId);
    if (transaksi == null) return false;
    
    final totalPembayaran = await getTotalPembayaranByTransaksiId(transaksiId);
    return totalPembayaran >= transaksi.totalHarga;
  }

  // Create pembayaran dan update status transaksi jika lunas
  Future<Pembayaran> createPembayaranAndUpdateStatus(Pembayaran pembayaran) async {
    // Simpan pembayaran
    await createPembayaran(pembayaran);
    // Status transaksi tidak berubah otomatis; diubah manual sesuai alur
    return pembayaran;
  }

  // Update status transaksi dengan validasi alur menggunakan FSM
  // Alur: pending -> proses -> selesai -> dikirim/diterima (jika delivery) -> diterima
  Future<Transaksi> updateStatusTransaksi(
    String transaksiId,
    String newStatus, {
    String? kurirId,
    bool isDelivery = false,
  }) async {
    final transaksi = await getTransaksiById(transaksiId);
    if (transaksi == null) {
      throw Exception('Transaksi tidak ditemukan');
    }

    // Inisialisasi FSM untuk validasi transisi
    final fsm = TransactionFSM(
      initialState: TransactionFSM.fromString(transaksi.status),
      isDelivery: transaksi.isDelivery,
    );

    // Validasi transisi menggunakan FSM
    final targetState = TransactionFSM.fromString(newStatus);
    if (!fsm.canTransitionTo(targetState)) {
      throw Exception(
        'Tidak dapat mengubah status dari "${transaksi.status}" ke "$newStatus". '
        'Transisi tidak valid menurut alur transaksi.',
      );
    }

    // Lakukan transisi di FSM (untuk logging/audit trail di masa depan)
    fsm.transitionTo(targetState);

    // Update transaksi
    final updatedTransaksi = Transaksi(
      id: transaksi.id,
      customerId: transaksi.customerId,
      customerName: transaksi.customerName,
      customerPhone: transaksi.customerPhone,
      tanggalMasuk: transaksi.tanggalMasuk,
      tanggalSelesai: (newStatus == 'selesai' || newStatus == 'dikirim' || newStatus == 'diterima')
          ? (transaksi.tanggalSelesai ?? DateTime.now())
          : transaksi.tanggalSelesai,
      status: TransactionFSM.stateToString(fsm.currentState), // Gunakan state dari FSM
      totalHarga: transaksi.totalHarga,
      catatan: transaksi.catatan,
      isDelivery: transaksi.isDelivery,
    );
    await updateTransaksi(updatedTransaksi);

    // Jika status menjadi 'selesai' dan delivery, buat OrderKurir (status transaksi tetap 'selesai')
    if (newStatus == 'selesai' && transaksi.isDelivery) {
      // Cek apakah sudah ada OrderKurir
      final existingOrder = await getOrderKurirByTransaksiId(transaksiId);
      if (existingOrder == null) {
        // Load customer untuk mendapatkan alamat
        final customer = await getCustomerByTransaksiId(transaksiId);
        final alamatPengiriman = customer?.fullAddress ?? 'Alamat belum tersedia';

        // Cek apakah COD (belum lunas)
        final isLunas = await isTransaksiLunas(transaksiId);
        final isCOD = !isLunas;

        // Jika kurirId tidak diberikan, ambil kurir pertama yang tersedia
        String finalKurirId = kurirId ?? '';
        if (finalKurirId.isEmpty) {
          final kurirList = await getUsersByRole('kurir');
          if (kurirList.isNotEmpty) {
            finalKurirId = kurirList.first.id;
          } else {
            throw Exception('Tidak ada kurir yang tersedia');
          }
        }

        // Buat OrderKurir
        final orderKurir = OrderKurir(
          id: 'ORD_${DateTime.now().millisecondsSinceEpoch}',
          transaksiId: transaksiId,
          kurirId: finalKurirId,
          alamatPengiriman: alamatPengiriman,
          isCOD: isCOD,
          status: 'assigned',
          tanggalAssign: DateTime.now(),
        );
        await createOrderKurir(orderKurir);
      }
    }

    // Jika status menjadi 'dikirim' dan isDelivery = true, buat OrderKurir (untuk manual update)
    if (newStatus == 'dikirim' && transaksi.isDelivery) {
      // Cek apakah sudah ada OrderKurir
      final existingOrder = await getOrderKurirByTransaksiId(transaksiId);
      if (existingOrder == null) {
        // Load customer untuk mendapatkan alamat
        final customer = await getCustomerByTransaksiId(transaksiId);
        final alamatPengiriman = customer?.fullAddress ?? 'Alamat belum tersedia';

        // Cek apakah COD (belum lunas)
        final isLunas = await isTransaksiLunas(transaksiId);
        final isCOD = !isLunas;

        // Jika kurirId tidak diberikan, ambil kurir pertama yang tersedia
        String finalKurirId = kurirId ?? '';
        if (finalKurirId.isEmpty) {
          final kurirList = await getUsersByRole('kurir');
          if (kurirList.isNotEmpty) {
            finalKurirId = kurirList.first.id;
          } else {
            throw Exception('Tidak ada kurir yang tersedia');
          }
        }

        // Buat OrderKurir
        final orderKurir = OrderKurir(
          id: 'ORD_${DateTime.now().millisecondsSinceEpoch}',
          transaksiId: transaksiId,
          kurirId: finalKurirId,
          alamatPengiriman: alamatPengiriman,
          isCOD: isCOD,
          status: 'assigned',
          tanggalAssign: DateTime.now(),
        );
        await createOrderKurir(orderKurir);
      }
    }

    return updatedTransaksi;
  }

  // Get available kurir (untuk assign order)
  Future<List<User>> getAvailableKurir() async {
    return await getUsersByRole('kurir');
  }

  // Get available next states menggunakan FSM
  // Helper method untuk UI yang ingin menampilkan opsi status berikutnya
  List<String> getAvailableNextStates(String currentStatus, bool isDelivery) {
    try {
      final fsm = TransactionFSM(
        initialState: TransactionFSM.fromString(currentStatus),
        isDelivery: isDelivery,
      );
      final nextStates = fsm.getNextStates();
      return nextStates.map<String>((state) => TransactionFSM.stateToString(state)).toList();
    } catch (e) {
      // Jika status tidak valid, return empty list
      return [];
    }
  }

  // Get available events menggunakan FSM
  // Helper method untuk event-driven approach (opsional)
  List<String> getAvailableEvents(String currentStatus, bool isDelivery) {
    try {
      final fsm = TransactionFSM(
        initialState: TransactionFSM.fromString(currentStatus),
        isDelivery: isDelivery,
      );
      final events = fsm.getAvailableEvents();
      return events.map((event) {
        switch (event) {
          case TransactionEvent.mulaiProses:
            return 'mulai_proses';
          case TransactionEvent.selesaikan:
            return 'selesaikan';
          case TransactionEvent.kirim:
            return 'kirim';
          case TransactionEvent.terima:
            return 'terima';
          case TransactionEvent.ambil:
            return 'ambil';
        }
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Cek apakah transisi valid menggunakan FSM
  // Helper method untuk validasi sebelum update
  bool canTransitionTo(String currentStatus, String newStatus, bool isDelivery) {
    try {
      final fsm = TransactionFSM(
        initialState: TransactionFSM.fromString(currentStatus),
        isDelivery: isDelivery,
      );
      final targetState = TransactionFSM.fromString(newStatus);
      return fsm.canTransitionTo(targetState);
    } catch (e) {
      return false;
    }
  }

  // Search transaksi
  Future<List<Transaksi>> searchTransaksi(String query) async {
    if (AppConstants.useSupabase) {
      final data = await _supabase
          .from('transaksi')
          .select()
          .or('customer_name.ilike.%$query%,customer_phone.ilike.%$query%')
          .order('tanggal_masuk', ascending: false);
      return data.map<Transaksi>((row) => _fromSupabase(row)).toList();
    }
    return await _db.searchTransaksi(query);
  }

  // Filter transaksi
  Future<List<Transaksi>> filterTransaksi({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? customerId,
  }) async {
    if (AppConstants.useSupabase) {
      var query = _supabase.from('transaksi').select();
      if (status != null && status.isNotEmpty) {
        query = query.eq('status', status);
      }
      if (customerId != null && customerId.isNotEmpty) {
        query = query.eq('customer_id', customerId);
      }
      if (startDate != null) {
        query = query.gte('tanggal_masuk', startDate.toIso8601String());
      }
      if (endDate != null) {
        final endDateTime = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        query = query.lte('tanggal_masuk', endDateTime.toIso8601String());
      }
      final data = await query.order('tanggal_masuk', ascending: false);
      return data.map<Transaksi>((row) => _fromSupabase(row)).toList();
    }
    return await _db.filterTransaksi(
      status: status,
      startDate: startDate,
      endDate: endDate,
      customerId: customerId,
    );
  }

  // Filter pembayaran
  Future<List<Pembayaran>> filterPembayaran({
    String? status,
    String? metodePembayaran,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (AppConstants.useSupabase) {
      var query = _supabase.from('pembayaran').select();
      if (status != null && status.isNotEmpty) {
        query = query.eq('status', status);
      }
      if (metodePembayaran != null && metodePembayaran.isNotEmpty) {
        query = query.eq('metode_pembayaran', metodePembayaran);
      }
      if (startDate != null) {
        query = query.gte('tanggal_bayar', startDate.toIso8601String());
      }
      if (endDate != null) {
        final endDateTime = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        query = query.lte('tanggal_bayar', endDateTime.toIso8601String());
      }
      final data = await query.order('tanggal_bayar', ascending: false);
      return data.map<Pembayaran>((row) => _pembayaranFromSupabase(row)).toList();
    }
    return await _db.filterPembayaran(
      status: status,
      metodePembayaran: metodePembayaran,
      startDate: startDate,
      endDate: endDate,
    );
  }
}

