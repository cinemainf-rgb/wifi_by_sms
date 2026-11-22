import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:flutter/material.dart';

class PrinterService {
  static BluetoothInfo? _connectedDevice;

  // 1. جلب الطابعات المقترنة
  static Future<List<BluetoothInfo>> getPairedDevices() async {
    try {
      return await PrintBluetoothThermal.pairedBluetooths;
    } catch (e) {
      debugPrint("Error getting devices: $e");
      return [];
    }
  }

  // 2. الاتصال بالطابعة
  static Future<bool> connect(BluetoothInfo device) async {
    try {
      final bool result = await PrintBluetoothThermal.connect(macPrinterAddress: device.macAdress);
      if (result) _connectedDevice = device;
      return result;
    } catch (e) {
      debugPrint("Error connecting: $e");
      return false;
    }
  }

  // 3. فصل الاتصال
  static Future<void> disconnect() async {
    try {
      await PrintBluetoothThermal.disconnect;
      _connectedDevice = null;
    } catch (e) {
      debugPrint("Error disconnecting: $e");
    }
  }

  // دالة مساعدة - دي الصح بتاعة المكتبة الجديدة
  static Future<void> _printLine(String text, {int size = 1}) async {
    await PrintBluetoothThermal.writeString(
      printText: PrintTextSize(size: size, text: text),
    );
  }

  // 4. دالة الطباعة الفعلية
  static Future<void> printReceipt({
    required String machineName,
    required String balance,
    required String limit,
    required String date,
  }) async {
    if (_connectedDevice == null) {
      throw Exception('الرجاء الاتصال بالطابعة أولاً');
    }

    try {
      await _printLine("Fazlaka Pay\n", size: 3);
      await _printLine("--------------------------------\n", size: 1);
      await _printLine("المكنة: $machineName\n", size: 1);
      await _printLine("التاريخ: $date\n", size: 1);
      await _printLine("الحد الأقصى: $limit\n", size: 1);
      await _printLine("--------------------------------\n", size: 1);
      await _printLine("الرصيد الحالي\n", size: 2);
      await _printLine("$balance\n", size: 3);
      await _printLine("\n\n", size: 1);
      await _printLine("شكراً لتعاملكم معنا\n", size: 1);
      await _printLine("\n\n\n", size: 1);
    } catch (e) {
      throw Exception('حدث خطأ أثناء الطباعة: $e');
    }
  }
}
