import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/utils/formatter.dart';
import '../providers/app_provider.dart';
import '../providers/machine_provider.dart';
import '../providers/sales_provider.dart';
import '../providers/security_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../theme/app_theme.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.primaryDarkGreen,
      ),
    );
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

  // شكل موحد للكروت
  Widget _buildSectionCard({required Widget child}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final txnProv = context.watch<TransactionProvider>();
    final salesProv = context.watch<SalesProvider>();
    final secProv = context.watch<SecurityProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. ملخص اليوم (بتصميم بارز زي الأول)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primaryDarkGreen,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryDarkGreen.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ملخص اليوم',
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryItem('المبيعات', AppFormatter.fmt(salesProv.todaySales)),
                  _buildSummaryItem('الأرباح', AppFormatter.fmt(salesProv.todayProfit)),
                  _buildSummaryItem('العمليات', '${salesProv.opsCount}'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. إعدادات الأمان
        _buildSectionCard(
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: AppTheme.primaryDarkGreen,
            title: const Text('قفل التطبيق بالبصمة', style: TextStyle(fontWeight: FontWeight.bold)),
            secondary: const Icon(Icons.fingerprint, color: AppTheme.primaryDarkGreen),
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

        // 3. النسخ الاحتياطي
        _buildSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.backup, color: AppTheme.primaryDarkGreen),
                  SizedBox(width: 8),
                  Text('النسخ الاحتياطي والاستعادة (JSON)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryDarkGreen,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _exportBackup,
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('تصدير'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryDarkGreen,
                        side: const BorderSide(color: AppTheme.primaryDarkGreen),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _restoreBackup,
                      icon: const Icon(Icons.upload, size: 18),
                      label: const Text('استعادة'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // زر تصدير CSV (زي الأول)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blueGrey,
                  side: BorderSide(color: Colors.blueGrey.shade200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  _notify('سيتم تفعيل تصدير CSV قريباً');
                },
                icon: const Icon(Icons.file_present, size: 18),
                label: const Text('تصدير البيانات كـ CSV'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _backupCtrl,
                maxLines: 4,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'الصق بيانات JSON هنا للاستعادة...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ],
          ),
        ),

        // 4. سجل التدقيق (Audit Log)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('سجل العمليات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Chip(
              label: Text('${txnProv.auditLogs.length} عملية'),
              backgroundColor: AppTheme.secondaryMint.withOpacity(0.3),
              labelStyle: const TextStyle(color: AppTheme.primaryDarkGreen, fontSize: 12),
              side: BorderSide.none,
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...txnProv.auditLogs.map(
          (log) => Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade100,
                child: const Icon(Icons.history, color: Colors.grey, size: 20),
              ),
              title: Text(log.action, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(log.details, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ),
          ),
        ),
      ],
    );
  }

  // ويدجت مساعدة لملخص اليوم
  Widget _buildSummaryItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
