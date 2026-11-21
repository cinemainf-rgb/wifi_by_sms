import 'constants.dart';

class AppHelpers {
  static double limitForWallet(String name) {
    final n = name.toLowerCase();
    if (n.contains('انستا') || n.contains('إنستا') || n.contains('insta')) {
      return AppConstants.instaOutLimit;
    }
    return AppConstants.defaultWalletOutLimit;
  }
}
