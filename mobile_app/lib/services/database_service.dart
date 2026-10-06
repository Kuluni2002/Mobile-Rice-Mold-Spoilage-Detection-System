import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../core/errors/failures.dart';
import '../domain/entities/batch.dart' as domain;
import '../models/grain_models.dart';
import '../models/scan_record.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  static Database? _db;

  factory DatabaseService() => instance;
  DatabaseService._internal();

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, AppConstants.dbName),
      version: AppConstants.dbVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createTables,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('DROP TABLE IF EXISTS scans');
          await _createTables(db, newVersion);
        }
      },
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE batches (
        id TEXT PRIMARY KEY,
        batch_number TEXT NOT NULL UNIQUE,
        variety TEXT,
        source TEXT,
        quantity REAL,
        storage_date TEXT NOT NULL,
        location TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE scans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        batch_id TEXT NOT NULL REFERENCES batches(id) ON DELETE CASCADE,
        timestamp TEXT NOT NULL,
        image_path TEXT,
        total_grains INTEGER NOT NULL,
        healthy_count INTEGER NOT NULL,
        early_risk_count INTEGER NOT NULL,
        spoiled_count INTEGER NOT NULL,
        dominant_class TEXT NOT NULL,
        recommendation TEXT,
        recommendation_source TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_scans_batch_timestamp ON scans(batch_id, timestamp)',
    );
  }

  Future<T> _guard<T>(Future<T> Function(Database db) action) async {
    try {
      return await action(await database);
    } on DatabaseException catch (error) {
      final duplicate = error.toString().contains('UNIQUE constraint failed');
      throw DatabaseFailure(
        duplicate ? 'This batch number already exists' : 'Unable to access saved data',
        isDuplicateBatchNumber: duplicate,
      );
    }
  }

  Future<int> insertBatch(domain.Batch batch) => _guard(
    (db) => db.insert('batches', batch.toMap()),
  );

  Future<List<domain.Batch>> getBatches() => _guard((db) async {
    final rows = await db.rawQuery('''
      SELECT b.*,
        (SELECT dominant_class FROM scans s WHERE s.batch_id = b.id
          ORDER BY s.timestamp DESC LIMIT 1) AS latest_result,
        (SELECT timestamp FROM scans s WHERE s.batch_id = b.id
          ORDER BY s.timestamp DESC LIMIT 1) AS latest_scan_time,
        (SELECT COUNT(*) FROM scans s WHERE s.batch_id = b.id) AS scan_count
      FROM batches b ORDER BY b.created_at DESC
    ''');
    return rows.map(domain.Batch.fromMap).toList();
  });

  Future<domain.Batch?> getBatch(String id) => _guard((db) async {
    final rows = await db.rawQuery('''
      SELECT b.*,
        (SELECT dominant_class FROM scans s WHERE s.batch_id = b.id
          ORDER BY s.timestamp DESC LIMIT 1) AS latest_result,
        (SELECT timestamp FROM scans s WHERE s.batch_id = b.id
          ORDER BY s.timestamp DESC LIMIT 1) AS latest_scan_time,
        (SELECT COUNT(*) FROM scans s WHERE s.batch_id = b.id) AS scan_count
      FROM batches b WHERE b.id = ?
    ''', [id]);
    return rows.isEmpty ? null : domain.Batch.fromMap(rows.first);
  });

  Future<bool> batchNumberExists(String number) => _guard((db) async {
    final rows = await db.query(
      'batches',
      columns: ['id'],
      where: 'batch_number = ?',
      whereArgs: [number],
      limit: 1,
    );
    return rows.isNotEmpty;
  });

  Future<int> deleteBatch(String id) =>
      _guard((db) => db.delete('batches', where: 'id = ?', whereArgs: [id]));

  Future<int> insertScan(ScanRecord scan) =>
      _guard((db) => db.insert('scans', scan.toMap()));

  Future<List<ScanRecord>> getScansForBatch(String batchId) => _guard(
    (db) async => (await db.query(
      'scans',
      where: 'batch_id = ?',
      whereArgs: [batchId],
      orderBy: 'timestamp DESC',
    )).map(ScanRecord.fromMap).toList(),
  );

  Future<ScanRecord?> getScan(int id) => _guard((db) async {
    final rows = await db.query('scans', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : ScanRecord.fromMap(rows.first);
  });

  Future<int> deleteScan(int id) =>
      _guard((db) => db.delete('scans', where: 'id = ?', whereArgs: [id]));

  Future<Map<String, int>> getDashboardStats() => _guard((db) async {
    final rows = await db.rawQuery('''
      SELECT
        COUNT(*) AS total_batches,
        COALESCE((SELECT COUNT(*) FROM scans), 0) AS total_scans,
        COALESCE(SUM(CASE WHEN latest_result = ? THEN 1 ELSE 0 END), 0) AS healthy,
        COALESCE(SUM(CASE WHEN latest_result = ? THEN 1 ELSE 0 END), 0) AS early_risk,
        COALESCE(SUM(CASE WHEN latest_result = ? THEN 1 ELSE 0 END), 0) AS spoiled
      FROM (
        SELECT b.id,
          (SELECT dominant_class FROM scans s WHERE s.batch_id = b.id
            ORDER BY s.timestamp DESC LIMIT 1) AS latest_result
        FROM batches b
      )
    ''', [
      AppConstants.classHealthy,
      AppConstants.classEarlyRisk,
      AppConstants.classSpoiled,
    ]);
    final row = rows.first;
    final earlyRisk = (row['early_risk'] as num).toInt();
    final spoiled = (row['spoiled'] as num).toInt();
    return {
      'totalBatches': (row['total_batches'] as num).toInt(),
      'totalScans': (row['total_scans'] as num).toInt(),
      'healthy': (row['healthy'] as num).toInt(),
      'earlyRisk': earlyRisk,
      'spoiled': spoiled,
      'batchesNeedingAttention': earlyRisk + spoiled,
    };
  });

  Future<List<domain.Batch>> getRecentBatches([int limit = 5]) => _guard((db) async {
    final rows = await db.rawQuery('''
      SELECT b.*,
        (SELECT dominant_class FROM scans s WHERE s.batch_id = b.id
          ORDER BY s.timestamp DESC LIMIT 1) AS latest_result,
        (SELECT timestamp FROM scans s WHERE s.batch_id = b.id
          ORDER BY s.timestamp DESC LIMIT 1) AS latest_scan_time,
        (SELECT COUNT(*) FROM scans s WHERE s.batch_id = b.id) AS scan_count
      FROM batches b
      ORDER BY COALESCE(latest_scan_time, b.created_at) DESC
      LIMIT ?
    ''', [limit]);
    return rows.map(domain.Batch.fromMap).toList();
  });

  Future<int> saveScan(BatchResult result, [String? batchId]) async {
    final id = batchId ?? const Uuid().v4();
    if (batchId == null) {
      final now = DateTime.now().toUtc();
      await insertBatch(domain.Batch(
        id: id,
        batchNumber: 'Unassigned ${now.millisecondsSinceEpoch}',
        storageDate: now,
        createdAt: now,
        updatedAt: now,
      ));
    }
    return insertScan(ScanRecord(
      batchId: id,
      timestamp: result.timestamp,
      imagePath: result.imagePath,
      totalGrains: result.total,
      healthyCount: result.counts[AppConstants.classHealthy] ?? 0,
      earlyRiskCount: result.counts[AppConstants.classEarlyRisk] ?? 0,
      spoiledCount: result.counts[AppConstants.classSpoiled] ?? 0,
      dominantClass: result.dominant,
      recommendation: result.recommendation,
      recommendationSource: 'ai',
    ));
  }

  Future<List<Map<String, dynamic>>> getAllScans() =>
      _guard((db) => db.query('scans', orderBy: 'timestamp DESC'));
}
