import 'package:flutter/material.dart';
import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WiFi By SMS - فذلكا',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WifiSmsHomeScreen(),
    );
  }
}

class WifiSmsHomeScreen extends StatefulWidget {
  const WifiSmsHomeScreen({super.key});

  @override
  State<WifiSmsHomeScreen> createState() => _WifiSmsHomeScreenState();
}

class _WifiSmsHomeScreenState extends State<WifiSmsHomeScreen> {
  BluetoothPrint bluetoothPrint = BluetoothPrint.instance;
  bool _connected = false;
  String _generatedCode = "اضغط لتوليد الكود";

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  void _initBluetooth() {
    bluetoothPrint.state.listen((state) {
      setState(() {
        _connected = state == BluetoothPrint.CONNECTED;
      });
    });
  }

  void _generateVoucher() {
    var bytes = utf8.encode(DateTime.now().toString());
    var digest = sha256.convert(bytes);
    String code = digest.toString().substring(0, 7).toUpperCase();
    
    setState(() {
      _generatedCode = code;
    });
  }

  Future<void> _printVoucher() async {
    if (_connected) {
      Map<String, dynamic> config = <String, dynamic>{};
      List<LineText> list = [];
      
      list.add(LineText(type: LineText.TYPE_TEXT, content: "FAZLAKA - فذلكا", weight: 2, align: LineText.ALIGN_CENTER, linefeed: 1));
      list.add(LineText(type: LineText.TYPE_TEXT, content: "--------------------------------", align: LineText.ALIGN_CENTER, linefeed: 1));
      list.add(LineText(type: LineText.TYPE_TEXT, content: "WiFi Voucher Code:", align: LineText.ALIGN_LEFT, linefeed: 1));
      list.add(LineText(type: LineText.TYPE_TEXT, content: "Username: $_generatedCode", weight: 2, align: LineText.ALIGN_LEFT, linefeed: 1));
      list.add(LineText(type: LineText.TYPE_TEXT, content: "Password: (Empty / فارغ)", align: LineText.ALIGN_LEFT, linefeed: 1));
      list.add(LineText(type: LineText.TYPE_TEXT, content: "--------------------------------", align: LineText.ALIGN_CENTER, linefeed: 1));
      list.add(LineText(type: LineText.TYPE_TEXT, content: "شكراً لاستخدامكم شبكة فذلكا ج.م", align: LineText.ALIGN_CENTER, linefeed: 1));
      list.add(LineText(type: LineText.TYPE_FEED, count: 1));

      await bluetoothPrint.printReceipt(config, list);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فذلكا - واي فاي بالرسائل'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'الكود الحالي:',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            const SizedBox(height: 10),
            Text(
              _generatedCode,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _generateVoucher,
              icon: const Icon(Icons.refresh),
              label: const Text('توليد كارت جديد'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _connected ? _printVoucher : null,
              icon: const Icon(Icons.print),
              style: ElevatedButton.styleFrom(backgroundColor: _connected ? Colors.green : Colors.grey),
              label: Text(_connected ? 'طباعة الكارت (بلوتوث)' : 'الطابعة غير متصلة'),
            ),
          ],
        ),
      ),
    );
  }
}
