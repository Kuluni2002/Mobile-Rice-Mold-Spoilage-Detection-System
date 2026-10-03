import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../core/constants/app_constants.dart';
import '../models/grain_models.dart';

class DatabaseService {
  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path   = join(dbPath, AppConstants.dbName);

    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE scans (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp     TEXT NOT NULL,
        image_path    TEXT,
        total_grains  INTEGER,
        healthy_count INTEGER,
        early_risk_count INTEGER,
        spoiled_count INTEGER,
        dominant_class TEXT,
        recommendation TEXT
      )
    ''');
  }

  Future<int> saveScan(BatchResult result) async {
    final db = await database;
    return db.insert('scans', {
      'timestamp'        : result.timestamp.toIso8601String(),
      'image_path'       : result.imagePath,
      'total_grains'     : result.total,
      'healthy_count'    : result.counts['healthy'] ?? 0,
      'early_risk_count' : result.counts['early_risk'] ?? 0,
      'spoiled_count'    : result.counts['spoiled'] ?? 0,
      'dominant_class'   : result.dominant,
      'recommendation'   : result.recommendation,
    });
  }

  Future<List<Map<String, dynamic>>> getAllScans() async {
    final db = await database;
    return db.query('scans', orderBy: 'timestamp DESC');
  }

  Future<void> deleteScan(int id) async {
    final db = await database;
    await db.delete('scans', where: 'id = ?', whereArgs: [id]);
  }
}