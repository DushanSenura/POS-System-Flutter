import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/sales_provider.dart';
import '../models/sale_model.dart';

class IncomeSummaryScreen extends ConsumerStatefulWidget {
  const IncomeSummaryScreen({super.key});

  @override
  ConsumerState<IncomeSummaryScreen> createState() =>
      _IncomeSummaryScreenState();
}

class _IncomeSummaryScreenState extends ConsumerState<IncomeSummaryScreen> {
  int _weekOffset = 0; // 0 = current week, -1 = last week, 1 = next week

  // Define time zones for each shift
  List<Map<String, dynamic>> _getTimeZones() {
    final now = DateTime.now();
    final currentWeekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final weekStart = currentWeekStart.add(Duration(days: _weekOffset * 7));

    return [
      {
        'label': 'Monday 6:45 AM - 7:20 PM',
        'start': DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day,
          6,
          45,
        ),
        'end': DateTime(weekStart.year, weekStart.month, weekStart.day, 19, 20),
      },
      {
        'label': 'Monday 7:20 PM - Tuesday 8:20 AM',
        'start': DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day,
          19,
          20,
        ),
        'end': DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + 1,
          8,
          20,
        ),
      },
      {
        'label': 'Tuesday 8:20 AM - 7:45 PM',
        'start': DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + 1,
          8,
          20,
        ),
        'end': DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + 1,
          19,
          45,
        ),
      },
      {
        'label': 'Tuesday 7:45 PM - Wednesday 7:55 AM',
        'start': DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + 1,
          19,
          45,
        ),
        'end': DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + 2,
          7,
          55,
        ),
      },
      {
        'label': 'Wednesday 7:55 AM - 7:50 PM',
        'start': DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + 2,
          7,
          55,
        ),
        'end': DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + 2,
          19,
          50,
        ),
      },
      {
        'label': 'Wednesday 7:50 PM - Thursday 9:10 AM',
        'start': DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + 2,
          19,
          50,
        ),
        'end': DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + 3,
          9,
          10,
        ),
      },
      {
        'label': 'Thursday 9:10 AM - 8:20 PM',
        'start': DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + 3,
          9,
          10,
        ),
        'end': DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + 3,
          20,
          20,
        ),
      },
      {
        'label': 'Thursday 8:20 PM - Friday 6:20 AM',
        'start': DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + 3,
          20,
          20,
        ),
        'end': DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + 4,
          6,
          20,
        ),
      },
      {
        'label': 'Friday 6:20 AM - 8:20 PM',
        'start': DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + 4,
          6,
          20,
        ),
        'end': DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + 4,
          20,
          20,
        ),
      },
      {
        'label': 'Friday 8:20 PM - Saturday 7:20 AM',
        'start': DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + 4,
          20,
          20,
        ),
        'end': DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + 5,
          7,
          20,
        ),
      },
      {
        'label': 'Saturday 7:20 AM - 7:45 PM',
        'start': DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + 5,
          7,
          20,
        ),
        'end': DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + 5,
          19,
          45,
        ),
      },
      {
        'label': 'Saturday 7:45 PM - Sunday 7:20 AM',
        'start': DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + 5,
          19,
          45,
        ),
        'end': DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + 6,
          7,
          20,
        ),
      },
      {
        'label': 'Sunday 7:20 AM - 9:20 PM',
        'start': DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + 6,
          7,
          20,
        ),
        'end': DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + 6,
          21,
          20,
        ),
      },
      {
        'label': 'Sunday 9:20 PM - Monday 6:45 AM',
        'start': DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + 6,
          21,
          20,
        ),
        'end': DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + 7,
          6,
          45,
        ),
      },
    ];
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  Map<String, dynamic> _calculateIncomeForTimeZone(
    List<Sale> sales,
    DateTime start,
    DateTime end,
  ) {
    final filteredSales = sales.where((sale) {
      return sale.createdAt.isAfter(start) && sale.createdAt.isBefore(end);
    }).toList();

    final totalIncome = filteredSales.fold<double>(
      0.0,
      (sum, sale) => sum + sale.total.toDouble(),
    );

    final transactionCount = filteredSales.length;
    final averageTransaction = transactionCount > 0
        ? totalIncome / transactionCount
        : 0.0;

    return {
      'income': totalIncome,
      'transactions': transactionCount,
      'average': averageTransaction,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sales = ref.watch(salesProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = currentUser?.role.toLowerCase() == 'admin';
    final timeZones = _getTimeZones();

    // Calculate week date range
    final now = DateTime.now();
    final currentWeekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final selectedWeekStart = currentWeekStart.add(
      Duration(days: _weekOffset * 7),
    );
    final selectedWeekEnd = selectedWeekStart.add(const Duration(days: 6));

    final weekLabel = _weekOffset == 0
        ? 'This Week'
        : _weekOffset == -1
        ? 'Last Week'
        : _weekOffset == 1
        ? 'Next Week'
        : '${_formatDate(selectedWeekStart)} - ${_formatDate(selectedWeekEnd)}';

    // Calculate total income across all time zones
    double totalWeeklyIncome = 0.0;
    int totalTransactions = 0;

    for (var zone in timeZones) {
      final stats = _calculateIncomeForTimeZone(
        sales,
        zone['start'],
        zone['end'],
      );
      totalWeeklyIncome += (stats['income'] as double);
      totalTransactions += stats['transactions'] as int;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Income Summary by Time Zone'),
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
          // Week Navigation
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _weekOffset--;
                        });
                      },
                      icon: const Icon(Icons.chevron_left),
                      tooltip: 'Previous Week',
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            weekLabel,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatDate(selectedWeekStart)} - ${_formatDate(selectedWeekEnd)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _weekOffset++;
                        });
                      },
                      icon: const Icon(Icons.chevron_right),
                      tooltip: 'Next Week',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Quick Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _weekOffset = 0;
                        });
                      },
                      icon: const Icon(Icons.today, size: 18),
                      label: const Text('This Week'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _weekOffset == 0
                            ? theme.colorScheme.primaryContainer
                            : null,
                        foregroundColor: _weekOffset == 0
                            ? theme.colorScheme.onPrimaryContainer
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedWeekStart,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          helpText: 'Select any date in the week',
                        );
                        if (picked != null) {
                          setState(() {
                            // Calculate week offset from selected date
                            final now = DateTime.now();
                            final currentWeekStart = DateTime(
                              now.year,
                              now.month,
                              now.day,
                            ).subtract(Duration(days: now.weekday - 1));
                            final pickedWeekStart = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                            ).subtract(Duration(days: picked.weekday - 1));
                            final daysDifference = pickedWeekStart
                                .difference(currentWeekStart)
                                .inDays;
                            _weekOffset = (daysDifference / 7).round();
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: const Text('Select Week'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Summary Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Column(
              children: [
                Text(
                  weekLabel,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(totalWeeklyIncome),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long, color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$totalTransactions Transactions',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.trending_up, color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Avg: ${CurrencyFormatter.format(totalTransactions > 0 ? totalWeeklyIncome / totalTransactions : 0)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Time Zone List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: timeZones.length,
              itemBuilder: (context, index) {
                final zone = timeZones[index];
                final stats = _calculateIncomeForTimeZone(
                  sales,
                  zone['start'],
                  zone['end'],
                );

                return _buildTimeZoneCard(
                  context,
                  theme,
                  zone['label'],
                  zone['start'],
                  zone['end'],
                  stats['income'],
                  stats['transactions'],
                  stats['average'],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeZoneCard(
    BuildContext context,
    ThemeData theme,
    String label,
    DateTime start,
    DateTime end,
    double income,
    int transactions,
    double average,
  ) {
    final now = DateTime.now();
    // Only highlight current zone if we're viewing the current week
    final isCurrentZone =
        _weekOffset == 0 && now.isAfter(start) && now.isBefore(end);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isCurrentZone ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrentZone
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isCurrentZone
              ? LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer.withOpacity(0.3),
                    theme.colorScheme.secondaryContainer.withOpacity(0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time Zone Label
              Row(
                children: [
                  if (isCurrentZone)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: theme.colorScheme.onPrimary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'CURRENT',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (isCurrentZone) const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isCurrentZone
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Income Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Income',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(income),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: income > 0
                          ? Colors.green
                          : theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      theme,
                      Icons.receipt_long_outlined,
                      'Transactions',
                      transactions.toString(),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      theme,
                      Icons.show_chart,
                      'Average',
                      CurrencyFormatter.format(average),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
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

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Sales Data'),
        content: const Text(
          'Are you sure you want to delete all sales data? This will affect income summary calculations. This action cannot be undone.',
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
