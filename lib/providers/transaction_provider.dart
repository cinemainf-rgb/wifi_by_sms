import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/database/db_service.dart';
import '../core/utils/formatter.dart';

class AuditEntry {
  final int id;
  final String action;
  final String details;
  final int createdAt;

  AuditEntry({
    required this.id,
    required this.action,
    required this.details,
    required this.createdAt,
  });

  factory AuditEntry.fromMap(Map<String, dynamic> m) => AuditEntry(
        id: m['id'] as int,
        action: (m['action'] as String?) ?? '',
        details: (m['details'] as String?) ?? '',
        createdAt: (m['created_at'] as num? ?? 0).toInt(),
      );
}

class TransactionProvider extends ChangeNotifier {
  final DbService _dbService = DbService.instance;

  double debts = 0;
  List<AuditEntry> auditLogs = [];

  Future<void> loadDebtsAndAudit() async {
    final db = await _dbService.database;

    final statsRows = await db.query('daily_stats', where: 'id = 1', limit: 1);
    if (statsRows.isNotEmpty) {
      debts = (statsRows.first['debts'] as num? ?? 0).toDouble();
    }

    final logRows = await db.query('audit_log', orderBy: 'id DESC', limit: 200);
    auditLogs = logRows.map((r) => AuditEntry.fromMap(r)).toList();

    notifyListeners();
  }

  Future<void> updateDebts(double newDebts, {String note = ''}) async {
    if (newDebts < 0) {
      throw Exception('الديون لا يمكن أن تكون سالبة');
    }

    final db = await _dbService.database;
    await db.transaction((txn) async {
      await txn.update(
        'daily_stats',
        {'debts': newDebts},
        where: 'id = 1',
      );
      await txn.insert('txns', {
        'title': note.trim().isEmpty ? 'تحديث إجمالي الديون' : note.trim(),
        'amount': newDebts,
        'profit': 0,
        'type': 'ديون',
        'date': AppFormatter.todayStr(),
      });
      await _dbService.logAction(
        'DEBTS_UPDATE',
        'تحديث الديون إلى $newDebts ${note.trim().isEmpty ? '' : '- ${note.trim()}'}',
        executor: txn,
      );
    });

    await loadDebtsAndAudit();
  }

  Future<String> exportAsJson() async {
    final db = await _dbService.database;
    final machines = await db.query('machines');
    final wallets = await db.query('wallets');
    final txns = await db.query('txns');
    final sales = await db.query('sales');
    final dailyStats = await db.query('daily_stats');
    final auditLog = await db.query('audit_log', orderBy: 'id DESC', limit: 500);

    final payload = {
      'app': 'Fazlaka Pay',
      'exported_at': DateTime.now().toIso8601String(),
      'machines': machines,
      'wallets': wallets,
      'txns': txns,
      'sales': sales,
      'daily_stats': dailyStats,
      'audit_log': auditLog,
    };

    await _dbService.logAction('BACKUP_EXPORT', 'تم تصدير نسخة احتياطية بصيغة JSON');
    return jsonEncode(payload);
  }

  Future<void> restoreBackup(String jsonData) async {
    if (jsonData.trim().isEmpty) {
      throw Exception('بيانات النسخة الاحتياطية فارغة');
    }

    final dynamic decoded = jsonDecode(jsonData);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('صيغة ملف النسخة الاحتياطية غير صحيحة');
    }

    final machines = decoded['machines'];
    final wallets = decoded['wallets'];
    if (machines is! List || wallets is! List) {
      throw Exception('ملف النسخة الاحتياطية يفتقد لبيانات المكن أو المحافظ');
    }

    final db = await _dbService.database;
    await db.transaction((txn) async {
      await txn.delete('machines');
      for (final item in machines) {
        if (item is Map<String, dynamic>) {
          final balance = (item['balance'] as num? ?? 0).toDouble();
          final limitVal = (item['limit_val'] as num? ?? 200000).toDouble();
          if (balance < 0 || limitVal < 0) {
            throw Exception('النسخة الاحتياطية تحتوي على رصيد أو حد سالب');
          }
          await txn.insert('machines', {
            'name': (item['name'] ?? 'مكنة').toString(),
            'balance': balance,
            'limit_val': limitVal,
          });
        }
      }

      await txn.delete('wallets');
      final seenNames = <String>{};
      for (final item in wallets) {
        if (item is Map<String, dynamic>) {
          final wName = (item['name'] ?? '').toString().trim();
          final balance = (item['balance'] as num? ?? 0).toDouble();
          final outLimit = (item['outLimit'] as num? ?? 200000).toDouble();
          if (wName.isEmpty || seenNames.contains(wName)) {
            throw Exception('اسم محفظة مكرر أو فارغ في النسخة الاحتياطية');
          }
          if (balance < 0 || outLimit < 0) {
            throw Exception('النسخة الاحتياطية تحتوي على رصيد محفظة سالب');
          }
          seenNames.add(wName);
          await txn.insert('wallets', {
            'name': wName,
            'balance': balance,
            'outLimit': outLimit,
          });
        }
      }

      final txns = decoded['txns'];
      if (txns is List) {
        await txn.delete('txns');
        for (final item in txns) {
          if (item is Map<String, dynamic>) {
            await txn.insert('txns', {
              'title': (item['title'] ?? '').toString(),
              'amount': (item['amount'] as num? ?? 0).toDouble(),
              'profit': (item['profit'] as num? ?? 0).toDouble(),
              'type': (item['type'] ?? 'عام').toString(),
              'date': (item['date'] ?? AppFormatter.todayStr()).toString(),
            });
          }
        }
      }

      final sales = decoded['sales'];
      if (sales is List) {
        await txn.delete('sales');
        for (final item in sales) {
          if (item is Map<String, dynamic>) {
            await txn.insert('sales', {
              'name': (item['name'] ?? '').toString(),
              'qty': (item['qty'] as num? ?? 1).toInt(),
              'buy': (item['buy'] as num? ?? 0).toDouble(),
              'sell': (item['sell'] as num? ?? 0).toDouble(),
              'date': (item['date'] ?? AppFormatter.todayStr()).toString(),
            });
          }
        }
      }

      final stats = decoded['daily_stats'];
      if (stats is List && stats.isNotEmpty && stats.first is Map<String, dynamic>) {
        final s = stats.first as Map<String, dynamic>;
        await txn.update(
          'daily_stats',
          {
            'stat_date': (s['stat_date'] ?? AppFormatter.todayStr()).toString(),
            'today_sales': (s['today_sales'] as num? ?? 0).toDouble(),
            'today_profit': (s['today_profit'] as num? ?? 0).toDouble(),
            'debts': (s['debts'] as num? ?? 0).toDouble(),
            'ops_count': (s['ops_count'] as num? ?? 0).toInt(),
            'is_dark': (s['is_dark'] as num? ?? 0).toInt(),
          },
          where: 'id = 1',
        );
      }

      await _dbService.logAction(
        'BACKUP_RESTORE',
        'تم استعادة نسخة احتياطية بنجاح',
        executor: txn,
      );
    });

    await loadDebtsAndAudit();
  }
}
