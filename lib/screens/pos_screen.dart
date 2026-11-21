import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/utils/formatter.dart';
import '../models/wallet.dart';
import '../providers/sales_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _prodNameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _buyCtrl = TextEditingController();
  final _sellCtrl = TextEditingController();

  final _transferAmtCtrl = TextEditingController();
  final _transferCommCtrl = TextEditingController(text: '0');
  Wallet? _fromWallet;
  Wallet? _toWallet;

  final _debtCtrl = TextEditingController();

  @override
  void dispose() {
    _prodNameCtrl.dispose();
    _qtyCtrl.dispose();
    _buyCtrl.dispose();
    _sellCtrl.dispose();
    _transferAmtCtrl.dispose();
    _transferCommCtrl.dispose();
    _debtCtrl.dispose();
    super.dispose();
  }

  void _notify(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submitSale() async {
    try {
      final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
      final buy = double.tryParse(_buyCtrl.text.trim()) ?? -1;
      final sell = double.tryParse(_sellCtrl.text.trim()) ?? -1;

      await context.read<SalesProvider>().addProductSale(
            name: _prodNameCtrl.text,
            qty: qty,
            buy: buy,
            sell: sell,
          );
      _prodNameCtrl.clear();
      _buyCtrl.clear();
      _sellCtrl.clear();
      _qtyCtrl.text = '1';
      _notify('تم تسجيل عملية البيع بنجاح');
    } catch (e) {
      _notify(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _submitTransfer() async {
    try {
      if (_fromWallet == null || _toWallet == null) {
        throw Exception('اختر المحفظة المرسلة والمستلمة');
      }
      final amt = double.tryParse(_transferAmtCtrl.text.trim()) ?? 0;
      final comm = double.tryParse(_transferCommCtrl.text.trim()) ?? 0;

      await context.read<WalletProvider>().transferBetweenWallets(
            from: _fromWallet!,
            to: _toWallet!,
            amount: amt,
            commission: comm,
          );
      _transferAmtCtrl.clear();
      _transferCommCtrl.text = '0';
      await context.read<SalesProvider>().loadSalesAndStats();
      _notify('تم تنفيذ التحويل بنجاح');
    } catch (e) {
      _notify(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _submitDebts() async {
    try {
      final val = double.tryParse(_debtCtrl.text.trim()) ?? -1;
      await context.read<TransactionProvider>().updateDebts(val);
      _debtCtrl.clear();
      _notify('تم تحديث الديون');
    } catch (e) {
      _notify(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallets = context.watch<WalletProvider>().wallets;
    final txns = context.watch<SalesProvider>().txns;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('تسجيل بيع منتج', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 10),
                TextField(controller: _prodNameCtrl, decoration: const InputDecoration(labelText: 'اسم المنتج')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'الكمية'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _buyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'سعر الشراء'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _sellCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'سعر البيع'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton(onPressed: _submitSale, child: const Text('إتمام البيع')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('تحويل بين المحافظ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 10),
                DropdownButtonFormField<Wallet>(
                  value: _fromWallet,
                  hint: const Text('من محفظة'),
                  items: wallets
                      .map((w) => DropdownMenuItem(value: w, child: Text('${w.name} (${AppFormatter.fmt(w.balance)})')))
                      .toList(),
                  onChanged: (v) => setState(() => _fromWallet = v),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<Wallet>(
                  value: _toWallet,
                  hint: const Text('إلى محفظة'),
                  items: wallets
                      .map((w) => DropdownMenuItem(value: w, child: Text('${w.name} (${AppFormatter.fmt(w.balance)})')))
                      .toList(),
                  onChanged: (v) => setState(() => _toWallet = v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _transferAmtCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'المبلغ'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _transferCommCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'العمولة'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton(onPressed: _submitTransfer, child: const Text('تنفيذ التحويل')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('تحديث إجمالي الديون', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 10),
                TextField(
                  controller: _debtCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'إجمالي الديون الحالي'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(onPressed: _submitDebts, child: const Text('تحديث الديون')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('آخر المعاملات', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 8),
        ...txns.take(20).map(
              (t) => Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  title: Text(t.title),
                  subtitle: Text('${t.type} • ${t.date}'),
                  trailing: Text(
                    AppFormatter.fmt(t.amount),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}
