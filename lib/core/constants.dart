import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // App Info
  static const String appVersion = '1.0.0';
  static String appName = dotenv.env['APP_NAME'] ?? 'Trias Laundry POS';

  // API Endpoints (jika menggunakan backend)
  static const String baseUrl = 'https://api.example.com';
  static const String loginEndpoint = '/auth/login';
  static const String transaksiEndpoint = '/transaksi';

  // Supabase Configuration (from .env file)
  static String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  static String supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static const bool useSupabase = true;

  // Local Storage Keys
  static const String userKey = 'user_data';
  static const String tokenKey = 'auth_token';
  static const String isLoggedInKey = 'is_logged_in';

  // User Roles
  static const String roleOwner = 'owner';
  static const String roleKasir = 'kasir';
  static const String roleKurir = 'kurir';

  // Transaction Status
  static const String statusPending = 'pending';
  static const String statusProses = 'proses';
  static const String statusSelesai = 'selesai';
  static const String statusDikirim = 'dikirim';
  static const String statusDiterima = 'diterima';

  // Payment Status
  static const String paymentPending = 'pending';
  static const String paymentLunas = 'lunas';
  static const String paymentBelumLunas = 'belum_lunas';
}




