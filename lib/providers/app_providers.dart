import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../models/transaksi.dart';
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
  
  List<Transaksi> _transaksi = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Transaksi> get transaksi => _transaksi;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load transaksi dengan status
  Future<void> loadTransaksiByStatus(String status) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _transaksi = await _transaksiService.getTransaksiByStatus(status);
      logger.d('✅ Loaded ${_transaksi.length} transaksi with status: $status');
    } catch (e) {
      _error = e.toString();
      logger.e('Error loading transaksi', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load transaksi hari ini
  Future<void> loadTransaksiHariIni() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _transaksi = await _transaksiService.getTransaksiHariIni();
      logger.d('✅ Loaded ${_transaksi.length} transaksi hari ini');
    } catch (e) {
      _error = e.toString();
      logger.e('Error loading transaksi hari ini', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search transaksi
  Future<void> searchTransaksi(String query) async {
    if (query.isEmpty) {
      _transaksi = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _transaksi = await _transaksiService.searchTransaksi(query);
      logger.d('✅ Search results: ${_transaksi.length} transaksi');
    } catch (e) {
      _error = e.toString();
      logger.e('Error searching transaksi', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh data
  Future<void> refresh() async {
    await loadTransaksiHariIni();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
