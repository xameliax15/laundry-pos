import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../models/user.dart';
import '../models/activity_log.dart';
import '../database/database_helper.dart';
import '../services/auth_service.dart';
import '../core/constants.dart';
import '../core/logger.dart';

class UserService {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;

  // Get all users
  Future<List<User>> getAllUsers() async {
    if (AppConstants.useSupabase) {
      final data = await _supabase.from('users').select().order('username');
      return data.map<User>((row) => User.fromJson(row)).toList();
    }
    return await _db.getAllUsers();
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

  // Create user
  Future<User> createUser({
    required String username,
    required String email,
    required String role,
    required String password,
    String? phone,
  }) async {
    final currentUser = AuthService().getCurrentUser();
    if (currentUser == null || currentUser.role != 'owner') {
      throw Exception('Hanya owner yang dapat membuat user baru');
    }

    if (AppConstants.useSupabase) {
      final normalizedEmail = _normalizeEmail(email);
      final existing = await _supabase
          .from('users')
          .select('id,username,email')
          .or('username.eq.$username,email.eq.$normalizedEmail');
      if (existing.isNotEmpty) {
        throw Exception('Username atau email sudah digunakan');
      }

      final previousSession = _supabase.auth.currentSession;
      final authResponse = await _supabase.auth.signUp(
        email: normalizedEmail,
        password: password,
      );
      final authUser = authResponse.user;
      if (authUser == null) {
        throw Exception('Gagal membuat akun auth untuk user baru');
      }

      final inserted = await _supabase.from('users').insert({
        'id': authUser.id,
        'username': username,
        'email': normalizedEmail,
        'role': role,
        'phone': phone,
      }).select().single();

      await _logActivity(
        userId: currentUser.id,
        action: 'CREATE_USER',
        description: 'Membuat user baru: $username ($role)',
        recordId: inserted['id'] as String? ?? authUser.id,
      );

      if (previousSession?.refreshToken != null) {
        try {
          await _supabase.auth.setSession(previousSession!.refreshToken!);
        } catch (e) {
          throw Exception('User dibuat, tetapi sesi owner perlu login ulang.');
        }
      }

      return User.fromJson(inserted);
    }

    // SQLite fallback
    final existingUsers = await _db.getAllUsers();
    if (existingUsers.any((u) => u.username.toLowerCase() == username.toLowerCase())) {
      throw Exception('Username sudah digunakan');
    }
    if (existingUsers.any((u) => u.email.toLowerCase() == email.toLowerCase())) {
      throw Exception('Email sudah digunakan');
    }

    final userId = 'USER_${DateTime.now().millisecondsSinceEpoch}';
    final user = User(
      id: userId,
      username: username,
      email: email,
      role: role,
      phone: phone,
    );

    await _db.insertUser(user);
    await _db.insertActivityLog(
      userId: currentUser.id,
      action: 'CREATE_USER',
      description: 'Membuat user baru: $username ($role)',
      tableName: 'user',
      recordId: userId,
    );
    return user;
  }

  // Update user
  Future<User> updateUser(User user) async {
    final currentUser = AuthService().getCurrentUser();
    if (currentUser == null || currentUser.role != 'owner') {
      throw Exception('Hanya owner yang dapat mengupdate user');
    }

    if (AppConstants.useSupabase) {
      final normalizedEmail = _normalizeEmail(user.email);
      final existingUsers = await _supabase.from('users').select('id,username,email');
      if (existingUsers.any((u) =>
          u['id'] != user.id &&
          (u['username'] as String).toLowerCase() == user.username.toLowerCase())) {
        throw Exception('Username sudah digunakan');
      }
      if (existingUsers.any((u) =>
          u['id'] != user.id &&
          _normalizeEmail(u['email'] as String) == normalizedEmail)) {
        throw Exception('Email sudah digunakan');
      }

      await _supabase.from('users').update({
        'username': user.username,
        'email': normalizedEmail,
        'role': user.role,
        'phone': user.phone,
      }).eq('id', user.id);

      await _logActivity(
        userId: currentUser.id,
        action: 'UPDATE_USER',
        description: 'Mengupdate user: ${user.username}',
        recordId: user.id,
      );

      return user;
    }

    final existingUsers = await _db.getAllUsers();
    if (existingUsers.any((u) =>
        u.id != user.id && u.username.toLowerCase() == user.username.toLowerCase())) {
      throw Exception('Username sudah digunakan');
    }
    if (existingUsers.any((u) =>
        u.id != user.id && u.email.toLowerCase() == user.email.toLowerCase())) {
      throw Exception('Email sudah digunakan');
    }

    await _db.updateUser(user);
    await _db.insertActivityLog(
      userId: currentUser.id,
      action: 'UPDATE_USER',
      description: 'Mengupdate user: ${user.username}',
      tableName: 'user',
      recordId: user.id,
    );
    return user;
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    final currentUser = AuthService().getCurrentUser();
    if (currentUser == null || currentUser.role != 'owner') {
      throw Exception('Hanya owner yang dapat menghapus user');
    }

    // Prevent deleting own account
    if (currentUser.id == userId) {
      throw Exception('Tidak dapat menghapus akun sendiri');
    }

    if (AppConstants.useSupabase) {
      final user = await getUserById(userId);
      if (user == null) {
        throw Exception('User tidak ditemukan');
      }

      await _supabase.from('users').delete().eq('id', userId);

      await _logActivity(
        userId: currentUser.id,
        action: 'DELETE_USER',
        description: 'Menghapus user: ${user.username}',
        recordId: userId,
      );
      return;
    }

    final user = await _db.getUserById(userId);
    if (user == null) {
      throw Exception('User tidak ditemukan');
    }

    await _db.deleteUser(userId);
    await _db.insertActivityLog(
      userId: currentUser.id,
      action: 'DELETE_USER',
      description: 'Menghapus user: ${user.username}',
      tableName: 'user',
      recordId: userId,
    );
  }

  // Get activity logs by user ID
  Future<List<ActivityLog>> getActivityLogsByUserId(String userId, {int? limit}) async {
    if (AppConstants.useSupabase) {
      var query = _supabase
          .from('activity_log')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      if (limit != null) {
        query = query.limit(limit);
      }
      final logs = await query;
      return logs.map<ActivityLog>((log) => ActivityLog.fromJson(log)).toList();
    }

    final logs = await _db.getActivityLogsByUserId(userId, limit: limit);
    return logs.map((log) => ActivityLog.fromJson(log)).toList();
  }

  // Get all activity logs
  Future<List<ActivityLog>> getAllActivityLogs({int? limit}) async {
    if (AppConstants.useSupabase) {
      var query = _supabase
          .from('activity_log')
          .select()
          .order('created_at', ascending: false);
      if (limit != null) {
        query = query.limit(limit);
      }
      final logs = await query;
      return logs.map<ActivityLog>((log) => ActivityLog.fromJson(log)).toList();
    }

    final logs = await _db.getAllActivityLogs(limit: limit);
    return logs.map((log) => ActivityLog.fromJson(log)).toList();
  }

  Future<void> _logActivity({
    required String userId,
    required String action,
    required String description,
    required String recordId,
  }) async {
    try {
      await _supabase.from('activity_log').insert({
        'user_id': userId,
        'action': action,
        'description': description,
        'table_name': 'users',
        'record_id': recordId,
      });
    } catch (e) {
      print('Error logging activity: $e');
    }
  }

  String _normalizeEmail(String email) {
    return email.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
  }
}



