import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../models/customer.dart';
import '../database/database_helper.dart';
import '../core/constants.dart';

class CustomerService {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;

  Future<Customer?> getCustomerByPhone(String phone) async {
    if (AppConstants.useSupabase) {
      final data = await _supabase
          .from('customer')
          .select()
          .eq('phone', phone)
          .maybeSingle();
      return data == null ? null : Customer.fromJson(data);
    }
    return await _db.getCustomerByPhone(phone);
  }

  Future<Customer?> getCustomerById(String id) async {
    if (AppConstants.useSupabase) {
      final data = await _supabase
          .from('customer')
          .select()
          .eq('id', id)
          .maybeSingle();
      return data == null ? null : Customer.fromJson(data);
    }
    return await _db.getCustomerById(id);
  }

  Future<Customer> createOrUpdateCustomer({
    required String name,
    required String phone,
    String? alamat,
    String? kelurahan,
    String? kecamatan,
    String? kota,
    String? kodePos,
  }) async {
    // Jika alamat diberikan sebagai string lengkap, parse menjadi komponen
    if (alamat != null && alamat.isNotEmpty && kelurahan == null) {
      // Coba parse alamat dari format: "Jl. Contoh, Kel. X, Kec. Y, Kota Z, 12345"
      final parts = alamat.split(',');
      if (parts.length >= 1) {
        alamat = parts[0].trim();
      }
      if (parts.length >= 2) {
        final kelMatch = RegExp(r'Kel\.?\s*(.+)', caseSensitive: false).firstMatch(parts[1]);
        if (kelMatch != null) kelurahan = kelMatch.group(1)?.trim();
      }
      if (parts.length >= 3) {
        final kecMatch = RegExp(r'Kec\.?\s*(.+)', caseSensitive: false).firstMatch(parts[2]);
        if (kecMatch != null) kecamatan = kecMatch.group(1)?.trim();
      }
      if (parts.length >= 4) {
        kota = parts[3].trim();
      }
      if (parts.length >= 5) {
        kodePos = parts[4].trim();
      }
    }

    if (AppConstants.useSupabase) {
      final existing = await _supabase
          .from('customer')
          .select()
          .eq('phone', phone)
          .maybeSingle();

      final nowIso = DateTime.now().toIso8601String();
      if (existing != null) {
        final payload = {
          'name': name,
          'phone': phone,
          'alamat': alamat ?? existing['alamat'],
          'kelurahan': kelurahan ?? existing['kelurahan'],
          'kecamatan': kecamatan ?? existing['kecamatan'],
          'kota': kota ?? existing['kota'],
          'kode_pos': kodePos ?? existing['kode_pos'],
          'updated_at': nowIso,
        };
        final updated = await _supabase
            .from('customer')
            .update(payload)
            .eq('id', existing['id'])
            .select()
            .single();
        return Customer.fromJson(updated);
      }

      final customerId = 'CUST-${DateTime.now().millisecondsSinceEpoch}';
      final inserted = await _supabase.from('customer').insert({
        'id': customerId,
        'name': name,
        'phone': phone,
        'alamat': alamat,
        'kelurahan': kelurahan,
        'kecamatan': kecamatan,
        'kota': kota,
        'kode_pos': kodePos,
        'created_at': nowIso,
        'updated_at': nowIso,
      }).select().single();
      return Customer.fromJson(inserted);
    }

    // Cek apakah customer sudah ada berdasarkan phone
    var customer = await _db.getCustomerByPhone(phone);
    
    final now = DateTime.now();
    
    if (customer != null) {
      // Update customer yang sudah ada
      customer = Customer(
        id: customer.id,
        name: name,
        phone: phone,
        alamat: alamat ?? customer.alamat,
        kelurahan: kelurahan ?? customer.kelurahan,
        kecamatan: kecamatan ?? customer.kecamatan,
        kota: kota ?? customer.kota,
        kodePos: kodePos ?? customer.kodePos,
        createdAt: customer.createdAt,
        updatedAt: now,
      );
      await _db.updateCustomer(customer);
    } else {
      // Buat customer baru
      final customerId = 'CUST-${now.millisecondsSinceEpoch}';
      customer = Customer(
        id: customerId,
        name: name,
        phone: phone,
        alamat: alamat,
        kelurahan: kelurahan,
        kecamatan: kecamatan,
        kota: kota,
        kodePos: kodePos,
        createdAt: now,
        updatedAt: now,
      );
      await _db.insertCustomer(customer);
    }
    
    return customer;
  }

  // Search customer
  Future<List<Customer>> searchCustomer(String query) async {
    if (AppConstants.useSupabase) {
      final data = await _supabase
          .from('customer')
          .select()
          .or('name.ilike.%$query%,phone.ilike.%$query%')
          .order('created_at', ascending: false);
      return data.map<Customer>((row) => Customer.fromJson(row)).toList();
    }
    return await _db.searchCustomer(query);
  }

  // Get all customers
  Future<List<Customer>> getAllCustomers() async {
    if (AppConstants.useSupabase) {
      final data = await _supabase
          .from('customer')
          .select()
          .order('created_at', ascending: false);
      return data.map<Customer>((row) => Customer.fromJson(row)).toList();
    }
    return await _db.getAllCustomers();
  }
}

