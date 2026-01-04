import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/employee_model.dart';

/// Provider for employees list
final employeesProvider =
    StateNotifierProvider<EmployeesNotifier, List<Employee>>((ref) {
      return EmployeesNotifier();
    });

/// Notifier for managing employees
class EmployeesNotifier extends StateNotifier<List<Employee>> {
  static const String _boxName = 'employees';
  Box<Employee>? _box;

  EmployeesNotifier() : super([]) {
    _init();
  }

  /// Initialize and load employees from Hive
  Future<void> _init() async {
    _box = Hive.box<Employee>(_boxName);
    state = _box?.values.toList() ?? [];
  }

  /// Add a new employee
  Future<void> addEmployee(Employee employee) async {
    await _box?.put(employee.id, employee);
    state = [...state, employee];
  }

  /// Update an existing employee
  Future<void> updateEmployee(Employee employee) async {
    await _box?.put(employee.id, employee);
    state = [
      for (final emp in state)
        if (emp.id == employee.id) employee else emp,
    ];
  }

  /// Delete an employee
  Future<void> deleteEmployee(String id) async {
    await _box?.delete(id);
    state = state.where((emp) => emp.id != id).toList();
  }

  /// Toggle employee active status
  Future<void> toggleEmployeeStatus(String id) async {
    final employee = state.firstWhere((emp) => emp.id == id);
    final updated = employee.copyWith(
      isActive: !employee.isActive,
      updatedAt: DateTime.now(),
    );
    await updateEmployee(updated);
  }

  /// Get employee by ID
  Employee? getEmployeeById(String id) {
    try {
      return state.firstWhere((emp) => emp.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get active employees
  List<Employee> getActiveEmployees() {
    return state.where((emp) => emp.isActive).toList();
  }

  /// Search employees by name, email, or phone
  List<Employee> searchEmployees(String query) {
    final lowerQuery = query.toLowerCase();
    return state.where((emp) {
      return emp.name.toLowerCase().contains(lowerQuery) ||
          emp.email.toLowerCase().contains(lowerQuery) ||
          emp.phone.contains(lowerQuery);
    }).toList();
  }
}

/// Provider for active employees only
final activeEmployeesProvider = Provider<List<Employee>>((ref) {
  final employees = ref.watch(employeesProvider);
  return employees.where((emp) => emp.isActive).toList();
});

/// Provider for employee count
final employeeCountProvider = Provider<int>((ref) {
  final employees = ref.watch(employeesProvider);
  return employees.length;
});

/// Provider for active employee count
final activeEmployeeCountProvider = Provider<int>((ref) {
  final employees = ref.watch(activeEmployeesProvider);
  return employees.length;
});
