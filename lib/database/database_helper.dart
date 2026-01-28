import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:path_provider/path_provider.dart';
import '../models/transaksi.dart';
import '../models/detail_laundry.dart';
import '../models/customer.dart';
import '../models/pembayaran.dart';
import '../models/user.dart';
import '../models/order_kurir.dart';
import '../core/logger.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static bool _initialized = false;

  DatabaseHelper._init() {
    // Ensure database factory is initialized even if main() didn't call it
    initDatabaseFactory();
  }

  // Public method to initialize database factory (called from main)
  static void initDatabaseFactory() {
    if (_initialized) {
      logger.d('✓ Database factory already initialized');
      // Verify it's still valid
      if (!kIsWeb && databaseFactory == null) {
        logger.w('⚠️ databaseFactory is null despite being initialized, re-initializing...');
        _initialized = false;
      } else {
        return;
      }
    }
    
    print('Initializing database factory...');
    
    // Web platform uses sqflite_common_ffi_web
    if (kIsWeb) {
      print('Web platform detected, initializing FFI web factory (no web worker)...');
      // Avoid shared worker requirement (sqflite_sw.js) by using noWebWorker.
      // Use local sqlite3.wasm from web/ to avoid network/cert issues.
      final webOptions = SqfliteFfiWebOptions(
        sqlite3WasmUri: Uri.parse('sqlite3.wasm'),
      );
      databaseFactory = createDatabaseFactoryFfiWeb(
        options: webOptions,
        noWebWorker: true,
      );
      _initialized = true;
      return;
    }
    
    // Initialize database factory for desktop platforms (Windows, Linux, macOS)
    if (!kIsWeb) {
      try {
        // Try to detect desktop platform
        final isDesktop = defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS;
        
        if (isDesktop) {
          // Initialize FFI database factory for desktop
          print('Desktop platform detected ($defaultTargetPlatform), initializing FFI...');
          sqfliteFfiInit();
          databaseFactory = databaseFactoryFfi;
          
          // Verify that databaseFactory is set
          if (databaseFactory == null) {
            throw Exception('databaseFactory is still null after sqfliteFfiInit()');
          }
          print('✓ Database factory initialized with FFI for $defaultTargetPlatform');
          _initialized = true;
          return; // Success, exit early
        } else {
          // Mobile platform (Android/iOS) - use default factory
          print('Mobile platform detected, using default factory');
          _initialized = true;
          return;
        }
      } catch (e, stackTrace) {
        print('❌ FFI initialization failed: $e');
        print('Stack trace: $stackTrace');
        
        // For desktop, this is critical - rethrow
        final isDesktop = defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS;
        if (isDesktop) {
          throw Exception('Failed to initialize database factory for desktop: $e');
        }
        // For mobile, fall through to default
        print('Falling back to default factory for mobile');
        _initialized = true;
        return;
      }
    }
  }

  // Private method for internal use - ensures initialization
  static void _ensureInitialized() {
    if (!_initialized) {
      logger.d('🔄 Database factory not initialized yet, initializing now...');
      initDatabaseFactory();
    }
    
    // Double-check that databaseFactory is set for non-web platforms
    if (!kIsWeb && databaseFactory == null) {
      print('Warning: databaseFactory is null after initialization, re-initializing...');
      _initialized = false;
      initDatabaseFactory();
      
      // If still null, this is a critical error
      if (databaseFactory == null) {
        throw Exception('Critical: databaseFactory is still null after re-initialization. Please ensure sqflite_common_ffi is properly configured.');
      }
    }
  }

  Future<Database> get database async {
    // Ensure database factory is initialized before getting database
    _ensureInitialized();
    
    if (_database != null) return _database!;
    _database = await _initDB('laundry_pos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Ensure database factory is initialized
    _ensureInitialized();
    
    // Double check that databaseFactory is set (for desktop)
    if (!kIsWeb) {
      if (databaseFactory == null) {
        logger.w('⚠️ databaseFactory is null, re-initializing...');
        try {
          // Reset initialization flag to allow re-initialization
          _initialized = false;
          sqfliteFfiInit();
          databaseFactory = databaseFactoryFfi;
          _initialized = true;
          logger.i('✓ Database factory re-initialized');
        } catch (e, stackTrace) {
          logger.e('Error re-initializing database factory', error: e);
          logger.d('Stack trace: $stackTrace');
          throw Exception('Failed to initialize database factory: $e');
        }
      }
      
      // Final verification
      if (databaseFactory == null) {
        throw Exception('databaseFactory is not initialized. Please call DatabaseHelper.initDatabaseFactory() in main() before using database.');
      }
    }
    
    String dbPath;
    try {
      dbPath = await getDatabasesPath();
    } catch (e) {
      // If getDatabasesPath fails, try alternative approach for desktop
      if (!kIsWeb) {
        // Use path_provider for desktop
        final directory = await getApplicationDocumentsDirectory();
        dbPath = directory.path;
      } else {
        rethrow;
      }
    }
    
    final path = join(dbPath, filePath);

    logger.d('📂 Opening database at: $path');
    logger.d('Database factory status: ${databaseFactory != null ? "initialized" : "null"}');
    
    // Use explicit factory to avoid relying on global databaseFactory
    final isDesktop = defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
    DatabaseFactory? factory = databaseFactory;
    if (kIsWeb) {
      factory ??= databaseFactoryFfiWeb;
    } else if (isDesktop) {
      factory ??= databaseFactoryFfi;
    }

    if (factory == null) {
      final errorMsg = 'CRITICAL: databaseFactory is null before openDatabase(). Please ensure DatabaseHelper.initDatabaseFactory() was called.';
      logger.e('❌ $errorMsg');
      throw Exception(errorMsg);
    }
    
    try {
      return await factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 4, // Increment version untuk migration (menambahkan activity_log)
          onCreate: _createDB,
          onUpgrade: _upgradeDB,
        ),
      );
    } catch (e, stackTrace) {
      logger.e('Error opening database', error: e);
      logger.d('Stack trace: $stackTrace');
      
      // If error mentions databaseFactory, provide helpful message
      if (e.toString().contains('databaseFactory') || e.toString().contains('not initialized')) {
        print('⚠️ Database factory error detected. Checking initialization...');
        _ensureInitialized();
        print('Re-attempting database open after re-initialization...');
        // Try once more after re-initialization
        try {
          return await factory.openDatabase(
            path,
            options: OpenDatabaseOptions(
              version: 4,
              onCreate: _createDB,
              onUpgrade: _upgradeDB,
            ),
          );
        } catch (e2) {
          logger.e('❌ Second attempt also failed', error: e2);
          rethrow;
        }
      }
      
      rethrow;
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Tabel customer
    await db.execute('''
      CREATE TABLE customer (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL UNIQUE,
        alamat TEXT,
        kelurahan TEXT,
        kecamatan TEXT,
        kota TEXT,
        kode_pos TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Tabel user (untuk kasir, kurir, owner)
    await db.execute('''
      CREATE TABLE user (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL,
        role TEXT NOT NULL,
        phone TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Tabel transaksi
    await db.execute('''
      CREATE TABLE transaksi (
        id TEXT PRIMARY KEY,
        customer_id TEXT,
        customer_name TEXT NOT NULL,
        customer_phone TEXT NOT NULL,
        tanggal_masuk TEXT NOT NULL,
        tanggal_selesai TEXT,
        status TEXT NOT NULL,
        total_harga REAL NOT NULL,
        catatan TEXT,
        is_delivery INTEGER DEFAULT 0,
        FOREIGN KEY (customer_id) REFERENCES customer (id) ON DELETE SET NULL
      )
    ''');

    // Tabel detail_laundry
    await db.execute('''
      CREATE TABLE detail_laundry (
        id TEXT PRIMARY KEY,
        id_transaksi TEXT NOT NULL,
        jenis_layanan TEXT NOT NULL,
        jenis_barang TEXT NOT NULL,
        jumlah INTEGER NOT NULL,
        ukuran TEXT,
        berat REAL,
        luas REAL,
        catatan TEXT,
        foto TEXT,
        FOREIGN KEY (id_transaksi) REFERENCES transaksi (id) ON DELETE CASCADE
      )
    ''');

    // Tabel pembayaran
    await db.execute('''
      CREATE TABLE pembayaran (
        id TEXT PRIMARY KEY,
        transaksi_id TEXT NOT NULL,
        jumlah REAL NOT NULL,
        tanggal_bayar TEXT NOT NULL,
        metode_pembayaran TEXT NOT NULL,
        status TEXT NOT NULL,
        bukti_pembayaran TEXT,
        FOREIGN KEY (transaksi_id) REFERENCES transaksi (id) ON DELETE CASCADE
      )
    ''');

    // Tabel order_kurir
    await db.execute('''
      CREATE TABLE order_kurir (
        id TEXT PRIMARY KEY,
        transaksi_id TEXT NOT NULL,
        kurir_id TEXT NOT NULL,
        alamat_pengiriman TEXT,
        is_cod INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL,
        tanggal_assign TEXT,
        tanggal_selesai TEXT,
        catatan TEXT,
        FOREIGN KEY (transaksi_id) REFERENCES transaksi (id) ON DELETE CASCADE,
        FOREIGN KEY (kurir_id) REFERENCES user (id) ON DELETE CASCADE
      )
    ''');

    // Insert default users
    await _insertDefaultUsers(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Migrate dari version 1 ke 2
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS customer (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          phone TEXT NOT NULL UNIQUE,
          alamat TEXT,
          kelurahan TEXT,
          kecamatan TEXT,
          kota TEXT,
          kode_pos TEXT,
          created_at TEXT,
          updated_at TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS user (
          id TEXT PRIMARY KEY,
          username TEXT NOT NULL UNIQUE,
          email TEXT NOT NULL,
          role TEXT NOT NULL,
          phone TEXT,
          created_at TEXT,
          updated_at TEXT
        )
      ''');

      await db.execute('''
        ALTER TABLE transaksi ADD COLUMN customer_id TEXT
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS pembayaran (
          id TEXT PRIMARY KEY,
          transaksi_id TEXT NOT NULL,
          jumlah REAL NOT NULL,
          tanggal_bayar TEXT NOT NULL,
          metode_pembayaran TEXT NOT NULL,
          status TEXT NOT NULL,
          bukti_pembayaran TEXT,
          FOREIGN KEY (transaksi_id) REFERENCES transaksi (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS order_kurir (
          id TEXT PRIMARY KEY,
          transaksi_id TEXT NOT NULL,
          kurir_id TEXT NOT NULL,
          alamat_pengiriman TEXT,
          is_cod INTEGER NOT NULL DEFAULT 0,
          status TEXT NOT NULL,
          tanggal_assign TEXT,
          tanggal_selesai TEXT,
          catatan TEXT,
          FOREIGN KEY (transaksi_id) REFERENCES transaksi (id) ON DELETE CASCADE,
          FOREIGN KEY (kurir_id) REFERENCES user (id) ON DELETE CASCADE
        )
      ''');

      await _insertDefaultUsers(db);
    }
    
    // Migrate dari version 2 ke 3: tambahkan is_delivery ke transaksi
    if (oldVersion < 3) {
      try {
        await db.execute('''
          ALTER TABLE transaksi ADD COLUMN is_delivery INTEGER DEFAULT 0
        ''');
        print('✓ Added is_delivery column to transaksi table');
      } catch (e) {
        // Column mungkin sudah ada, skip error
        print('Note: is_delivery column may already exist: $e');
      }
    }
    
    // Migrate dari version 3 ke 4: tambahkan activity_log
    if (oldVersion < 4) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS activity_log (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            action TEXT NOT NULL,
            description TEXT,
            table_name TEXT,
            record_id TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES user (id) ON DELETE CASCADE
          )
        ''');
        print('✓ Added activity_log table');
      } catch (e) {
        // Table mungkin sudah ada, skip error
        print('Note: activity_log table may already exist: $e');
      }
    }
  }

  Future<void> _insertDefaultUsers(Database db) async {
    // Insert default users jika belum ada
    final existingUsers = await db.query('user');
    if (existingUsers.isEmpty) {
      final now = DateTime.now().toIso8601String();
      await db.insert('user', {
        'id': 'user_owner_1',
        'username': 'owner',
        'email': 'owner@laundry.com',
        'role': 'owner',
        'phone': '081234567890',
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('user', {
        'id': 'user_kasir_1',
        'username': 'kasir',
        'email': 'kasir@laundry.com',
        'role': 'kasir',
        'phone': '081234567891',
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('user', {
        'id': 'user_kurir_1',
        'username': 'kurir',
        'email': 'kurir@laundry.com',
        'role': 'kurir',
        'phone': '081234567892',
        'created_at': now,
        'updated_at': now,
      });
    }
  }

  // ========== TRANSaksi Methods ==========
  
  Future<int> insertTransaksi(Transaksi transaksi) async {
    final db = await database;
    return await db.insert(
      'transaksi',
      transaksi.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Transaksi>> getAllTransaksi() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('transaksi', orderBy: 'tanggal_masuk DESC');
    return List.generate(maps.length, (i) => Transaksi.fromJson(maps[i]));
  }

  Future<List<Transaksi>> getTransaksiByStatus(String status) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transaksi',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'tanggal_masuk DESC',
    );
    return List.generate(maps.length, (i) => Transaksi.fromJson(maps[i]));
  }

  Future<List<Transaksi>> getTransaksiHariIni() async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
    
    final List<Map<String, dynamic>> maps = await db.query(
      'transaksi',
      where: 'tanggal_masuk >= ? AND tanggal_masuk <= ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'tanggal_masuk DESC',
    );
    return List.generate(maps.length, (i) => Transaksi.fromJson(maps[i]));
  }

  Future<Transaksi?> getTransaksiById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transaksi',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Transaksi.fromJson(maps.first);
  }

  // Search transaksi by ID, customer name, or phone
  Future<List<Transaksi>> searchTransaksi(String query) async {
    final db = await database;
    final searchQuery = '%$query%';
    final List<Map<String, dynamic>> maps = await db.query(
      'transaksi',
      where: 'id LIKE ? OR customer_name LIKE ? OR customer_phone LIKE ?',
      whereArgs: [searchQuery, searchQuery, searchQuery],
      orderBy: 'tanggal_masuk DESC',
    );
    return List.generate(maps.length, (i) => Transaksi.fromJson(maps[i]));
  }

  // Filter transaksi dengan berbagai parameter
  Future<List<Transaksi>> filterTransaksi({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? customerId,
  }) async {
    final db = await database;
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    if (status != null && status.isNotEmpty) {
      whereConditions.add('status = ?');
      whereArgs.add(status);
    }

    if (startDate != null) {
      whereConditions.add('tanggal_masuk >= ?');
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      final endDateTime = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      whereConditions.add('tanggal_masuk <= ?');
      whereArgs.add(endDateTime.toIso8601String());
    }

    if (customerId != null && customerId.isNotEmpty) {
      whereConditions.add('customer_id = ?');
      whereArgs.add(customerId);
    }

    final whereClause = whereConditions.isNotEmpty
        ? whereConditions.join(' AND ')
        : null;

    final List<Map<String, dynamic>> maps = await db.query(
      'transaksi',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'tanggal_masuk DESC',
    );
    return List.generate(maps.length, (i) => Transaksi.fromJson(maps[i]));
  }

  // Search customer by name or phone
  Future<List<Customer>> searchCustomer(String query) async {
    final db = await database;
    final searchQuery = '%$query%';
    final List<Map<String, dynamic>> maps = await db.query(
      'customer',
      where: 'name LIKE ? OR phone LIKE ?',
      whereArgs: [searchQuery, searchQuery],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Customer.fromJson(maps[i]));
  }

  // Get all customers
  Future<List<Customer>> getAllCustomers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customer',
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Customer.fromJson(maps[i]));
  }

  Future<int> updateTransaksi(Transaksi transaksi) async {
    final db = await database;
    return await db.update(
      'transaksi',
      transaksi.toJson(),
      where: 'id = ?',
      whereArgs: [transaksi.id],
    );
  }

  Future<int> deleteTransaksi(String id) async {
    final db = await database;
    return await db.delete(
      'transaksi',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== DETAIL LAUNDRY Methods ==========

  Future<int> insertDetailLaundry(DetailLaundry detail) async {
    final db = await database;
    return await db.insert(
      'detail_laundry',
      detail.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DetailLaundry>> getDetailLaundryByTransaksiId(String idTransaksi) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'detail_laundry',
      where: 'id_transaksi = ?',
      whereArgs: [idTransaksi],
    );
    return List.generate(maps.length, (i) => DetailLaundry.fromJson(maps[i]));
  }

  Future<int> deleteDetailLaundry(String id) async {
    final db = await database;
    return await db.delete(
      'detail_laundry',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteDetailLaundryByTransaksiId(String idTransaksi) async {
    final db = await database;
    return await db.delete(
      'detail_laundry',
      where: 'id_transaksi = ?',
      whereArgs: [idTransaksi],
    );
  }

  // ========== STATISTICS Methods ==========

  Future<int> getTotalTransaksiHariIni() async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
    
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM transaksi WHERE tanggal_masuk >= ? AND tanggal_masuk <= ?',
      [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<double> getTotalPendapatanHariIni() async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
    
    final result = await db.rawQuery(
      'SELECT SUM(total_harga) as total FROM transaksi WHERE tanggal_masuk >= ? AND tanggal_masuk <= ?',
      [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalOmzet() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(total_harga) as total FROM transaksi');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Get pendapatan untuk tanggal tertentu
  Future<double> getPendapatanByDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    final result = await db.rawQuery(
      'SELECT SUM(total_harga) as total FROM transaksi WHERE tanggal_masuk >= ? AND tanggal_masuk <= ?',
      [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Get pendapatan bulanan
  Future<double> getPendapatanBulanan(int year, int month) async {
    final db = await database;
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);
    
    final result = await db.rawQuery(
      'SELECT SUM(total_harga) as total FROM transaksi WHERE tanggal_masuk >= ? AND tanggal_masuk <= ?',
      [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // ========== CUSTOMER Methods ==========

  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return await db.insert(
      'customer',
      customer.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Customer?> getCustomerByPhone(String phone) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customer',
      where: 'phone = ?',
      whereArgs: [phone],
    );
    if (maps.isEmpty) return null;
    return Customer.fromJson(maps.first);
  }

  Future<Customer?> getCustomerById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customer',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Customer.fromJson(maps.first);
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await database;
    return await db.update(
      'customer',
      customer.toJson(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  // ========== USER Methods ==========

  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert(
      'user',
      user.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<User>> getUsersByRole(String role) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user',
      where: 'role = ?',
      whereArgs: [role],
    );
    return List.generate(maps.length, (i) => User.fromJson(maps[i]));
  }

  Future<User?> getUserById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return User.fromJson(maps.first);
  }

  // Get all users
  Future<List<User>> getAllUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user',
      orderBy: 'username ASC',
    );
    return List.generate(maps.length, (i) => User.fromJson(maps[i]));
  }

  // Update user
  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'user',
      user.toJson(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // Delete user
  Future<int> deleteUser(String id) async {
    final db = await database;
    return await db.delete(
      'user',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== ACTIVITY LOG Methods ==========

  Future<int> insertActivityLog({
    required String userId,
    required String action,
    String? description,
    String? tableName,
    String? recordId,
  }) async {
    final db = await database;
    final logId = 'LOG_${DateTime.now().millisecondsSinceEpoch}';
    return await db.insert(
      'activity_log',
      {
        'id': logId,
        'user_id': userId,
        'action': action,
        'description': description,
        'table_name': tableName,
        'record_id': recordId,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getActivityLogsByUserId(String userId, {int? limit}) async {
    final db = await database;
    return await db.query(
      'activity_log',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }

  Future<List<Map<String, dynamic>>> getAllActivityLogs({int? limit}) async {
    final db = await database;
    return await db.query(
      'activity_log',
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }

  // ========== PEMBAYARAN Methods ==========

  Future<int> insertPembayaran(Pembayaran pembayaran) async {
    final db = await database;
    return await db.insert(
      'pembayaran',
      pembayaran.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Pembayaran>> getPembayaranByTransaksiId(String transaksiId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pembayaran',
      where: 'transaksi_id = ?',
      whereArgs: [transaksiId],
    );
    return List.generate(maps.length, (i) => Pembayaran.fromJson(maps[i]));
  }

  Future<Pembayaran?> getPembayaranCODByTransaksiId(String transaksiId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pembayaran',
      where: 'transaksi_id = ? AND metode_pembayaran = ?',
      whereArgs: [transaksiId, 'cod'],
    );
    if (maps.isEmpty) return null;
    return Pembayaran.fromJson(maps.first);
  }

  // Filter pembayaran by status dan metode
  Future<List<Pembayaran>> filterPembayaran({
    String? status,
    String? metodePembayaran,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    if (status != null && status.isNotEmpty) {
      whereConditions.add('status = ?');
      whereArgs.add(status);
    }

    if (metodePembayaran != null && metodePembayaran.isNotEmpty) {
      whereConditions.add('metode_pembayaran = ?');
      whereArgs.add(metodePembayaran);
    }

    if (startDate != null) {
      whereConditions.add('tanggal_bayar >= ?');
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      final endDateTime = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      whereConditions.add('tanggal_bayar <= ?');
      whereArgs.add(endDateTime.toIso8601String());
    }

    final whereClause = whereConditions.isNotEmpty
        ? whereConditions.join(' AND ')
        : null;

    final List<Map<String, dynamic>> maps = await db.query(
      'pembayaran',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'tanggal_bayar DESC',
    );
    return List.generate(maps.length, (i) => Pembayaran.fromJson(maps[i]));
  }

  // ========== ORDER KURIR Methods ==========

  Future<int> insertOrderKurir(OrderKurir orderKurir) async {
    final db = await database;
    return await db.insert(
      'order_kurir',
      orderKurir.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<OrderKurir>> getOrderKurirByKurirId(String kurirId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'order_kurir',
      where: 'kurir_id = ?',
      whereArgs: [kurirId],
      orderBy: 'tanggal_assign DESC',
    );
    return List.generate(maps.length, (i) => OrderKurir.fromJson(maps[i]));
  }

  Future<OrderKurir?> getOrderKurirByTransaksiId(String transaksiId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'order_kurir',
      where: 'transaksi_id = ?',
      whereArgs: [transaksiId],
    );
    if (maps.isEmpty) return null;
    return OrderKurir.fromJson(maps.first);
  }

  Future<int> updateOrderKurir(OrderKurir orderKurir) async {
    final db = await database;
    return await db.update(
      'order_kurir',
      orderKurir.toJson(),
      where: 'id = ?',
      whereArgs: [orderKurir.id],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

