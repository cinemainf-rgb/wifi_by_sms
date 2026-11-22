import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../providers/security_provider.dart';
import '../theme/app_theme.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  String? _errorText;
  bool _isSubmitting = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  // بصمة حقيقية - بتشتغل بس لما تدوس على الزرار، مش لوحدها
  Future<void> _tryBiometric() async {
    setState(() => _errorText = null);
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) {
        if (mounted) setState(() => _errorText = 'موبايلك مفيهوش بصمة متسجلة');
        return;
      }
      final ok = await _localAuth.authenticate(
        localizedReason: 'حط صباعك عشان تفتح فزلكة',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      if (!ok) {
        if (mounted) setState(() => _errorText = 'البصمة فشلت، جرب تاني');
        return;
      }
      // البصمة نجحت - نفتح على طول، من غير ما نقفل تاني
      final sec = context.read<SecurityProvider>();
      final opened = await sec.unlockWithBiometric();
      if (!opened && mounted) {
        setState(() => _errorText = 'البصمة نجحت بس القفل مفتحش، جرب الـ PIN');
      }
    } catch (e) {
      if (mounted) setState(() => _errorText = 'غلطة في البصمة: $e');
    }
  }

  Future<void> _submitPin(SecurityProvider sec) async {
    setState(() {
      _errorText = null;
      _isSubmitting = true;
    });
    try {
      if (!sec.hasPin) {
        final pin = _pinController.text.trim();
        final confirm = _confirmPinController.text.trim();
        if (pin.length < 4) throw Exception('أدخل رمز PIN من 4 أرقام على الأقل');
        if (pin != confirm) throw Exception('الرمز غير متطابق مع التأكيد');
        await sec.setPin(pin);
      } else {
        final ok = await sec.unlockWithPin(_pinController.text.trim());
        if (!ok) throw Exception('رمز PIN غير صحيح');
      }
    } catch (e) {
      if (mounted) setState(() => _errorText = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sec = context.watch<SecurityProvider>();
    final isSetupMode = !sec.hasPin;
    return Scaffold(
      backgroundColor: AppTheme.primaryDarkGreen,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Fazlaka', style: TextStyle(fontFamily: 'Cairo', fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 8),
                  const Text('Fazlaka Pay', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white70)),
                  const SizedBox(height: 40),
                  if (_errorText != null) ...[
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Text(_errorText!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                    const SizedBox(height: 16),
                  ],
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: TextField(controller: _pinController, keyboardType: TextInputType.number, obscureText: true, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, letterSpacing: 10, fontWeight: FontWeight.bold), decoration: InputDecoration(hintText: '••••', filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(vertical: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
                  ),
                  if (isSetupMode) ...[
                    const SizedBox(height: 16),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: TextField(controller: _confirmPinController, keyboardType: TextInputType.number, obscureText: true, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, letterSpacing: 10, fontWeight: FontWeight.bold), decoration: InputDecoration(hintText: 'تأكيد ••••', filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(vertical: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
                    ),
                  ],
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF26A69A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), onPressed: _isSubmitting ? null : () => _submitPin(sec), child: _isSubmitting ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(isSetupMode ? 'حفظ وفتح' : 'دخول', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  ),
                  if (!isSetupMode) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryMint, foregroundColor: AppTheme.primaryDarkGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), onPressed: _tryBiometric, icon: const Icon(Icons.fingerprint, size: 28), label: const Text('دخول بالبصمة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
