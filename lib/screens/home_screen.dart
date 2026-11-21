import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/utils/constants.dart';
import '../core/utils/formatter.dart';
import '../providers/app_provider.dart';
import '../providers/machine_provider.dart';
import '../providers/sales_provider.dart';
import '../providers/security_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../theme/app_theme.dart';
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

  // --- القائمة الجانبية (Drawer) ---
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppTheme.primaryDarkGreen,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                Text(
                  'Fazlaka Pay',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'الإصدار 1.0.0',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('الإعدادات'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('مشاركة واتساب'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.save_alt),
            title: const Text('تصدير JSON'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('استيراد'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock, color: Colors.red),
            title: const Text('قفل البرنامج', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context); // غلق الدرج
              context.read<SecurityProvider>().lockApp();
            },
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
          // كروت الإحصائيات
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
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
          const SizedBox(height: 24),

          // قسم المكن (شبيه بتصميم الأول)
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              margin: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryDarkGreen.withOpacity(0.05), Colors.white],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryDarkGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.atm, color: AppTheme.primaryDarkGreen),
                  ),
                  title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('الحد: ${AppFormatter.fmt(m.limit)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppFormatter.fmt(m.balance),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primaryDarkGreen),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.grey),
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
          ),

          const SizedBox(height: 16),

          // قسم المحافظ
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.wallet, color: Colors.blueGrey),
                title: Text(w.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('حد السحب: ${AppFormatter.fmt(w.outLimit)}'),
                trailing: Text(
                  AppFormatter.fmt(w.balance),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
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
    
    // الشاشات اللي هتتنقل بينها من الشريط السفلي
    final pages = [
      _buildOverviewTab(),
      const PosScreen(),
      _buildOverviewTab(), // مؤقتاً لحد ما نعمل شاشة المحافظ منفصلة
      const ReportsScreen(),
    ];

    return Scaffold(
      // ضفنا القائمة الجانبية
      drawer: _buildDrawer(),
      
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
            onPressed: () => context.read<SecurityProvider>().lockApp(),
          ),
        ],
      ),
      body: pages[_currentIndex],
      
      // الزرار العايم (Floating Action Button) زي الأول
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // ممكن نخليه يفتح نافذة إضافة عملية جديدة
          // _showAddTransactionDialog(); 
        },
        backgroundColor: AppTheme.primaryDarkGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),

      // شريط التنقل السفلي (بقى 4 تابات)
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.secondaryMint.withOpacity(0.3),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.atm), label: 'المكان'),
          NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'المبيعات'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'المحافظ'),
          NavigationDestination(icon: Icon(Icons.analytics), label: 'التقارير'),
        ],
      ),
    );
  }
}
