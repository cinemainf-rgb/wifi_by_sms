import 'package:flutter/foundation.dart';
import '../core/database/db_service.dart';
import '../core/utils/constants.dart';
import '../models/machine.dart';

class MachineProvider extends ChangeNotifier {
  final DbService _dbService = DbService.instance;

  List<Machine> machines = [];
  int selectedMachineIndex = 0;

  double get totalMachinesBalance =>
      machines.fold(0.0, (sum, m) => sum + m.balance);

  Future<void> loadMachines() async {
    final db = await _dbService.database;
    final rows = await db.query('machines', orderBy: 'id ASC');
    machines = rows.map((r) => Machine.fromMap(r)).toList();
    if (machines.isEmpty) {
      selectedMachineIndex = 0;
    } else if (selectedMachineIndex >= machines.length) {
      selectedMachineIndex = machines.length - 1;
    } else if (selectedMachineIndex < 0) {
      selectedMachineIndex = 0;
    }
    notifyListeners();
  }

  void selectMachine(int index) {
    if (index >= 0 && index < machines.length) {
      selectedMachineIndex = index;
      notifyListeners();
    }
  }

  Future<void> addMachine(
    String name,
    double balance, {
    double limit = AppConstants.defaultMachineLimit,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw Exception('اسم المكنة مطلوب');
    }
    if (balance < 0 || limit < 0) {
      throw Exception('لا يمكن تسجيل رصيد أو حد سالب');
    }

    final db = await _dbService.database;
    await db.transaction((txn) async {
      await txn.insert('machines', {
        'name': cleanName,
        'balance': balance,
        'limit_val': limit,
      });
      await _dbService.logAction(
        'MACHINE_ADD',
        'إضافة مكنة "$cleanName" برصيد $balance',
        executor: txn,
      );
    });

    await loadMachines();
  }

  Future<void> updateMachine(Machine m) async {
    if (m.id == null) return;
    final cleanName = m.name.trim();
    if (cleanName.isEmpty) {
      throw Exception('اسم المكنة مطلوب');
    }
    if (m.balance < 0 || m.limit < 0) {
      throw Exception('لا يمكن تحديث رصيد أو حد بقيمة سالبة');
    }

    final db = await _dbService.database;
    await db.transaction((txn) async {
      await txn.update(
        'machines',
        {
          'name': cleanName,
          'balance': m.balance,
          'limit_val': m.limit,
        },
        where: 'id = ?',
        whereArgs: [m.id],
      );
      await _dbService.logAction(
        'MACHINE_UPDATE',
        'تحديث مكنة "$cleanName" (ID: ${m.id}) إلى رصيد ${m.balance}',
        executor: txn,
      );
    });

    await loadMachines();
  }

  Future<void> deleteMachine(Machine m) async {
    final db = await _dbService.database;
    if (m.id == null) return;

    await db.transaction((txn) async {
      await txn.delete(
        'machines',
        where: 'id = ?',
        whereArgs: [m.id],
      );
      await _dbService.logAction(
        'MACHINE_DELETE',
        'حذف مكنة "${m.name}" (ID: ${m.id})',
        executor: txn,
      );
    });

    await loadMachines();

    if (selectedMachineIndex >= machines.length) {
      selectedMachineIndex = machines.isEmpty ? 0 : machines.length - 1;
    }

    notifyListeners();
  }
}
