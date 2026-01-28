import '../core/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local Storage Service - Implementasi dengan SharedPreferences
class LocalDB {
  static final LocalDB _instance = LocalDB._internal();
  factory LocalDB() => _instance;
  LocalDB._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  /// Initialize SharedPreferences
  Future<void> init() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
      logger.d('✅ LocalDB initialized');
    }
  }

  /// Save data ke local storage
  Future<bool> saveData(String key, String value) async {
    try {
      if (!_initialized) await init();
      final result = await _prefs.setString(key, value);
      logger.d('✅ Data saved locally: $key');
      return result;
    } catch (e) {
      logger.e('Error saving data', error: e);
      return false;
    }
  }

  /// Get data dari local storage
  Future<String?> getData(String key) async {
    try {
      if (!_initialized) await init();
      final data = _prefs.getString(key);
      logger.d('✅ Data retrieved: $key');
      return data;
    } catch (e) {
      logger.e('Error retrieving data', error: e);
      return null;
    }
  }

  /// Delete data dari local storage
  Future<bool> deleteData(String key) async {
    try {
      if (!_initialized) await init();
      final result = await _prefs.remove(key);
      logger.d('✅ Data deleted: $key');
      return result;
    } catch (e) {
      logger.e('Error deleting data', error: e);
      return false;
    }
  }

  /// Clear all data dari local storage
  Future<bool> clearAll() async {
    try {
      if (!_initialized) await init();
      final result = await _prefs.clear();
      logger.i('✅ All local data cleared');
      return result;
    } catch (e) {
      logger.e('Error clearing data', error: e);
      return false;
    }
  }

  /// Save user token
  Future<bool> saveToken(String token) async {
    return saveData('auth_token', token);
  }

  /// Get user token
  Future<String?> getToken() async {
    return getData('auth_token');
  }

  /// Save user data as JSON
  Future<bool> saveUserData(String userData) async {
    return saveData('user_data', userData);
  }

  /// Get user data
  Future<String?> getUserData() async {
    return getData('user_data');
  }
}
