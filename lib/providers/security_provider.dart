import 'package:flutter/widgets.dart';
import '../core/database/db_service.dart';
import '../core/security/auth_service.dart';

class SecurityProvider extends ChangeNotifier with WidgetsBindingObserver {
  final DbService _dbService = DbService.instance;
  final AuthService _authService = AuthService.instance;

  String? _pinHash;
  String? _salt;
  bool _biometricEnabled = false;
  bool _isLocked = false;
  bool _observerAttached = false;

  bool get hasPin => _pinHash != null && _pinHash!.isNotEmpty && _salt != null && _salt!.isNotEmpty;
  bool get biometricEnabled => _biometricEnabled;
  bool get isLocked => _isLocked;

  void attachObserver() {
    if (_observerAttached) return;
    WidgetsBinding.instance.addObserver(this);
    _observerAttached = true;
  }

  void detachObserver() {
    if (!_observerAttached) return;
    WidgetsBinding.instance.removeObserver(this);
    _observerAttached = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (hasPin || _biometricEnabled) {
        lockApp();
      }
    }
  }

  void lockApp() {
    if (!_isLocked) {
      _isLocked = true;
      notifyListeners();
    }
  }

  Future<void> loadSecurity() async {
    final db = await _dbService.database;
    final rows = await db.query('security', where: 'id = 1', limit: 1);
    if (rows.isNotEmpty) {
      final row = rows.first;
      _pinHash = row['pin_hash'] as String?;
      _salt = row['salt'] as String?;
      _biometricEnabled = ((row['biometric_enabled'] as int?) ?? 0) == 1;
      _isLocked = hasPin || _biometricEnabled;
    } else {
      _isLocked = false;
    }
    notifyListeners();
  }

  Future<void> setPin(String newPin) async {
    final cleanPin = newPin.trim();
    if (cleanPin.length < 4) {
      throw Exception('الرمز السري PIN يجب أن يكون 4 أرقام على الأقل');
    }

    final salt = _authService.generateSalt();
    final hash = await _authService.hashPin(cleanPin, salt);
    final db = await _dbService.database;

    await db.transaction((txn) async {
      await txn.update(
        'security',
        {'pin_hash': hash, 'salt': salt},
        where: 'id = 1',
      );
      await _dbService.logAction(
        'PIN_SET',
        'تم تعيين أو تحديث رمز PIN باستخدام PBKDF2',
        executor: txn,
      );
    });

    _pinHash = hash;
    _salt = salt;
    _isLocked = false;
    notifyListeners();
  }

  Future<bool> unlockWithPin(String pin) async {
    if (!hasPin) {
      _isLocked = false;
      notifyListeners();
      return true;
    }
    final ok = await _authService.verifyPin(
      inputPin: pin.trim(),
      storedHash: _pinHash!,
      storedSalt: _salt!,
    );
    if (ok) {
      _isLocked = false;
      await _dbService.logAction('APP_UNLOCK_PIN', 'تم فتح التطبيق بواسطة PIN');
      notifyListeners();
    }
    return ok;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    if (enabled) {
      final canUse = await _authService.canCheckBiometrics();
      if (!canUse) {
        throw Exception('البصمة غير مدعومة أو غير مفعلة على هذا الجهاز');
      }
    }

    final db = await _dbService.database;
    await db.transaction((txn) async {
      await txn.update(
        'security',
        {'biometric_enabled': enabled ? 1 : 0},
        where: 'id = 1',
      );
      await _dbService.logAction(
        'BIOMETRIC_TOGGLE',
        enabled ? 'تم تفعيل قفل البصمة' : 'تم إلغاء قفل البصمة',
        executor: txn,
      );
    });

    _biometricEnabled = enabled;
    notifyListeners();
  }

  Future<bool> unlockWithBiometric() async {
    if (!_biometricEnabled) return false;
    final ok = await _authService.authenticateBiometric();
    if (ok) {
      _isLocked = false;
      await _dbService.logAction('APP_UNLOCK_BIOMETRIC', 'تم فتح التطبيق بالبصمة');
      notifyListeners();
    }
    return ok;
  }

  @override
  void dispose() {
    detachObserver();
    super.dispose();
  }
}
