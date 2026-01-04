import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/employee_log_model.dart';
import '../models/employee_model.dart';

const _uuid = Uuid();

/// Provider for employee logs
final employeeLogsProvider =
    StateNotifierProvider<EmployeeLogsNotifier, List<EmployeeLog>>((ref) {
      return EmployeeLogsNotifier();
    });

/// Notifier for managing employee logs
class EmployeeLogsNotifier extends StateNotifier<List<EmployeeLog>> {
  static const String _boxName = 'employee_logs';
  Box<EmployeeLog>? _box;

  EmployeeLogsNotifier() : super([]) {
    _init();
  }

  /// Initialize and load logs from Hive
  Future<void> _init() async {
    _box = await Hive.openBox<EmployeeLog>(_boxName);
    state = _box?.values.toList() ?? [];
  }

  /// Add a new log entry (when employee is marked active)
  Future<void> addLog(Employee employee) async {
    final log = EmployeeLog(
      id: _uuid.v4(),
      employeeId: employee.id,
      employeeName: employee.name,
      activeTime: DateTime.now(),
      createdAt: DateTime.now(),
    );
    await _box?.put(log.id, log);
    state = [...state, log];
  }

  /// Mark employee as inactive (end shift)
  Future<void> endLog(String logId) async {
    final log = state.firstWhere((l) => l.id == logId);
    final deactiveTime = DateTime.now();
    final hoursWorked = log
        .copyWith(deactiveTime: deactiveTime)
        .calculateHours();

    final updatedLog = log.copyWith(
      deactiveTime: deactiveTime,
      hoursWorked: hoursWorked,
    );

    await _box?.put(logId, updatedLog);
    state = [
      for (final l in state)
        if (l.id == logId) updatedLog else l,
    ];
  }

  /// Get logs for a specific employee
  List<EmployeeLog> getLogsForEmployee(String employeeId) {
    return state.where((log) => log.employeeId == employeeId).toList();
  }

  /// Get logs for a specific date range
  List<EmployeeLog> getLogsByDateRange(DateTime start, DateTime end) {
    return state.where((log) {
      return log.activeTime.isAfter(start) && log.activeTime.isBefore(end);
    }).toList();
  }

  /// Get active logs (no deactive time)
  List<EmployeeLog> getActiveLogs() {
    return state.where((log) => log.deactiveTime == null).toList();
  }

  /// Calculate total hours for employee in date range
  double calculateTotalHours(String employeeId, DateTime start, DateTime end) {
    final logs = state.where((log) {
      return log.employeeId == employeeId &&
          log.activeTime.isAfter(start) &&
          log.activeTime.isBefore(end) &&
          log.deactiveTime != null;
    }).toList();

    return logs.fold(0.0, (sum, log) => sum + (log.hoursWorked ?? 0));
  }

  /// Calculate salary based on hours and salary method
  double calculateSalary(Employee employee, double totalHours) {
    switch (employee.salaryMethod) {
      case 'Daily':
        // Assuming 8 hours per day
        final days = totalHours / 8;
        return employee.salary * days;
      case 'Weekly':
        // Assuming 40 hours per week
        final weeks = totalHours / 40;
        return employee.salary * weeks;
      case 'Monthly':
        // Assuming 160 hours per month (4 weeks * 40 hours)
        final months = totalHours / 160;
        return employee.salary * months;
      default:
        return 0;
    }
  }

  /// Clear all logs
  Future<void> clearAll() async {
    await _box?.clear();
    state = [];
  }
}

/// Provider for weekly hours
final weeklyHoursProvider = Provider.family<double, String>((ref, employeeId) {
  final now = DateTime.now();
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  final endOfWeek = startOfWeek.add(const Duration(days: 7));

  return ref
      .watch(employeeLogsProvider.notifier)
      .calculateTotalHours(employeeId, startOfWeek, endOfWeek);
});

/// Provider for monthly hours
final monthlyHoursProvider = Provider.family<double, String>((ref, employeeId) {
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 1);

  return ref
      .watch(employeeLogsProvider.notifier)
      .calculateTotalHours(employeeId, startOfMonth, endOfMonth);
});
