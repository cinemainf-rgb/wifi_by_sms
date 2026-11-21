import 'package:flutter/foundation.dart';
import '../core/database/db_service.dart';
import '../core/utils/formatter.dart';
import '../models/product_sale.dart';
import '../models/txn_item.dart';

class SalesProvider extends ChangeNotifier {
  final DbService _dbService = DbService.instance;

  List<ProductSale> sales = [];
  List<TxnItem> txns = [];

  double todaySales = 0;
  double todayProfit = 0;
  int opsCount = 0;

  Future<void> loadSalesAndStats() async {
    final db = await _dbService.database;

    final saleRows = await db.query('sales', orderBy: 'id DESC');
    sales = saleRows.map((r) => ProductSale.fromMap(r)).toList();

    final txnRows = await db.query('txns', orderBy: 'id DESC');
    txns = txnRows.map((r) => TxnItem.fromMap(r)).toList();

    final statsRows = await db.query('daily_stats', where: 'id = 1', limit: 1);
    if (statsRows.isNotEmpty) {
      final s = statsRows.first;
      todaySales = (s['today_sales'] as num? ?? 0).toDouble();
      todayProfit = (s['today_profit'] as num? ?? 0).toDouble();
      opsCount = (s['ops_count'] as num? ?? 0).toInt();
    }

    notifyListeners();
  }

  Future<void> addProductSale({
    required String name,
    required int qty,
    required double buy,
    required double sell,
    int? creditWalletId,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw Exception('اسم المنتج مطلوب');
    }
    if (qty <= 0) {
      throw Exception('الكمية يجب أن تكون أكبر من صفر');
    }
    if (buy < 0 || sell < 0) {
      throw Exception('سعر الشراء أو البيع لا يمكن أن يكون سالباً');
    }

    final totalAmount = sell * qty;
    final profit = (sell - buy) * qty;
    final today = AppFormatter.todayStr();

    final db = await _dbService.database;
    await db.transaction((txn) async {
      await txn.insert('sales', {
        'name': cleanName,
        'qty': qty,
        'buy': buy,
        'sell': sell,
        'date': today,
      });

      await txn.insert('txns', {
        'title': 'بيع $cleanName (×$qty)',
        'amount': totalAmount,
        'profit': profit,
        'type': 'مبيعات',
        'date': today,
      });

      if (creditWalletId != null) {
        await txn.rawUpdate(
          'UPDATE wallets SET balance = balance + ? WHERE id = ?',
          [totalAmount, creditWalletId],
        );
      }

      await txn.rawUpdate(
        '''
        UPDATE daily_stats
        SET today_sales = today_sales + ?,
            today_profit = today_profit + ?,
            ops_count = ops_count + 1
        WHERE id = 1
        ''',
        [totalAmount, profit],
      );

      await _dbService.logAction(
        'SALE_ADD',
        'بيع "$cleanName" عدد $qty بإجمالي $totalAmount وربح $profit',
        executor: txn,
      );
    });

    await loadSalesAndStats();
  }

  Future<void> addCustomTxn({
    required String title,
    required double amount,
    double profit = 0,
    String type = 'عام',
    int? walletId,
    double walletDelta = 0,
  }) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      throw Exception('بيان العملية مطلوب');
    }
    if (amount <= 0) {
      throw Exception('قيمة العملية يجب أن تكون أكبر من صفر');
    }

    final db = await _dbService.database;
    await db.transaction((txn) async {
      if (walletId != null && walletDelta != 0) {
        final wRows = await txn.query(
          'wallets',
          where: 'id = ?',
          whereArgs: [walletId],
          limit: 1,
        );
        if (wRows.isNotEmpty) {
          final currentBal = (wRows.first['balance'] as num).toDouble();
          final nextBal = currentBal + walletDelta;
          if (nextBal < 0) {
            throw Exception('رصيد المحفظة غير كافٍ');
          }
          await txn.update(
            'wallets',
            {'balance': nextBal},
            where: 'id = ?',
            whereArgs: [walletId],
          );
        }
      }

      await txn.insert('txns', {
        'title': cleanTitle,
        'amount': amount,
        'profit': profit,
        'type': type,
        'date': AppFormatter.todayStr(),
      });

      await txn.rawUpdate(
        '''
        UPDATE daily_stats
        SET today_profit = today_profit + ?,
            ops_count = ops_count + 1
        WHERE id = 1
        ''',
        [profit],
      );

      await _dbService.logAction(
        'TXN_ADD',
        'عملية "$cleanTitle" بقيمة $amount (نوع: $type، ربح: $profit)',
        executor: txn,
      );
    });

    await loadSalesAndStats();
  }
}
