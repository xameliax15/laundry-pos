import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../models/user.dart';
import '../core/constants.dart';
import '../core/logger.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  bool _isLoggedIn = false;
  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;

  // Login dengan database
  Future<User?> login(String username, String password) async {
    try {
      final resolvedEmail = await _resolveEmail(username);
      if (resolvedEmail == null) {
        return null;
      }

      final normalizedEmail = _normalizeEmail(resolvedEmail);
      final authResponse = await _supabase.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );

      final authUser = authResponse.user;
      if (authUser == null) {
        return null;
      }

      final user = await _getOrCreateUserProfile(
        authUser: authUser,
        usernameInput: username,
        email: normalizedEmail,
      );

      _currentUser = user;
      _isLoggedIn = true;
      
      // Log activity
      await _logActivity(
        userId: user.id,
        action: 'LOGIN',
        description: 'User login: ${user.username}',
      );
      
      logger.i('✓ Login berhasil - User: ${user.username}, Role: ${user.role}');
      
      return user;
    } catch (e) {
      logger.e('❌ Error during login', error: e);
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
      _currentUser = null;
      _isLoggedIn = false;
      logger.i('✅ Logout successful - Local storage cleared');
    } catch (e) {
      logger.e('Error during logout', error: e);
      rethrow;
    }
  }

  Future<void> updatePassword(String newPassword) async {
    final response = await _supabase.auth.updateUser(
      supabase.UserAttributes(password: newPassword),
    );
    if (response.user == null) {
      throw Exception('Gagal memperbarui password');
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // Get current user
  User? getCurrentUser() {
    return _currentUser;
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _isLoggedIn && _currentUser != null;
  }

  // Get user role
  String? getUserRole() {
    return _currentUser?.role;
  }

  Future<String?> _resolveEmail(String usernameOrEmail) async {
    final input = usernameOrEmail.trim();
    if (input.contains('@')) {
      return _normalizeEmail(input);
    }

    // Query dengan case-insensitive matching
    final userRow = await _supabase
        .from('users')
        .select('email')
        .ilike('username', input)
        .maybeSingle();
    
    logger.i('🔍 Looking for username: "$input", found: ${userRow != null}');
    
    final email = userRow?['email'] as String?;
    if (email == null) {
      logger.w('⚠️ Username "$input" not found in database');
      return null;
    }
    
    logger.i('✓ Resolved username "$input" to email: $email');
    return _normalizeEmail(email);
  }

  String _normalizeEmail(String email) {
    return email.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
  }

  Future<User> _getOrCreateUserProfile({
    required supabase.User authUser,
    required String usernameInput,
    required String email,
  }) async {
    final existing = await _supabase
        .from('users')
        .select()
        .eq('email', email)
        .maybeSingle();

    if (existing != null) {
      return User.fromJson(existing);
    }

    final username = usernameInput.contains('@')
        ? email.split('@').first
        : usernameInput.trim();

    final created = await _supabase.from('users').insert({
      'id': authUser.id,
      'username': username,
      'email': email,
      'role': AppConstants.roleKasir,
      'phone': null,
    }).select().single();

    return User.fromJson(created);
  }

  Future<void> _logActivity({
    required String userId,
    required String action,
    required String description,
  }) async {
    try {
      await _supabase.from('activity_log').insert({
        'user_id': userId,
        'action': action,
        'description': description,
      });
    } catch (e) {
      logger.e('Error logging activity', error: e);
    }
  }
}

