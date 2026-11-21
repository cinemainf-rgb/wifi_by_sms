import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p_path;
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../utils/constants.dart';
import '../utils/formatter.dart';

class DbService {
  DbService._();
  static final DbService instance = DbService._();

  Database? _db;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<String> _getOrCreateDbPassword() async {
    String? existing = await _secureStorage.read(key: AppConstants.dbKeyStorageKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    final generated = base64UrlEncode(bytes);
    await _secureStorage.write(key: AppConstants.dbKeyStorageKey, value: generated);
    return generated;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final password = await _getOrCreateDbPassword();

    return openDatabase(
      p_path.join(dbPath, AppConstants.dbName),
      password: password,
      version: AppConstants.dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE machines(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            balance REAL,
            limit_val REAL
          )
        ''');

        await db.execute('''
          CREATE TABLE wallets(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE,
            balance REAL,
            outLimit REAL
          )
        ''');

        await db.execute('''
          CREATE TABLE txns(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            amount REAL,
            profit REAL DEFAULT 0,
            type TEXT DEFAULT 'عام',
            date TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE sales(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            qty INTEGER,
            buy REAL,
            sell REAL,
            date TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE daily_stats(
            id INTEGER PRIMARY KEY CHECK (id = 1),
            stat_date TEXT,
            today_sales REAL DEFAULT 0,
            today_profit REAL DEFAULT 0,
            debts REAL DEFAULT 0,
            ops_count INTEGER DEFAULT 0,
            is_dark INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE security(
            id INTEGER PRIMARY KEY CHECK (id = 1),
            pin_hash TEXT,
            salt TEXT,
            biometric_enabled INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE audit_log(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            action TEXT,
            details TEXT,
            created_at INTEGER
          )
        ''');

        await db.insert('machines', {'name': 'فوري رئيسي', 'balance': 4121.5, 'limit_val': 200000});
        await db.insert('machines', {'name': 'فوري كروت', 'balance': 0, 'limit_val': 200000});
        await db.insert('machines', {'name': 'فوري كاش أوت', 'balance': 23000, 'limit_val': 200000});
        await db.insert('machines', {'name': 'بساطة', 'balance': 0, 'limit_val': 200000});
        await db.insert('machines', {'name': 'موبايل', 'balance': 4121.5, 'limit_val': 200000});
        await db.insert('machines', {'name': 'كاش مصر', 'balance': 1162.4, 'limit_val': 200000});

        await db.insert('wallets', {'name': AppConstants.safeName, 'balance': 50000, 'outLimit': 200000});
        await db.insert('wallets', {'name': AppConstants.drawerName, 'balance': 10000, 'outLimit': 200000});
        await db.insert('wallets', {'name': 'إنستاباي', 'balance': 25000, 'outLimit': 400000});
        await db.insert('wallets', {'name': 'فودافون كاش', 'balance': 12000, 'outLimit': 200000});

        await db.insert('daily_stats', {
          'id': 1,
          'stat_date': AppFormatter.todayStr(),
          'today_sales': 0,
          'today_profit': 0,
          'debts': 0,
          'ops_count': 0,
          'is_dark': 0,
        });

        await db.insert('security', {
          'id': 1,
          'pin_hash': null,
          'salt': null,
          'biometric_enabled': 0,
        });

        await db.insert('audit_log', {
          'action': 'DB_INIT',
          'details': 'تم إنشاء وتشفير قاعدة البيانات لأول مرة',
          'created_at': DateTime.now().millisecondsSinceEpoch,
        });
      },
    );
  }

  Future<void> logAction(String action, String details, {DatabaseExecutor? executor}) async {
    final target = executor ?? await database;
    await target.insert('audit_log', {
      'action': action,
      'details': details,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
