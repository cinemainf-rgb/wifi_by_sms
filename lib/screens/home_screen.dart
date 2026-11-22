import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';

import '../core/utils/constants.dart';
import '../core/utils/formatter.dart';
import '../services/printer_service.dart';
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
  
  // متغير عشان نخفي ونظهر الأرقام
  bool _hideBalances = false; 

  void _showError(Object e) {
    if (!mounted) return;
    final msg = e.toString().replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // دالة مساعدة لإخفاء الرقم لو العين مقفولة
  String _formatValue(double value) {
    return _hideBalances ? '****' : AppFormatter.fmt(value);
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
              decoration: const InputDecoration(labelText: 'اسم المحفظة', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: balCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'الرصيد الابتدائي', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryDarkGreen),
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
              decoration: const InputDecoration(labelText: 'اسم المكنة', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: balCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'الرصيد الابتدائي', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryDarkGreen),
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

  // --- دالة عرض الطابعات والاتصال والطباعة ---
  Future<void> _showPrinterSelectionDialog(dynamic machine) async {
    final devices = await PrinterService.getPairedDevices();
    
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('اختر الطابعة'),
        content: devices.isEmpty 
            ? const Text('لا توجد طابعات متصلة بالبلوتوث. يرجى إقران الطابعة من إعدادات الموبايل أولاً.')
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return ListTile(
                      leading: const Icon(Icons.print, color: AppTheme.primaryDarkGreen),
                      title: Text(device.name ?? 'طابعة غير معروفة'),
                      subtitle: Text(device.address ?? ''),
                      onTap: () async {
                        Navigator.pop(ctx); 
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('جاري الاتصال بالطابعة...')),
                        );

                        bool connected = await PrinterService.connect(device);
                        
                        if (connected) {
                          try {
                            await PrinterService.printReceipt(
                              machineName: machine.name,
                              balance: AppFormatter.fmt(machine.balance),
                              limit: AppFormatter.fmt(machine.limit),
                              date: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                            );
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تمت الطباعة بنجاح ✅'), backgroundColor: Colors.green),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                            );
                          }
                        } else {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('فشل الاتصال بالطابعة ❌'), backgroundColor: Colors.red),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  void _showQuickActionMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('إضافة سريعة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet, color: AppTheme.primaryDarkGreen),
                title: const Text('إضافة محفظة جديدة'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddWalletDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.atm, color: AppTheme.primaryDarkGreen),
                title: const Text('إضافة مكنة جديدة'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddMachineDialog();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: AppTheme.primaryDarkGreen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Fazlaka Pay', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                Text('الإصدار 1.0.0', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          ListTile(leading: const Icon(Icons.settings), title: const Text('الإعدادات'), onTap: () {}),
          ListTile(leading: const Icon(Icons.share), title: const Text('مشاركة واتساب'), onTap: () {}),
          ListTile(leading: const Icon(Icons.save_alt), title: const Text('تصدير JSON'), onTap: () {}),
          ListTile(leading: const Icon(Icons.file_download), title: const Text('استيراد'), onTap: () {}),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock, color: Colors.red),
            title: const Text('قفل البرنامج', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
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
      color: AppTheme.primaryDarkGreen,
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
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              StatCard(title: 'إجمالي المكن', value: _formatValue(machinesProv.totalMachinesBalance), icon: Icons.point_of_sale),
              StatCard(title: 'إجمالي المحافظ', value: _formatValue(walletsProv.totalWalletsBalance), icon: Icons.account_balance_wallet),
              StatCard(title: 'مبيعات اليوم', value: _formatValue(salesProv.todaySales), icon: Icons.trending_up),
              StatCard(title: 'الديون', value: _formatValue(txnProv.debts), icon: Icons.receipt_long, accentColor: Colors.red.shade700),
            ],
          ),
          const SizedBox(height: 24),
          
          SectionHeader(
            title: 'المكن (${machinesProv.machines.length})',
            trailing: TextButton.icon(
              onPressed: _showAddMachineDialog,
              icon: const Icon(Icons.add, size: 18, color: AppTheme.primaryDarkGreen),
              label: const Text('إضافة', style: TextStyle(color: AppTheme.primaryDarkGreen)),
            ),
          ),
          const SizedBox(height: 8),

          ...machinesProv.machines.map((m) => _buildMachineCard(m)),
        ],
      ),
    );
  }

  Widget _buildMachineCard(dynamic machine) {
    double maxLimit = machine.limit > 0 ? machine.limit.toDouble() : 200000.0;
    double currentBal = machine.balance.toDouble();
    double progress = (currentBal / maxLimit).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        gradient: LinearGradient(
          colors: [AppTheme.primaryDarkGreen.withOpacity(0.08), Colors.white],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        border: Border.all(color: AppTheme.primaryDarkGreen.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(machine.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('الحد: ${_formatValue(machine.limit.toDouble())}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatValue(machine.balance.toDouble()),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.primaryDarkGreen),
                        ),
                        Row(
                          children: [
                            // زرار الطباعة
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.print_outlined, color: Colors.blue, size: 20),
                              onPressed: () => _showPrinterSelectionDialog(machine),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                              onPressed: () async {
                                try {
                                  await context.read<MachineProvider>().deleteMachine(machine);
                                } catch (e) {
                                  _showError(e);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(color: AppTheme.primaryDarkGreen.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Center(
                        child: Text('ATM', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDarkGreen, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(progress > 0.7 ? Colors.orange : const Color(0xFF26A69A)),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletsTab() {
    final walletsProv = context.watch<WalletProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('كل المحافظ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryDarkGreen),
              onPressed: _showAddWalletDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('إضافة محفظة'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...walletsProv.wallets.map(
          (w) => Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.wallet, color: Colors.blueGrey),
                          const SizedBox(width: 8),
                          Text(w.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      Text(_formatValue(w.balance), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.primaryDarkGreen)),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('حد السحب: ${_formatValue(w.outLimit)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    
    final pages = [
      _buildOverviewTab(),
      const PosScreen(),
      _buildWalletsTab(),
      const ReportsScreen(),
    ];

    return Scaffold(
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDarkGreen,
        title: const Text(AppConstants.appNameAr, style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // زرار العين
          IconButton(
            tooltip: _hideBalances ? 'إظهار الأرقام' : 'إخفاء الأرقام',
            icon: Icon(_hideBalances ? Icons.visibility_off : Icons.visibility, color: Colors.white),
            onPressed: () {
              setState(() {
                _hideBalances = !_hideBalances;
              });
            },
          ),
          IconButton(
            tooltip: 'الوضع الليلي/النهاري',
            icon: Icon(app.isDark ? Icons.light_mode : Icons.dark_mode, color: Colors.white),
            onPressed: () => app.toggleTheme(),
          ),
          IconButton(
            tooltip: 'قفل',
            icon: const Icon(Icons.lock_outline, color: Colors.white),
            onPressed: () => context.read<SecurityProvider>().lockApp(),
          ),
        ],
      ),
      body: pages[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickActionMenu,
        backgroundColor: AppTheme.primaryDarkGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.secondaryMint.withOpacity(0.5),
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
