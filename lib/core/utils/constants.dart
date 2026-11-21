class AppConstants {
  static const String appName = 'Fazlaka Pay';
  static const String appNameAr = 'فزلكة';
  static const String dbName = 'fazlaka_encrypted.db';
  static const int dbVersion = 1;
  static const String dbKeyStorageKey = 'fazlaka_sqlcipher_key_v1';

  static const String drawerName = 'الدرج';
  static const String safeName = 'الخزنة';

  static const double defaultMachineLimit = 200000.0;
  static const double defaultWalletOutLimit = 200000.0;
  static const double instaOutLimit = 400000.0;
  static const double defaultCommissionRate = 2.0;

  static const int pbkdf2Iterations = 100000;
  static const int pbkdf2KeyLength = 32;
}
