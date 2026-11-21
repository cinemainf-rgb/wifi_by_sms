import 'package:flutter/foundation.dart';
import '../core/database/db_service.dart';
import '../core/utils/constants.dart';
import '../core/utils/formatter.dart';
import '../core/utils/helpers.dart';
import '../models/wallet.dart';

class WalletProvider extends ChangeNotifier {
  final DbService _dbService = DbService.instance;

  List<Wallet> wallets = [];

  double get totalWalletsBalance =>
      wallets.fold(0.0, (sum, w) => sum + w.balance);

  Wallet? getWalletByName(String name) {
    final target = name.trim();
    try {
      return wallets.firstWhere((w) => w.name.trim() == target);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadWallets() async {
    final db = await _dbService.database;
    final rows = await db.query('wallets', orderBy: 'id ASC');
    wallets = rows.map((r) => Wallet.fromMap(r)).toList();
    notifyListeners();
  }

  Future<void> addWallet(String name, double balance, {double? outLimit}) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw Exception('اسم المحفظة مطلوب');
    }
    if (balance < 0) {
      throw Exception('لا يمكن تسجيل محفظة برصيد سالب');
    }

    final exists = wallets.any((x) => x.name.trim() == cleanName);
    if (exists) {
      throw Exception('المحفظة موجودة مسبقاً');
    }

    final db = await _dbService.database;
    final existingRows = await db.query(
      'wallets',
      where: 'TRIM(name) = ?',
      whereArgs: [cleanName],
      limit: 1,
    );
    if (existingRows.isNotEmpty) {
      throw Exception('المحفظة موجودة مسبقاً');
    }

    final resolvedLimit = outLimit ?? AppHelpers.limitForWallet(cleanName);
    if (resolvedLimit < 0) {
      throw Exception('لا يمكن تسجيل حد سحب سالب');
    }

    await db.transaction((txn) async {
      await txn.insert('wallets', {
        'name': cleanName,
        'balance': balance,
        'outLimit': resolvedLimit,
      });
      await _dbService.logAction(
        'WALLET_ADD',
        'إضافة محفظة "$cleanName" برصيد $balance',
        executor: txn,
      );
    });

    await loadWallets();
  }
  Future<void> updateWallet(Wallet w) async {
    if (w.id == null) return;
    final cleanName = w.name.trim();
    if (cleanName.isEmpty) {
      throw Exception('اسم المحفظة مطلوب');
    }
    if (w.balance < 0 || w.outLimit < 0) {
      throw Exception('لا يمكن تحديث رصيد أو حد بقيمة سالبة');
    }

    final duplicate = wallets.any(
      (x) => x.id != w.id && x.name.trim() == cleanName,
    );
    if (duplicate) {
      throw Exception('المحفظة موجودة مسبقاً');
    }

    final db = await _dbService.database;
    await db.transaction((txn) async {
      await txn.update(
        'wallets',
        {
          'name': cleanName,
          'balance': w.balance,
          'outLimit': w.outLimit,
        },
        where: 'id = ?',
        whereArgs: [w.id],
      );
      await _dbService.logAction(
        'WALLET_UPDATE',
        'تحديث محفظة "$cleanName" (ID: ${w.id}) إلى رصيد ${w.balance}',
        executor: txn,
      );
    });

    await loadWallets();
  }

  Future<void> deleteWallet(Wallet w) async {
    if (w.id == null) return;
    if (w.name == AppConstants.drawerName || w.name == AppConstants.safeName) {
      throw Exception('لا يمكن حذف "${w.name}"');
    }

    final db = await _dbService.database;
    await db.transaction((txn) async {
      await txn.delete('wallets', where: 'id = ?', whereArgs: [w.id]);
      await _dbService.logAction(
        'WALLET_DELETE',
        'حذف محفظة "${w.name}" (ID: ${w.id})',
        executor: txn,
      );
    });

    await loadWallets();
  }

  Future<void> transferBetweenWallets({
    required Wallet from,
    required Wallet to,
    required double amount,
    double commission = 0,
    String note = '',
  }) async {
    if (from.id == null || to.id == null || from.id == to.id) {
      throw Exception('اختر محفظتين مختلفتين للتحويل');
    }
    if (amount <= 0 || commission < 0) {
      throw Exception('قيمة التحويل غير صحيحة');
    }

    final totalDeduction = amount + commission;
    if (from.balance < totalDeduction) {
      throw Exception('رصيد المحفظة المرسلة غير كافٍ');
    }

    final newFromBalance = from.balance - totalDeduction;
    final newToBalance = to.balance + amount;
    if (newFromBalance < 0 || newToBalance < 0) {
      throw Exception('الرصيد لا يمكن أن يكون سالباً');
    }

    final db = await _dbService.database;
    await db.transaction((txn) async {
      await txn.update(
        'wallets',
        {'balance': newFromBalance},
        where: 'id = ?',
        whereArgs: [from.id],
      );
      await txn.update(
        'wallets',
        {'balance': newToBalance},
        where: 'id = ?',
        whereArgs: [to.id],
      );

      final title = note.trim().isEmpty
          ? 'تحويل من ${from.name} إلى ${to.name}'
          : '${note.trim()} (${from.name} -> ${to.name})';

      await txn.insert('txns', {
        'title': title,
        'amount': amount,
        'profit': commission,
        'type': 'تحويل محافظ',
        'date': AppFormatter.todayStr(),
      });

      await txn.rawUpdate(
        'UPDATE daily_stats SET today_profit = today_profit + ?, ops_count = ops_count + 1 WHERE id = 1',
        [commission],
      );

      await _dbService.logAction(
        'WALLET_TRANSFER',
        'تحويل $amount من "${from.name}" إلى "${to.name}" (عمولة: $commission)',
        executor: txn,
      );
    });

    await loadWallets();
  }
}
