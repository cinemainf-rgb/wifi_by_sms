import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../core/utils/constants.dart';
import '../providers/security_provider.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sec = context.read<SecurityProvider>();
      if (sec.hasPin && sec.biometricEnabled) {
        _tryBiometric();
      }
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _tryBiometric() async {
    final sec = context.read<SecurityProvider>();
    await sec.unlockWithBiometric();
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
        if (pin.length < 4) {
          throw Exception('أدخل رمز PIN من 4 أرقام على الأقل');
        }
        if (pin != confirm) {
          throw Exception('الرمز غير متطابق مع التأكيد');
        }
        await sec.setPin(pin);
      } else {
        final ok = await sec.unlockWithPin(_pinController.text.trim());
        if (!ok) {
          throw Exception('رمز PIN غير صحيح');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sec = context.watch<SecurityProvider>();
    final isSetupMode = !sec.hasPin;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 64),
                  const SizedBox(height: 12),
                  Text(
                    AppConstants.appNameAr,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isSetupMode
                        ? 'قم بتعيين رمز PIN لحماية حساباتك'
                        : 'أدخل رمز PIN لفتح التطبيق',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'رمز PIN',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.pin_outlined),
                    ),
                  ),
                  if (isSetupMode) ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: _confirmPinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'تأكيد رمز PIN',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.check_circle_outline),
                      ),
                    ),
                  ],
                  if (_errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorText!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : () => _submitPin(sec),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isSetupMode ? 'حفظ وفتح' : 'فتح التطبيق'),
                    ),
                  ),
                  if (!isSetupMode && sec.biometricEnabled) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _tryBiometric,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('فتح بالبصمة'),
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
