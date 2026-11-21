import 'package:flutter/foundation.dart';
import '../core/database/db_service.dart';
import '../core/utils/formatter.dart';
import 'machine_provider.dart';
import 'sales_provider.dart';
import 'security_provider.dart';
import 'transaction_provider.dart';
import 'wallet_provider.dart';

class AppProvider extends ChangeNotifier {
  final DbService _dbService = DbService.instance;

  bool isDark = false;
  bool isInitialized = false;
  String statDate = AppFormatter.todayStr();

  Future<void> initAll({
    required MachineProvider machineProvider,
    required WalletProvider walletProvider,
    required SalesProvider salesProvider,
    required TransactionProvider transactionProvider,
    required SecurityProvider securityProvider,
  }) async {
    final db = await _dbService.database;
    final statsRows = await db.query('daily_stats', where: 'id = 1', limit: 1);
    final today = AppFormatter.todayStr();

    if (statsRows.isNotEmpty) {
      final row = statsRows.first;
      isDark = ((row['is_dark'] as int?) ?? 0) == 1;
      final savedDate = (row['stat_date'] as String?) ?? today;

      if (savedDate != today) {
        await db.transaction((txn) async {
          await txn.update(
            'daily_stats',
            {
              'stat_date': today,
              'today_sales': 0,
              'today_profit': 0,
              'ops_count': 0,
            },
            where: 'id = 1',
          );
          await _dbService.logAction(
            'DAILY_RESET',
            'تجديد العدادات اليومية ليوم $today (كان $savedDate)',
            executor: txn,
          );
        });
        statDate = today;
      } else {
        statDate = savedDate;
      }
    }

    await securityProvider.loadSecurity();
    await Future.wait([
      machineProvider.loadMachines(),
      walletProvider.loadWallets(),
      salesProvider.loadSalesAndStats(),
      transactionProvider.loadDebtsAndAudit(),
    ]);

    isInitialized = true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    isDark = !isDark;
    final db = await _dbService.database;
    await db.update(
      'daily_stats',
      {'is_dark': isDark ? 1 : 0},
      where: 'id = 1',
    );
    notifyListeners();
  }
}
