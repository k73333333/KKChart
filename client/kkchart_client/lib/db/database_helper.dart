import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// SQLite 本地存储助手，管理全局配置和图表数据
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kkchart.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    Directory docsDirectory = await getApplicationDocumentsDirectory();
    String path = join(docsDirectory.path, filePath);
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 创建配置表 (AI 配置, 导出路径等)
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE NOT NULL,
        value TEXT NOT NULL
      )
    ''');

    // 创建图表数据表
    await db.execute('''
      CREATE TABLE charts (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        option_json TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  /// 获取配置值
  Future<String?> getSetting(String key) async {
    final db = await instance.database;
    final maps = await db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );

    if (maps.isNotEmpty) {
      return maps.first['value'] as String;
    }
    return null;
  }

  /// 保存或更新配置
  Future<void> saveSetting(String key, String value) async {
    final db = await instance.database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 保存新图表
  Future<void> insertChart(Map<String, dynamic> chartData) async {
    final db = await instance.database;
    await db.insert('charts', chartData, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// 获取所有图表列表 (按时间倒序)
  Future<List<Map<String, dynamic>>> getAllCharts() async {
    final db = await instance.database;
    return await db.query('charts', orderBy: 'created_at DESC');
  }

  /// 删除图表
  Future<void> deleteChart(String id) async {
    final db = await instance.database;
    await db.delete('charts', where: 'id = ?', whereArgs: [id]);
  }
}
