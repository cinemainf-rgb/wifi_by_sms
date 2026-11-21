class AppFormatter {
  // تنسيق الأرقام الإنجليزية مع فواصل الآلاف
  static String fmt(double v) {
    final bool neg = v < 0;
    final double absV = v.abs();
    String s = absV.toStringAsFixed(1);
    if (s.endsWith('.0')) {
      s = s.substring(0, s.length - 2);
    }
    final parts = s.split('.');
    final String intPart = parts[0];
    String out = '';
    int c = 0;
    for (int i = intPart.length - 1; i >= 0; i--) {
      out = intPart[i] + out;
      c++;
      if (c == 3 && i != 0) {
        out = ',$out';
        c = 0;
      }
    }
    if (parts.length > 1) {
      out += '.${parts[1]}';
    }
    return neg ? '-$out' : out;
  }

  // تاريخ اليوم بأرقام إنجليزية YYYY/MM/DD
  static String todayStr() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y/$m/$d';
  }
}
