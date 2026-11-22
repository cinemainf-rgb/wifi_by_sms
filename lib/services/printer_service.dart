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
      await PrintBluetoothThermal.printCustom("Fazlaka Pay", 3, 1);
      await PrintBluetoothThermal.printNewLine();
      await PrintBluetoothThermal.printCustom("--------------------------------", 1, 1);

      await PrintBluetoothThermal.printLeftRight("المكنة:", machineName, 1);
      await PrintBluetoothThermal.printLeftRight("التاريخ:", date, 1);
      await PrintBluetoothThermal.printLeftRight("الحد الأقصى:", limit, 1);
      await PrintBluetoothThermal.printCustom("--------------------------------", 1, 1);

      await PrintBluetoothThermal.printCustom("الرصيد الحالي", 2, 1);
      await PrintBluetoothThermal.printCustom(balance, 3, 1);

      await PrintBluetoothThermal.printNewLine();
      await PrintBluetoothThermal.printNewLine();
      await PrintBluetoothThermal.printCustom("شكراً لتعاملكم معنا", 1, 1);
      await PrintBluetoothThermal.printNewLine();
      await PrintBluetoothThermal.printNewLine();
      await PrintBluetoothThermal.printNewLine();
    } catch (e) {
      throw Exception('حدث خطأ أثناء الطباعة: $e');
    }
  }
}
