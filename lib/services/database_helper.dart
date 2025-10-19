import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'package:open_download_manager/services/config.dart';

/// Manages SQLite database operations for download history
class DatabaseHelper {
  static Database? _database;
  static const String _dbName = 'downloads.db';
  static const String _tableName = 'downloads';
  static bool _isInitialized = false;
  
  /// Initialize the database factory for desktop platforms
  static void _initializeDatabaseFactory() {
    if (_isInitialized) return;
    
    // Check if running on desktop platforms (Linux, Windows, macOS)
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      // Initialize FFI for desktop platforms
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    // For mobile platforms (Android, iOS), sqflite is already initialized
    
    _isInitialized = true;
  }
  
  /// Get the database instance (singleton pattern)
  static Future<Database> get database async {
    _initializeDatabaseFactory();
    
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  /// Initialize the database
  static Future<Database> _initDatabase() async {
    // Get the database path in the app_data directory
    final dbPath = path.join(Config.appDir, 'app_data', _dbName);
    
    // Ensure the directory exists
    final dbDir = Directory(path.dirname(dbPath));
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }
    
    // Open the database
    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _createDatabase,
    );
  }
  
  /// Create the database tables
  static Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        partialFilePath TEXT PRIMARY KEY,
        speed INTEGER,
        status TEXT NOT NULL,
        errorMessage TEXT
      )
    ''');
  }
  
  /// Insert or update a download record
  static Future<void> upsertDownload({
    required String partialFilePath,
    int? speed,
    required String status,
    String? errorMessage,
  }) async {
    final db = await database;
    await db.insert(
      _tableName,
      {
        'partialFilePath': partialFilePath,
        'speed': speed,
        'status': status,
        'errorMessage': errorMessage,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  /// Get all download records from the database
  static Future<List<Map<String, dynamic>>> getAllDownloads() async {
    final db = await database;
    return await db.query(_tableName);
  }
  
  /// Get a specific download record by partial file path
  static Future<Map<String, dynamic>?> getDownload(String partialFilePath) async {
    final db = await database;
    final results = await db.query(
      _tableName,
      where: 'partialFilePath = ?',
      whereArgs: [partialFilePath],
      limit: 1,
    );
    
    if (results.isEmpty) return null;
    return results.first;
  }
  
  /// Delete a download record
  static Future<void> deleteDownload(String partialFilePath) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'partialFilePath = ?',
      whereArgs: [partialFilePath],
    );
  }
  
  /// Clear all download records
  static Future<void> clearAllDownloads() async {
    final db = await database;
    await db.delete(_tableName);
  }
  
  /// Close the database connection
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
