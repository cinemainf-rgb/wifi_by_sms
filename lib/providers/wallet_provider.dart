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
