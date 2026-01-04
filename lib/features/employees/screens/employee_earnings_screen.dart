import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/employee_model.dart';
import '../providers/employees_provider.dart';
import '../../sales/providers/sales_provider.dart';
import '../../auth/providers/users_provider.dart';
import '../../auth/providers/auth_provider.dart';

class EmployeeEarningsScreen extends ConsumerStatefulWidget {
  const EmployeeEarningsScreen({super.key});

  @override
  ConsumerState<EmployeeEarningsScreen> createState() =>
      _EmployeeEarningsScreenState();
}

class _EmployeeEarningsScreenState
    extends ConsumerState<EmployeeEarningsScreen> {
  String _selectedRoleFilter = 'All';
  final Map<String, String> _employeePeriods = {}; // Track period per employee
  final List<String> _roleFilters = [
    'All',
    'Cashier',
    'Manager',
    'Sales Associate',
    'Inventory Manager',
    'Accountant',
    'Supervisor',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final employees = ref.watch(employeesProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = currentUser?.role.toLowerCase() == 'admin';

    // Filter employees by role
    var filteredEmployees = employees.where((employee) {
      return _selectedRoleFilter == 'All' ||
          employee.role == _selectedRoleFilter;
    }).toList();

    // Sort by name
    filteredEmployees.sort((a, b) => a.name.compareTo(b.name));

    // Calculate total sales for all filtered employees (using their individual periods)
    double totalSales = 0;
    for (var employee in filteredEmployees) {
      final salesAmount = _calculateSales(
        employee,
        _getEmployeePeriod(employee.id),
      );
      totalSales += salesAmount;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Sales'),
        elevation: 0,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _showClearDataDialog(context, ref),
              tooltip: 'Clear Data',
            ),
        ],
      ),
      body: Column(
        children: [
          // Stats Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Column(
              children: [
                // Total Sales Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Sales',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.format(totalSales),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Icon(
                        Icons.shopping_cart,
                        color: Colors.white,
                        size: 48,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Stats Row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Employees',
                        filteredEmployees.length.toString(),
                        Icons.people,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Average',
                        CurrencyFormatter.format(
                          filteredEmployees.isEmpty
                              ? 0
                              : totalSales / filteredEmployees.length,
                        ),
                        Icons.trending_up,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Role Filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _roleFilters.map((role) {
                  final isSelected = _selectedRoleFilter == role;
                  final count = role == 'All'
                      ? employees.length
                      : employees.where((e) => e.role == role).length;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text('$role ($count)'),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedRoleFilter = role;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Employees List
          Expanded(
            child: filteredEmployees.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No employees found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredEmployees.length,
                    itemBuilder: (context, index) {
                      final employee = filteredEmployees[index];
                      return _buildEmployeeSalesCard(context, employee, theme);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
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
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeSalesCard(
    BuildContext context,
    Employee employee,
    ThemeData theme,
  ) {
    final selectedPeriod = _getEmployeePeriod(employee.id);
    final sales = _calculateSales(employee, selectedPeriod);
    final transactionCount = _calculateTransactionCount(
      employee,
      selectedPeriod,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  radius: 24,
                  child: Text(
                    employee.name[0].toUpperCase(),
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Employee Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        employee.role,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),

                // Sales Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    CurrencyFormatter.format(sales),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Period Selector for this employee
            SegmentedButton<String>(
              segments: ['Daily', 'Weekly', 'Monthly'].map((period) {
                return ButtonSegment<String>(
                  value: period,
                  label: Text(period, style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
              selected: {selectedPeriod},
              onSelectionChanged: (Set<String> selected) {
                setState(() {
                  _employeePeriods[employee.id] = selected.first;
                });
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Details Grid
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    context,
                    'Transactions',
                    transactionCount.toString(),
                    Icons.receipt_long,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
                Expanded(
                  child: _buildInfoItem(
                    context,
                    'Avg Sale',
                    transactionCount > 0
                        ? CurrencyFormatter.format(sales / transactionCount)
                        : CurrencyFormatter.format(0),
                    Icons.point_of_sale,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Only show role since period is now shown in filter
            Center(
              child: _buildInfoItem(
                context,
                'Role',
                employee.role,
                Icons.work_outline,
              ),
            ),

            // Daily Sales Breakdown
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _buildDailySalesBreakdown(context, employee, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySalesBreakdown(
    BuildContext context,
    Employee employee,
    ThemeData theme,
  ) {
    final dailySales = _getDailySalesBreakdown(employee);

    if (dailySales.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          'No sales recorded in this period',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              'Daily Sales History',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...dailySales.entries.map((entry) {
          final date = entry.key;
          final amount = entry.value;
          final isToday = _isToday(date);

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isToday
                  ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                  : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: isToday
                  ? Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isToday ? Icons.today : Icons.calendar_today_outlined,
                  size: 14,
                  color: isToday
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatDate(date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                      color: isToday
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
                Text(
                  CurrencyFormatter.format(amount),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isToday
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  String _getEmployeePeriod(String employeeId) {
    return _employeePeriods[employeeId] ?? 'Weekly'; // Default to Weekly
  }

  Map<DateTime, double> _getDailySalesBreakdown(Employee employee) {
    final selectedPeriod = _getEmployeePeriod(employee.id);
    final salesList = ref.watch(salesProvider);
    final users = ref.watch(usersProvider);
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (selectedPeriod) {
      case 'Daily':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'Weekly':
        // Start from Monday of current week at 00:00:00
        startDate = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1));
        // End at Sunday of current week at 23:59:59
        endDate = startDate.add(
          const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
        );
        break;
      case 'Monthly':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
    }

    // Get all user accounts linked to this employee
    final linkedUserNames = users
        .where((user) => user.employeeId == employee.id)
        .map((user) => user.name)
        .toList();

    // Filter sales by employee name or linked user names and date range
    final employeeSales = salesList.where((sale) {
      final matchesEmployee =
          sale.cashierName == employee.name ||
          linkedUserNames.contains(sale.cashierName);
      final matchesDateRange =
          sale.createdAt.isAfter(startDate) && sale.createdAt.isBefore(endDate);
      return matchesEmployee && matchesDateRange;
    });

    // Group sales by day
    final Map<DateTime, double> dailySalesMap = {};
    for (final sale in employeeSales) {
      final saleDate = DateTime(
        sale.createdAt.year,
        sale.createdAt.month,
        sale.createdAt.day,
      );
      dailySalesMap[saleDate] = (dailySalesMap[saleDate] ?? 0) + sale.total;
    }

    // Sort by date (most recent first)
    final sortedEntries = dailySalesMap.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Map.fromEntries(sortedEntries);
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      final weekday = _getWeekdayName(date.weekday);
      final month = _getMonthName(date.month);
      return '$weekday, $month ${date.day}';
    }
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
      default:
        return '';
    }
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  double _calculateSales(Employee employee, String period) {
    final salesList = ref.watch(salesProvider);
    final users = ref.watch(usersProvider);
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (period) {
      case 'Daily':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'Weekly':
        // Start from Monday of current week at 00:00:00
        startDate = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1));
        // End at Sunday of current week at 23:59:59
        endDate = startDate.add(
          const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
        );
        break;
      case 'Monthly':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
    }

    // Get all user accounts linked to this employee
    final linkedUserNames = users
        .where((user) => user.employeeId == employee.id)
        .map((user) => user.name)
        .toList();

    // Filter sales by employee name or linked user names and date range
    final employeeSales = salesList.where((sale) {
      final matchesEmployee =
          sale.cashierName == employee.name ||
          linkedUserNames.contains(sale.cashierName);
      final matchesDateRange =
          sale.createdAt.isAfter(startDate) && sale.createdAt.isBefore(endDate);
      return matchesEmployee && matchesDateRange;
    });

    // Sum up total sales
    return employeeSales.fold<double>(0, (sum, sale) => sum + sale.total);
  }

  int _calculateTransactionCount(Employee employee, String period) {
    final salesList = ref.watch(salesProvider);
    final users = ref.watch(usersProvider);
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (period) {
      case 'Daily':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'Weekly':
        // Start from Monday of current week at 00:00:00
        startDate = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1));
        // End at Sunday of current week at 23:59:59
        endDate = startDate.add(
          const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
        );
        break;
      case 'Monthly':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
    }

    // Get all user accounts linked to this employee
    final linkedUserNames = users
        .where((user) => user.employeeId == employee.id)
        .map((user) => user.name)
        .toList();

    // Filter sales by employee name or linked user names and date range
    final employeeSales = salesList.where((sale) {
      final matchesEmployee =
          sale.cashierName == employee.name ||
          linkedUserNames.contains(sale.cashierName);
      final matchesDateRange =
          sale.createdAt.isAfter(startDate) && sale.createdAt.isBefore(endDate);
      return matchesEmployee && matchesDateRange;
    });

    return employeeSales.length;
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Sales Data'),
        content: const Text(
          'Are you sure you want to delete all sales data? This will affect employee sales calculations. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(salesProvider.notifier).clearAll();

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All sales data cleared successfully'),
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
