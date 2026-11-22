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

  // دالة مساعدة للطباعة - دي اللي بقت بديل printCustom
  static Future<void> _printLine(String text, {int size = 1, int align = 1}) async {
    await PrintBluetoothThermal.printString(
      printerText: PrintText(text: text, size: size, align: align),
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
      await _printLine("Fazlaka Pay", size: 3, align: 1);
      await _printLine("--------------------------------", size: 1, align: 1);
      await _printLine("المكنة: $machineName", size: 1, align: 0);
      await _printLine("التاريخ: $date", size: 1, align: 0);
      await _printLine("الحد الأقصى: $limit", size: 1, align: 0);
      await _printLine("--------------------------------", size: 1, align: 1);
      await _printLine("الرصيد الحالي", size: 2, align: 1);
      await _printLine(balance, size: 3, align: 1);
      await _printLine("", size: 1, align: 1);
      await _printLine("", size: 1, align: 1);
      await _printLine("شكراً لتعاملكم معنا", size: 1, align: 1);
      await _printLine("", size: 1, align: 1);
      await _printLine("", size: 1, align: 1);
      await _printLine("", size: 1, align: 1);
    } catch (e) {
      throw Exception('حدث خطأ أثناء الطباعة: $e');
    }
  }
}
