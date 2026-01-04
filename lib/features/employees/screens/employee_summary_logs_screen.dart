import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/employees_provider.dart';
import '../providers/employee_logs_provider.dart';
import '../models/employee_model.dart';

/// Employee Summary Logs Screen
class EmployeeSummaryLogsScreen extends ConsumerStatefulWidget {
  const EmployeeSummaryLogsScreen({super.key});

  @override
  ConsumerState<EmployeeSummaryLogsScreen> createState() =>
      _EmployeeSummaryLogsScreenState();
}

class _EmployeeSummaryLogsScreenState
    extends ConsumerState<EmployeeSummaryLogsScreen> {
  String _selectedPeriod = 'Weekly';
  String? _selectedRole;

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(employeesProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = currentUser?.role.toLowerCase() == 'admin';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get unique roles from employees
    final roles = employees.map((e) => e.role).toSet().toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Summary Logs'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _showClearDataDialog(context, ref),
              tooltip: 'Clear Data',
            ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About Summary Logs'),
                  content: const Text(
                    'This page tracks employee work hours based on their active/inactive status changes.\n\n'
                    'Hours are calculated and salary is estimated based on:\n'
                    '• Daily: 8 hours per day\n'
                    '• Weekly: 40 hours per week\n'
                    '• Monthly: 160 hours per month',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? theme.colorScheme.surface : AppColors.surface,
            child: Column(
              children: [
                // Period selector
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'Weekly',
                            label: Text('Weekly'),
                            icon: Icon(Icons.calendar_view_week),
                          ),
                          ButtonSegment(
                            value: 'Monthly',
                            label: Text('Monthly'),
                            icon: Icon(Icons.calendar_month),
                          ),
                        ],
                        selected: {_selectedPeriod},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _selectedPeriod = newSelection.first;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Role filter
                DropdownButtonFormField<String?>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Role',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.work_outline),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Roles'),
                    ),
                    ...roles.map((role) {
                      return DropdownMenuItem(value: role, child: Text(role));
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value;
                    });
                  },
                ),
              ],
            ),
          ),

          // Summary cards
          Expanded(child: _buildSummaryList(employees)),
        ],
      ),
    );
  }

  Widget _buildSummaryList(List<Employee> employees) {
    final filteredEmployees = _selectedRole == null
        ? employees
        : employees.where((e) => e.role == _selectedRole).toList();

    if (filteredEmployees.isEmpty) {
      final theme = Theme.of(context);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No employees found',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredEmployees.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final employee = filteredEmployees[index];
        return _buildEmployeeSummaryCard(employee);
      },
    );
  }

  Widget _buildEmployeeSummaryCard(Employee employee) {
    final theme = Theme.of(context);

    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    if (_selectedPeriod == 'Weekly') {
      startDate = now.subtract(Duration(days: now.weekday - 1));
      endDate = startDate.add(const Duration(days: 7));
    } else {
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 1);
    }

    final totalHours = ref
        .watch(employeeLogsProvider.notifier)
        .calculateTotalHours(employee.id, startDate, endDate);

    final calculatedSalary = ref
        .watch(employeeLogsProvider.notifier)
        .calculateSalary(employee, totalHours);

    final logs = ref
        .watch(employeeLogsProvider.notifier)
        .getLogsForEmployee(employee.id)
        .where(
          (log) =>
              log.activeTime.isAfter(startDate) &&
              log.activeTime.isBefore(endDate),
        )
        .toList();

    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          child: Text(
            employee.name[0].toUpperCase(),
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          employee.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          employee.role,
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary stats
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Hours',
                        _formatHoursToHHMM(totalHours),
                        Icons.access_time,
                        theme.colorScheme.tertiary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Calculated Salary',
                        CurrencyFormatter.format(calculatedSalary),
                        Icons.payments,
                        theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Base Salary',
                        '${CurrencyFormatter.format(employee.salary)} / ${employee.salaryMethod}',
                        Icons.account_balance_wallet,
                        theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Work Sessions',
                        '${logs.length}',
                        Icons.work_history,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),

                // Recent logs
                if (logs.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Recent Activity ($_selectedPeriod)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...logs.take(5).map((log) => _buildLogItem(log)),
                  if (logs.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: Text(
                          '+${logs.length - 5} more sessions',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(log) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, HH:mm:ss');
    final hoursWorked = log.hoursWorked ?? log.calculateHours();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: log.deactiveTime == null
                  ? Colors.green
                  : theme.colorScheme.onSurface.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clock In: ${dateFormat.format(log.activeTime)}',
                  style: const TextStyle(fontSize: 12),
                ),
                if (log.deactiveTime != null)
                  Text(
                    'Clock Out: ${dateFormat.format(log.deactiveTime!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  )
                else
                  Text(
                    'Currently On Duty',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          if (log.deactiveTime != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _formatHoursToHHMM(hoursWorked),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.tertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Format decimal hours to HH:MM format
  String _formatHoursToHHMM(double hours) {
    final totalMinutes = (hours * 60).round();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Employee Logs'),
        content: const Text(
          'Are you sure you want to delete all employee work logs? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(employeeLogsProvider.notifier).clearAll();

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All employee logs cleared successfully'),
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
