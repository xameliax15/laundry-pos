import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../models/transaksi.dart';
import '../models/detail_laundry.dart';
import '../services/auth_service.dart';
import '../services/transaksi_service.dart';
import '../core/logger.dart';

/// Auth Provider - manage authentication state
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _currentUser;
  bool _isLoggedIn = false;
  bool _isLoading = false;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;

  /// Login dengan credentials
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.login(username, password);
      if (user != null) {
        _currentUser = user;
        _isLoggedIn = true;
        logger.i('✅ Login successful: ${user.username}');
        return true;
      }
      logger.w('⚠️ Login failed: invalid credentials');
      return false;
    } catch (e) {
      logger.e('Error during login', error: e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _authService.logout();
      _currentUser = null;
      _isLoggedIn = false;
      logger.i('✅ Logout successful');
    } catch (e) {
      logger.e('Error during logout', error: e);
    } finally {
      notifyListeners();
    }
  }

  /// Check if user has role
  bool hasRole(String role) => _currentUser?.role == role;

  /// Refresh user data
  Future<void> refreshUser() async {
    try {
      final user = _authService.getCurrentUser();
      _currentUser = user;
      notifyListeners();
    } catch (e) {
      logger.e('Error refreshing user', error: e);
    }
  }
}

/// Transaksi Provider - manage transaction data
class TransaksiProvider extends ChangeNotifier {
  final TransaksiService _transaksiService = TransaksiService();
  
  // Data
  List<Transaksi> _transaksi = [];
  bool _isLoading = false;
  String? _error;

  // Filter properties
  String _searchQuery = '';
  String? _filterStatus;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  // Stats
  int _totalTransaksiHariIni = 0;
  double _totalPendapatanHariIni = 0.0;
  
  // Detail cache
  final Map<String, List<DetailLaundry>> _detailLaundryMap = {};
  
  // Payment status cache
  final Set<String> _paidTransactionIds = {};

  // Getters
  List<Transaksi> get transaksi => _transaksi;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalTransaksiHariIni => _totalTransaksiHariIni;
  double get totalPendapatanHariIni => _totalPendapatanHariIni;
  
  // Filter Getters
  String? get filterStatus => _filterStatus;
  DateTime? get filterStartDate => _filterStartDate;
  DateTime? get filterEndDate => _filterEndDate;
  String get searchQuery => _searchQuery;
  
  // Method to get details
  List<DetailLaundry> getDetailsFor(String transaksiId) => _detailLaundryMap[transaksiId] ?? [];

  // Check if transaction is paid
  bool isPaid(String transaksiId) => _paidTransactionIds.contains(transaksiId);

  /// Initial Load Data
  Future<void> loadDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Load Stats
      _totalTransaksiHariIni = await _transaksiService.getTotalTransaksiHariIni();
      _totalPendapatanHariIni = await _transaksiService.getTotalPendapatanHariIni();

      // 2. Load Transaksi based on filters
      await _applyFilters();

    } catch (e) {
      _error = e.toString();
      logger.e('Error loading dashboard data', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set Filters
  void setFilters({
    String? query,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (query != null) _searchQuery = query;
    // Allow clearing filters by passing null, but we need a way to distinguish "don't change" vs "clear"
    // For now, let's assume we pass the new state completely or utilize individual setters if needed.
    // To keep it simple: matches the UI logic.
    _filterStatus = status; 
    _filterStartDate = startDate;
    _filterEndDate = endDate;
    
    // Reload with new filters
    loadDashboardData();
  }
  
  void setSearch(String query) {
    _searchQuery = query;
    loadDashboardData();
  }
  
  void clearFilters() {
    _searchQuery = '';
    _filterStatus = null;
    _filterStartDate = null;
    _filterEndDate = null;
    loadDashboardData();
  }

  /// Internal: Apply all filters logic
  Future<void> _applyFilters() async {
    List<Transaksi> results = [];

    // Case 1: Search is active
    if (_searchQuery.isNotEmpty) {
      results = await _transaksiService.searchTransaksi(_searchQuery);
      
      // Apply additional filters locally if needed
      if (_filterStatus != null || _filterStartDate != null || _filterEndDate != null) {
        results = results.where((t) {
          if (_filterStatus != null && t.status != _filterStatus) return false;
          if (_filterStartDate != null && t.tanggalMasuk.isBefore(_filterStartDate!)) return false;
          if (_filterEndDate != null) {
            final endDate = DateTime(_filterEndDate!.year, _filterEndDate!.month, _filterEndDate!.day, 23, 59, 59);
            if (t.tanggalMasuk.isAfter(endDate)) return false;
          }
          return true;
        }).toList();
      }
    } 
    // Case 2: Only Filters (Server-side optimization possible, but service might support it)
    else if (_filterStatus != null || _filterStartDate != null || _filterEndDate != null) {
      results = await _transaksiService.filterTransaksi(
        status: _filterStatus,
        startDate: _filterStartDate,
        endDate: _filterEndDate,
      );
    } 
    // Case 3: Default View (Laundry Masuk: Pending & Proses)
    else {
      final pending = await _transaksiService.getTransaksiByStatus('pending');
      final proses = await _transaksiService.getTransaksiByStatus('proses');
      results = [...pending, ...proses];
      
      // Also load history for today separately if we want to show it in a specific section, 
      // but for "laundryMasuk" usually we want active ones. 
      // The dashboard showed "Laundry Masuk" and "Riwayat". 
      // Let's stick to what the dashboard displayed as main list: Laundry Masuk.
    }

    _transaksi = results;
    
    // Load Details and Payment Status for visible items
    await _loadDetailsForList(results);
    await _checkPaymentStatusForList(results);
  }

  Future<void> _checkPaymentStatusForList(List<Transaksi> list) async {
    for (var t in list) {
      if (!_paidTransactionIds.contains(t.id)) {
        final isLunas = await _transaksiService.isTransaksiLunas(t.id);
        if (isLunas) {
          _paidTransactionIds.add(t.id);
        }
      }
    }
  }

  Future<void> _loadDetailsForList(List<Transaksi> list) async {
    for (var t in list) {
       if (!_detailLaundryMap.containsKey(t.id)) {
         final details = await _transaksiService.getDetailLaundryByTransaksiId(t.id);
         _detailLaundryMap[t.id] = details;
       }
    }
  }

  /// Load transaksi dengan status (Compatibility)
  Future<void> loadTransaksiByStatus(String status) async {
    // ... existing logic can remain or redirect to new logic ...
    // keeping it simple for now, just calling internal logic but strictly for status
    _isLoading = true;
    notifyListeners();
    try {
      _transaksi = await _transaksiService.getTransaksiByStatus(status);
      await _loadDetailsForList(_transaksi);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load transaksi hari ini (Compatibility)
  Future<void> loadTransaksiHariIni() async {
     _isLoading = true;
    notifyListeners();
    try {
      _transaksi = await _transaksiService.getTransaksiHariIni();
      await _loadDetailsForList(_transaksi);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search transaksi (Compatibility)
  Future<void> searchTransaksi(String query) async {
    setSearch(query);
  }

  /// Update status transaksi
  Future<void> updateTransaksiStatus(String transaksiId, String newStatus) async {
    try {
      await _transaksiService.updateStatusTransaksi(transaksiId, newStatus);
      await refresh();
    } catch (e) {
      logger.e('Error updating transaksi status', error: e);
      rethrow;
    }
  }

  /// Refresh data
  Future<void> refresh() async {
    await loadDashboardData();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
