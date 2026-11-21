import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/utils/formatter.dart';
import '../models/wallet.dart';
import '../providers/sales_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../theme/app_theme.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.primaryDarkGreen,
      ),
    );
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

  // شكل موحد للخانات عشان تبقى شيك
  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.primaryDarkGreen, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallets = context.watch<WalletProvider>().wallets;
    final txns = context.watch<SalesProvider>().txns;

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          // التبويبات (بيع سريع، تحويل، ديون، السجل)
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                color: AppTheme.primaryDarkGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade700,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'بيع سريع'),
                Tab(text: 'تحويل'),
                Tab(text: 'ديون'),
                Tab(text: 'السجل'),
              ],
            ),
          ),

          // محتوى التبويبات
          Expanded(
            child: TabBarView(
              children: [
                // 1. تبويب البيع السريع
                ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('تسجيل بيع منتج', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryDarkGreen)),
                            const SizedBox(height: 16),
                            TextField(controller: _prodNameCtrl, decoration: _buildInputDecoration('اسم المنتج')),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _qtyCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: _buildInputDecoration('الكمية'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _buyCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: _buildInputDecoration('سعر الشراء'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _sellCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: _buildInputDecoration('سعر البيع'),
                            ),
                            const SizedBox(height: 20),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.primaryDarkGreen,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _submitSale, 
                              child: const Text('إتمام البيع', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // 2. تبويب التحويل
                ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('تحويل بين المحافظ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryDarkGreen)),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<Wallet>(
                              value: _fromWallet,
                              decoration: _buildInputDecoration('من محفظة'),
                              items: wallets
                                  .map((w) => DropdownMenuItem(value: w, child: Text('${w.name} (${AppFormatter.fmt(w.balance)})')))
                                  .toList(),
                              onChanged: (v) => setState(() => _fromWallet = v),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<Wallet>(
                              value: _toWallet,
                              decoration: _buildInputDecoration('إلى محفظة'),
                              items: wallets
                                  .map((w) => DropdownMenuItem(value: w, child: Text('${w.name} (${AppFormatter.fmt(w.balance)})')))
                                  .toList(),
                              onChanged: (v) => setState(() => _toWallet = v),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _transferAmtCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: _buildInputDecoration('المبلغ'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _transferCommCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: _buildInputDecoration('العمولة'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.primaryDarkGreen,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _submitTransfer, 
                              child: const Text('تنفيذ التحويل', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // 3. تبويب الديون
                ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('تحديث إجمالي الديون', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryDarkGreen)),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _debtCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: _buildInputDecoration('إجمالي الديون الحالي'),
                            ),
                            const SizedBox(height: 20),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryDarkGreen,
                                side: const BorderSide(color: AppTheme.primaryDarkGreen),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _submitDebts, 
                              child: const Text('تحديث الديون', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // 4. تبويب السجل (آخر المعاملات)
                ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    const SizedBox(height: 10),
                    ...txns.take(20).map(
                          (t) => Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.secondaryMint.withOpacity(0.3),
                                child: const Icon(Icons.receipt_long, color: AppTheme.primaryDarkGreen, size: 20),
                              ),
                              title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text('${t.type} • ${t.date}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              trailing: Text(
                                AppFormatter.fmt(t.amount),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDarkGreen),
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
