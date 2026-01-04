import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/employees_provider.dart';
import '../providers/employee_logs_provider.dart';
import '../models/employee_model.dart';
import 'employee_form_screen.dart';

/// Employees management screen
class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(employeesProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isEmployee = currentUser?.role.toLowerCase() == 'employee';

    // For employees, only show their own account
    final List<Employee> displayEmployees;
    if (isEmployee && currentUser?.employeeId != null) {
      final myEmployee = ref
          .read(employeesProvider.notifier)
          .getEmployeeById(currentUser!.employeeId!);
      displayEmployees = myEmployee != null ? [myEmployee] : [];
    } else {
      displayEmployees = _searchQuery.isEmpty
          ? employees
          : ref.read(employeesProvider.notifier).searchEmployees(_searchQuery);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEmployee ? 'My Account' : 'Employees'),
        actions: [
          if (!isEmployee)
            IconButton(
              icon: const Icon(Icons.analytics_outlined),
              onPressed: () {
                Navigator.pushNamed(context, '/employee-summary-logs');
              },
              tooltip: 'Summary Logs',
            ),
          if (!isEmployee && currentUser?.role.toLowerCase() == 'admin')
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _showClearDataDialog(context, ref),
              tooltip: 'Clear Data',
            ),
          if (!isEmployee)
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EmployeeFormScreen(),
                  ),
                );
              },
              tooltip: 'Add Employee',
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar - Only show for non-employees
          if (!isEmployee)
            Padding(
              padding: const EdgeInsets.all(16),
              child: CustomTextField(
                label: 'Search',
                controller: _searchController,
                hint: 'Search employees...',
                prefixIcon: const Icon(Icons.search),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

          // Summary cards - Only show for non-employees
          if (!isEmployee)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total',
                      employees.length.toString(),
                      Icons.people,
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Active',
                      ref.watch(activeEmployeeCountProvider).toString(),
                      Icons.check_circle,
                      AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          if (!isEmployee) const SizedBox(height: 16),

          // Employee info message for employees
          if (isEmployee)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                color: AppColors.info.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.info, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You can activate or deactivate your account here',
                          style: TextStyle(
                            color: AppColors.info,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Employees list
          Expanded(
            child: displayEmployees.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isEmployee
                              ? Icons.person_outline
                              : (_searchQuery.isEmpty
                                    ? Icons.people_outline
                                    : Icons.search_off),
                          size: 64,
                          color: AppColors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isEmployee
                              ? 'No account information found'
                              : (_searchQuery.isEmpty
                                    ? 'No employees yet'
                                    : 'No employees found'),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: displayEmployees.length,
                    separatorBuilder: (_, __) => const Divider(height: 24),
                    itemBuilder: (context, index) {
                      final employee = displayEmployees[index];
                      return _buildEmployeeCard(employee, isEmployee);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: isEmployee
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EmployeeFormScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Employee'),
              backgroundColor: AppColors.primary,
            ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(Employee employee, bool isEmployee) {
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                employee.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: employee.isActive
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                employee.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: employee.isActive
                      ? AppColors.success
                      : AppColors.error,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          employee.role,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.email_outlined,
                      size: 16,
                      color: AppColors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        employee.email,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.phone_outlined,
                      size: 16,
                      color: AppColors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      employee.phone,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Salary',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${CurrencyFormatter.format(employee.salary)} / ${employee.salaryMethod}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Joined',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('MMM dd, yyyy').format(employee.joinDate),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Active/Inactive Time Display
                _buildTimeDisplay(employee),
                const SizedBox(height: 16),
                // Action Buttons
                Row(
                  children: [
                    if (!isEmployee)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EmployeeFormScreen(employee: employee),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                    if (!isEmployee) const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final logsNotifier = ref.read(
                            employeeLogsProvider.notifier,
                          );

                          // If marking as active, create a new log entry
                          if (!employee.isActive) {
                            await logsNotifier.addLog(employee);
                          } else {
                            // If marking as inactive, end the current active log
                            final activeLogs = logsNotifier.getActiveLogs();

                            // Find the active log for this specific employee
                            try {
                              final employeeActiveLog = activeLogs.firstWhere(
                                (log) => log.employeeId == employee.id,
                              );
                              await logsNotifier.endLog(employeeActiveLog.id);
                            } catch (e) {
                              // No active log found for this employee, that's okay
                              print(
                                'No active log found for employee ${employee.id}',
                              );
                            }
                          }

                          // Toggle the employee status
                          ref
                              .read(employeesProvider.notifier)
                              .toggleEmployeeStatus(employee.id);
                        },
                        icon: Icon(
                          employee.isActive
                              ? Icons.person_off_outlined
                              : Icons.person_add_outlined,
                          size: 18,
                        ),
                        label: Text(
                          employee.isActive
                              ? (isEmployee ? 'Clock Out' : 'Mark as Inactive')
                              : (isEmployee ? 'Clock In' : 'Mark as Active'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: employee.isActive
                              ? AppColors.error
                              : AppColors.success,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDisplay(Employee employee) {
    final logsNotifier = ref.read(employeeLogsProvider.notifier);
    final activeLogs = logsNotifier.getActiveLogs();

    // Find active log for this employee
    final activeLog = activeLogs
        .where((log) => log.employeeId == employee.id)
        .firstOrNull;

    if (employee.isActive && activeLog != null) {
      // Show active time and duration
      final activeTime = activeLog.activeTime;
      final duration = DateTime.now().difference(activeTime);
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      final seconds = duration.inSeconds % 60;

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.success.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                const Text(
                  'On Duty',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Clock In',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMM dd, HH:mm:ss').format(activeTime),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Duration',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      // Show last inactive time if available
      final employeeLogs = logsNotifier.getLogsForEmployee(employee.id);
      if (employeeLogs.isEmpty) {
        return const SizedBox.shrink();
      }

      // Get the most recent completed log
      final completedLogs =
          employeeLogs.where((log) => log.deactiveTime != null).toList()
            ..sort((a, b) => b.deactiveTime!.compareTo(a.deactiveTime!));

      if (completedLogs.isEmpty) {
        return const SizedBox.shrink();
      }

      final lastLog = completedLogs.first;
      final totalSeconds = ((lastLog.hoursWorked ?? 0) * 3600).round();
      final hours = totalSeconds ~/ 3600;
      final minutes = (totalSeconds % 3600) ~/ 60;
      final seconds = totalSeconds % 60;

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.grey.withOpacity(0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, size: 16, color: AppColors.grey),
                const SizedBox(width: 8),
                const Text(
                  'Last Shift',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Clock In',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat(
                          'MMM dd, HH:mm:ss',
                        ).format(lastLog.activeTime),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Clock Out',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat(
                          'MMM dd, HH:mm:ss',
                        ).format(lastLog.deactiveTime!),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Duration',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Employees'),
        content: const Text(
          'Are you sure you want to delete all employees? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final employees = ref.read(employeesProvider);
              final employeesNotifier = ref.read(employeesProvider.notifier);

              for (final employee in employees) {
                await employeesNotifier.deleteEmployee(employee.id);
              }

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All employees cleared successfully'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
