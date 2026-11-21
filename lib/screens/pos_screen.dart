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
            to:
