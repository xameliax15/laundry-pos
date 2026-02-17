import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/logger.dart';
import '../services/auth_service.dart';

/// Model for status change log entry
class StatusLog {
  final String id;
  final String transaksiId;
  final String oldStatus;
  final String newStatus;
  final String changedBy;
  final String? changedByName;
  final DateTime changedAt;
  final String? notes;

  StatusLog({
    required this.id,
    required this.transaksiId,
    required this.oldStatus,
    required this.newStatus,
    required this.changedBy,
    this.changedByName,
    required this.changedAt,
    this.notes,
  });

  factory StatusLog.fromJson(Map<String, dynamic> json) {
    return StatusLog(
      id: json['id'] ?? '',
      transaksiId: json['transaksi_id'] ?? '',
      oldStatus: json['old_status'] ?? '',
      newStatus: json['new_status'] ?? '',
      changedBy: json['changed_by'] ?? '',
      changedByName: json['changed_by_name'],
      changedAt: DateTime.parse(json['changed_at'] ?? DateTime.now().toIso8601String()),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transaksi_id': transaksiId,
      'old_status': oldStatus,
      'new_status': newStatus,
      'changed_by': changedBy,
      'changed_by_name': changedByName,
      'changed_at': changedAt.toIso8601String(),
      'notes': notes,
    };
  }
}

/// Service for logging status changes
class StatusLogService {
  static final StatusLogService _instance = StatusLogService._internal();
  factory StatusLogService() => _instance;
  StatusLogService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  /// Log a status change
  Future<void> logStatusChange({
    required String transaksiId,
    required String oldStatus,
    required String newStatus,
    String? notes,
  }) async {
    try {
      final currentUser = _authService.getCurrentUser();
      if (currentUser == null) {
        logger.w('Cannot log status change: No user logged in');
        return;
      }

      final log = StatusLog(
        id: '',
        transaksiId: transaksiId,
        oldStatus: oldStatus,
        newStatus: newStatus,
        changedBy: currentUser.id,
        changedByName: currentUser.username,
        changedAt: DateTime.now(),
        notes: notes,
      );

      await _supabase.from('status_logs').insert(log.toJson());
      
      logger.i('✓ Status change logged: $oldStatus → $newStatus for transaksi $transaksiId');
    } catch (e) {
      logger.e('Error logging status change', error: e);
      // Don't throw - logging should not break the main flow
    }
  }

  /// Get status history for a transaction
  Future<List<StatusLog>> getStatusHistory(String transaksiId) async {
    try {
      final response = await _supabase
          .from('status_logs')
          .select()
          .eq('transaksi_id', transaksiId)
          .order('changed_at', ascending: false);

      return (response as List)
          .map((json) => StatusLog.fromJson(json))
          .toList();
    } catch (e) {
      logger.e('Error getting status history', error: e);
      return [];
    }
  }

  /// Get recent status changes (for dashboard/admin)
  Future<List<StatusLog>> getRecentChanges({int limit = 50}) async {
    try {
      final response = await _supabase
          .from('status_logs')
          .select()
          .order('changed_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => StatusLog.fromJson(json))
          .toList();
    } catch (e) {
      logger.e('Error getting recent status changes', error: e);
      return [];
    }
  }
}
