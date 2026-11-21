import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/utils/constants.dart';
import 'providers/app_provider.dart';
import 'providers/machine_provider.dart';
import 'providers/sales_provider.dart';
import 'providers/security_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/wallet_provider.dart';
import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FazlakaApp());
}

class FazlakaApp extends StatefulWidget {
  const FazlakaApp({super.key});

  @override
  State<FazlakaApp> createState() => _FazlakaAppState();
}

class _FazlakaAppState extends State<FazlakaApp> {
  late final MachineProvider _machineProvider;
  late final WalletProvider _walletProvider;
  late final SalesProvider _salesProvider;
  late final TransactionProvider _transactionProvider;
  late final SecurityProvider _securityProvider;
  late final AppProvider _appProvider;

  @override
  void initState() {
    super.initState();
    _machineProvider = MachineProvider();
    _walletProvider = WalletProvider();
    _salesProvider = SalesProvider();
    _transactionProvider = TransactionProvider();
    _securityProvider = SecurityProvider()..attachObserver();
    _appProvider = AppProvider();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appProvider.initAll(
        machineProvider: _machineProvider,
        walletProvider: _walletProvider,
        salesProvider: _salesProvider,
        transactionProvider: _transactionProvider,
        securityProvider: _securityProvider,
      );
    });
  }

  @override
  void dispose() {
    _securityProvider.detachObserver();
    _machineProvider.dispose();
    _walletProvider.dispose();
    _salesProvider.dispose();
    _transactionProvider.dispose();
    _securityProvider.dispose();
    _appProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppProvider>.value(value: _appProvider),
        ChangeNotifierProvider<MachineProvider>.value(value: _machineProvider),
        ChangeNotifierProvider<WalletProvider>.value(value: _walletProvider),
        ChangeNotifierProvider<SalesProvider>.value(value: _salesProvider),
        ChangeNotifierProvider<TransactionProvider>.value(value: _transactionProvider),
        ChangeNotifierProvider<SecurityProvider>.value(value: _securityProvider),
      ],
      child: Consumer2<AppProvider, SecurityProvider>(
        builder: (context, app, security, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: app.isDark ? ThemeMode.dark : ThemeMode.light,
            builder: (context, child) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: child ?? const SizedBox.shrink(),
              );
            },
            // تعديل شاشة التحميل لتكون بخلفية داكنة زي التطبيق الأول
            home: !app.isInitialized
                ? const Scaffold(
                    backgroundColor: AppTheme.primaryDarkGreen, // اللون الغامق الجديد
                    body: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.secondaryMint, // لون النعناع للتحميل
                      ),
                    ),
                  )
                : (security.isLocked
                    ? const LockScreen()
                    : const HomeScreen()),
          );
        },
      ),
    );
  }
}
