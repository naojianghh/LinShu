import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/diagnosis_report.dart';

class DiagnosisReportDb {
  DiagnosisReportDb._();

  static final DiagnosisReportDb instance = DiagnosisReportDb._();

  static const _dbName = 'lingshu_reports.db';
  static const _tableName = 'diagnosis_reports';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, _dbName);

    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName(
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            date TEXT NOT NULL,
            constitution TEXT NOT NULL,
            pattern TEXT NOT NULL,
            dietaryAdvice TEXT NOT NULL,
            lifestyleAdvice TEXT NOT NULL,
            exerciseAdvice TEXT NOT NULL,
            riskWarning TEXT NOT NULL,
            imageUrl TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertReport(DiagnosisReport report) async {
    final db = await database;
    await db.insert(
      _tableName,
      report.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DiagnosisReport>> getReports({int limit = 20}) async {
    final db = await database;
    final maps = await db.query(_tableName, orderBy: 'date DESC', limit: limit);
    return maps.map(DiagnosisReport.fromMap).toList();
  }
}
