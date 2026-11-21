import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:local_auth/local_auth.dart';
import '../utils/constants.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final LocalAuthentication _localAuth = LocalAuthentication();

  String generateSalt({int length = 16}) {
    final rng = Random.secure();
    final bytes = List<int>.generate(length, (_) => rng.nextInt(256));
    return base64Encode(bytes);
  }

  Future<String> hashPin(String pin, String saltBase64) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: AppConstants.pbkdf2Iterations,
      bits: AppConstants.pbkdf2KeyLength * 8,
    );

    final secretKey = SecretKey(utf8.encode(pin));
    final nonce = base64Decode(saltBase64);

    final newKey = await pbkdf2.deriveKey(
      secretKey: secretKey,
      nonce: nonce,
    );
    final bytes = await newKey.extractBytes();
    return base64Encode(bytes);
  }

  bool _constantTimeEquals(String a, String b) {
    final Uint8List ba = Uint8List.fromList(utf8.encode(a));
    final Uint8List bb = Uint8List.fromList(utf8.encode(b));
    if (ba.length != bb.length) return false;
    int diff = 0;
    for (int i = 0; i < ba.length; i++) {
      diff |= ba[i] ^ bb[i];
    }
    return diff == 0;
  }

  Future<bool> verifyPin({
    required String inputPin,
    required String storedHash,
    required String storedSalt,
  }) async {
    if (inputPin.isEmpty || storedHash.isEmpty || storedSalt.isEmpty) {
      return false;
    }
    final computed = await hashPin(inputPin, storedSalt);
    return _constantTimeEquals(computed, storedHash);
  }

  Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateBiometric({String reason = 'قم بتأكيد الهوية لفتح فزلكة'}) async {
    try {
      final available = await canCheckBiometrics();
      if (!available) return false;
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
