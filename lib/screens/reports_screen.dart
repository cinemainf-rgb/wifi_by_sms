import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/utils/formatter.dart';
import '../providers/app_provider.dart';
import '../providers/machine_provider.dart';
import '../providers/sales_provider.dart';
import '../providers/security_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final TextEditingController _backupCtrl = TextEditingController();

  @override
  void dispose() {
    _backupCtrl.dispose();
    super.dispose();
  }

  void _notify(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _exportBackup() async {
    final jsonStr = await context.read<TransactionProvider>().exportAsJson();
    _backupCtrl.text = jsonStr;
    await Clipboard.setData(ClipboardData(text: jsonStr));
    _notify('تم تصدير النسخة الاحتياطية ونسخها للحافظة');
  }

  Future<void> _restoreBackup() async {
    try {
      await context.read<TransactionProvider>().restoreBackup(_backupCtrl.text);
      if (!mounted) return;
      await context.read<AppProvider>().initAll(
            machineProvider: context.read<MachineProvider>(),
            walletProvider: context.read<WalletProvider>(),
            salesProvider: context.read<SalesProvider>(),
            transactionProvider: context.read<TransactionProvider>(),
            securityProvider: context.read<SecurityProvider>(),
          );
      _notify('تمت استعادة النسخة الاحتياطية بنجاح');
    } catch (e) {
      _notify(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final txnProv = context.watch<TransactionProvider>();
    final salesProv = context.watch<SalesProvider>();
    final secProv = context.watch<SecurityProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ملخص اليوم', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 8),
                Text('المبيعات: ${AppFormatter.fmt(salesProv.todaySales)}'),
                Text('الأرباح والعمولات: ${AppFormatter.fmt(salesProv.todayProfit)}'),
                Text('عدد العمليات: ${salesProv.opsCount}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          child: SwitchListTile(
            title: const Text('قفل التطبيق بالبصمة'),
            value: secProv.biometricEnabled,
            onChanged: (val) async {
              try {
                await secProv.setBiometricEnabled(val);
              } catch (e) {
                _notify(e.toString().replaceFirst('Exception: ', ''));
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('النسخ الاحتياطي والاستعادة (JSON)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _exportBackup,
                        icon: const Icon(Icons.download),
                        label: const Text('تصدير نسخة'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _restoreBackup,
                        icon: const Icon(Icons.upload),
                        label: const Text('استعادة نسخة'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _backupCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'الصق بيانات JSON هنا للاستعادة أو اعرض النسخة المصدرة',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('سجل التدقيق (Audit Log)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 8),
        ...txnProv.auditLogs.map(
          (log) => Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: Text(log.action, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(log.details),
            ),
          ),
        ),
      ],
    );
  }
}
