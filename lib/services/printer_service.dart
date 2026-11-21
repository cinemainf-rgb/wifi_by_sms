import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';

class PrinterService {
  static final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;
  static BluetoothDevice? _connectedDevice;

  // 1. جلب الطابعات المقترنة
  static Future<List<BluetoothDevice>> getPairedDevices() async {
    try {
      return await _bluetooth.getBondedDevices();
    } catch (e) {
      debugPrint("Error getting devices: $e");
      return [];
    }
  }

  // 2. الاتصال بالطابعة
  static Future<bool> connect(BluetoothDevice device) async {
    try {
      await _bluetooth.connect(device);
      _connectedDevice = device;
      return true;
    } catch (e) {
      debugPrint("Error connecting: $e");
      return false;
    }
  }

  // 3. فصل الاتصال
  static Future<void> disconnect() async {
    try {
      await _bluetooth.disconnect();
      _connectedDevice = null;
    } catch (e) {
      debugPrint("Error disconnecting: $e");
    }
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
      // أوامر ESC/POS للطباعة
      _bluetooth.printCustom("Fazlaka Pay", 3, 1); 
      _bluetooth.printNewLine();
      _bluetooth.printCustom("--------------------------------", 1, 1);
      
      _bluetooth.printLeftRight("المكنة:", machineName, 1);
      _bluetooth.printLeftRight("التاريخ:", date, 1);
      _bluetooth.printLeftRight("الحد الأقصى:", limit, 1);
      _bluetooth.printCustom("--------------------------------", 1, 1);
      
      _bluetooth.printCustom("الرصيد الحالي", 2, 1);
      _bluetooth.printCustom(balance, 3, 1); 
      
      _bluetooth.printNewLine();
      _bluetooth.printNewLine();
      _bluetooth.printCustom("شكراً لتعاملكم معنا", 1, 1);
      _bluetooth.printNewLine();
      _bluetooth.printNewLine();
      _bluetooth.printNewLine();
      
    } catch (e) {
      throw Exception('حدث خطأ أثناء الطباعة: $e');
    }
  }
}
