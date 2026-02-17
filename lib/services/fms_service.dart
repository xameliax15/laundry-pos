import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../core/logger.dart';

/// File Management Service - Handle file operations dengan Supabase Storage
class FmsService {
  static final FmsService _instance = FmsService._internal();
  factory FmsService() => _instance;
  FmsService._internal();

  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;
  static const String _bucketName = 'laundry_files';

  /// Upload file ke Supabase Storage
  Future<String?> uploadFile(File file, {String? customName}) async {
    try {
      final fileName = customName ?? DateTime.now().millisecondsSinceEpoch.toString();
      await _supabase.storage.from(_bucketName).upload(
            fileName,
            file,
          );
      logger.i('✅ File uploaded successfully: $fileName');
      return fileName;
    } catch (e) {
      logger.e('Error uploading file', error: e);
      return null;
    }
  }

  /// Download file dari Supabase Storage
  Future<List<int>?> downloadFile(String fileName) async {
    try {
      final data = await _supabase.storage.from(_bucketName).download(fileName);
      logger.i('✅ File downloaded successfully: $fileName');
      return data;
    } catch (e) {
      logger.e('Error downloading file', error: e);
      return null;
    }
  }

  /// Delete file dari Supabase Storage
  Future<bool> deleteFile(String fileName) async {
    try {
      await _supabase.storage.from(_bucketName).remove([fileName]);
      logger.i('✅ File deleted successfully: $fileName');
      return true;
    } catch (e) {
      logger.e('Error deleting file', error: e);
      return false;
    }
  }

  /// Get file URL dari Supabase Storage
  Future<String?> getFileUrl(String fileName) async {
    try {
      final url = _supabase.storage.from(_bucketName).getPublicUrl(fileName);
      logger.d('✅ File URL generated: $fileName');
      return url;
    } catch (e) {
      logger.e('Error getting file URL', error: e);
      return null;
    }
  }

  /// List semua files di bucket
  Future<List<String>> listFiles() async {
    try {
      final files = await _supabase.storage.from(_bucketName).list();
      return files.map((f) => f.name).toList();
    } catch (e) {
      logger.e('Error listing files', error: e);
      return [];
    }
  }
}



