import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../core/utils/constants.dart';
import '../core/utils/formatter.dart';
import '../providers/app_provider.dart';
import '../providers/machine_provider.dart';
import '../providers/sales_provider.dart';
import '../providers/security_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_card.dart';
import 'pos_screen.dart';
import 'reports_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _showError(Object e) {
    if (!mounted) return;
    final msg = e.toString().replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _showAddWalletDialog() async {
    final nameCtrl = TextEditingController();
    final balCtrl = TextEditingController(text: '0');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة محفظة جديدة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'اسم المحفظة'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: balCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'الرصيد الابتدائي'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                final bal = double.tryParse(balCtrl.text.trim()) ?? -1;
                await context.read<WalletProvider>().addWallet(nameCtrl.text, bal);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                _showError(e);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddMachineDialog() async {
    final nameCtrl = TextEditingController();
    final balCtrl = TextEditingController(text: '0');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة مكنة جديدة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'اسم المكنة'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: balCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'الرصيد الابتدائي'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                final bal = double.tryParse(balCtrl.text.trim()) ?? -1;
                await context.read<MachineProvider>().addMachine(nameCtrl.text, bal);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                _showError(e);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final app = context.watch<AppProvider>();
    final machinesProv = context.watch<MachineProvider>();
    final walletsProv = context.watch<WalletProvider>();
    final salesProv = context.watch<SalesProvider>();
    final txnProv = context.watch<TransactionProvider>();

    return RefreshIndicator(
      onRefresh: () => app.initAll(
        machineProvider: machinesProv,
        walletProvider: walletsProv,
        salesProvider: salesProv,
        transactionProvider: txnProv,
        securityProvider: context.read<SecurityProvider>(),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: [
              StatCard(
                title: 'إجمالي المكن',
                value: AppFormatter.fmt(machinesProv.totalMachinesBalance),
                icon: Icons.point_of_sale,
              ),
              StatCard(
                title: 'إجمالي المحافظ',
                value: AppFormatter.fmt(walletsProv.totalWalletsBalance),
                icon: Icons.account_balance_wallet,
              ),
              StatCard(
                title: 'مبيعات اليوم',
                value: AppFormatter.fmt(salesProv.todaySales),
                icon: Icons.trending_up,
              ),
              StatCard(
                title: 'الديون',
                value: AppFormatter.fmt(txnProv.debts),
                icon: Icons.receipt_long,
                accentColor: Colors.red.shade700,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SectionHeader(
            title: 'المحافظ (${walletsProv.wallets.length})',
            trailing: TextButton.icon(
              onPressed: _showAddWalletDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('إضافة'),
            ),
          ),
          const SizedBox(height: 8),
          ...walletsProv.wallets.map(
            (w) => Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.wallet),
                title: Text(w.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('حد السحب: ${AppFormatter.fmt(w.outLimit)}'),
                trailing: Text(
                  AppFormatter.fmt(w.balance),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SectionHeader(
            title: 'المكن (${machinesProv.machines.length})',
            trailing: TextButton.icon(
              onPressed: _showAddMachineDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('إضافة'),
            ),
          ),
          const SizedBox(height: 8),
          ...machinesProv.machines.map(
            (m) => Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.devices),
                title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('الحد: ${AppFormatter.fmt(m.limit)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppFormatter.fmt(m.balance),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        try {
                          await context.read<MachineProvider>().deleteMachine(m);
                        } catch (e) {
                          _showError(e);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final security = context.read<SecurityProvider>();

    final pages = [
      _buildOverviewTab(),
      const PosScreen(),
      const ReportsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appNameAr),
        actions: [
          IconButton(
            tooltip: 'تبديل الوضع الليلي/النهاري',
            icon: Icon(app.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => app.toggleTheme(),
          ),
          IconButton(
            tooltip: 'قفل التطبيق',
            icon: const Icon(Icons.lock_outline),
            onPressed: () => security.lockApp(),
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.point_of_sale), label: 'المعاملات'),
          NavigationDestination(icon: Icon(Icons.analytics_outlined), label: 'التقارير والسجل'),
        ],
      ),
    );
  }
}
