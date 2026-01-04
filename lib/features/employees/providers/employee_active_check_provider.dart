import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import 'employees_provider.dart';

/// Provider that checks if the current employee is active (clocked in)
final isEmployeeActiveProvider = Provider<bool>((ref) {
  final currentUser = ref.watch(currentUserProvider);

  // If not an employee or no user, return true (no restriction)
  if (currentUser == null || currentUser.role.toLowerCase() != 'employee') {
    return true;
  }

  // If employee doesn't have an employeeId, return false
  if (currentUser.employeeId == null) {
    return false;
  }

  // Watch the employees state to get real-time updates
  final employees = ref.watch(employeesProvider);

  // Find the employee in the list
  final employee = employees
      .where((emp) => emp.id == currentUser.employeeId)
      .firstOrNull;

  return employee?.isActive ?? false;
});

/// Provider that returns the reason why access is blocked (if any)
final employeeAccessBlockReasonProvider = Provider<String?>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  final isActive = ref.watch(isEmployeeActiveProvider);

  if (currentUser == null) {
    return null;
  }

  if (currentUser.role.toLowerCase() != 'employee') {
    return null;
  }

  if (!isActive) {
    return 'Please clock in from the Employees page to access this feature';
  }

  return null;
});
