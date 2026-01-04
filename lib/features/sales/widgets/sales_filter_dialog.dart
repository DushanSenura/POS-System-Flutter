import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/sales_provider.dart';

/// Sales filter dialog
class SalesFilterDialog extends ConsumerStatefulWidget {
  const SalesFilterDialog({super.key});

  @override
  ConsumerState<SalesFilterDialog> createState() => _SalesFilterDialogState();
}

class _SalesFilterDialogState extends ConsumerState<SalesFilterDialog> {
  String _selectedFilter = 'all'; // all, today, week, month, custom
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final currentFilter = ref.read(dateRangeProvider);
    if (currentFilter != null) {
      _selectedFilter = 'custom';
      _startDate = currentFilter.start;
      _endDate = currentFilter.end;
    }
  }

  void _applyFilter() {
    final now = DateTime.now();
    SalesDateRange? dateRange;

    switch (_selectedFilter) {
      case 'all':
        dateRange = null;
        break;
      case 'today':
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        dateRange = SalesDateRange(startOfDay, endOfDay);
        break;
      case 'week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfDay = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        );
        final endOfDay = DateTime(
          now.year,
          now.month,
          now.day,
        ).add(const Duration(days: 1));
        dateRange = SalesDateRange(startOfDay, endOfDay);
        break;
      case 'month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 1);
        dateRange = SalesDateRange(startOfMonth, endOfMonth);
        break;
      case 'custom':
        if (_startDate != null && _endDate != null) {
          final start = DateTime(
            _startDate!.year,
            _startDate!.month,
            _startDate!.day,
          );
          final end = DateTime(
            _endDate!.year,
            _endDate!.month,
            _endDate!.day,
          ).add(const Duration(days: 1));
          dateRange = SalesDateRange(start, end);
        }
        break;
    }

    ref.read(dateRangeProvider.notifier).state = dateRange;
    Navigator.pop(context);
  }

  void _clearFilter() {
    ref.read(dateRangeProvider.notifier).state = null;
    Navigator.pop(context);
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate == null || _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.filter_list,
                  color: AppColors.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Filter Sales',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Filter options
            _FilterOption(
              label: 'All Sales',
              value: 'all',
              groupValue: _selectedFilter,
              onChanged: (value) => setState(() => _selectedFilter = value!),
            ),
            _FilterOption(
              label: 'Today',
              value: 'today',
              groupValue: _selectedFilter,
              onChanged: (value) => setState(() => _selectedFilter = value!),
            ),
            _FilterOption(
              label: 'This Week',
              value: 'week',
              groupValue: _selectedFilter,
              onChanged: (value) => setState(() => _selectedFilter = value!),
            ),
            _FilterOption(
              label: 'This Month',
              value: 'month',
              groupValue: _selectedFilter,
              onChanged: (value) => setState(() => _selectedFilter = value!),
            ),
            _FilterOption(
              label: 'Custom Date Range',
              value: 'custom',
              groupValue: _selectedFilter,
              onChanged: (value) => setState(() => _selectedFilter = value!),
            ),

            // Custom date range selectors
            if (_selectedFilter == 'custom') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Date Range',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectStartDate,
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              _startDate == null
                                  ? 'Start Date'
                                  : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectEndDate,
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              _endDate == null
                                  ? 'End Date'
                                  : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _clearFilter,
                  child: const Text('Clear Filter'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed:
                      _selectedFilter == 'custom' &&
                          (_startDate == null || _endDate == null)
                      ? null
                      : _applyFilter,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Apply Filter'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _FilterOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      activeColor: AppColors.primary,
    );
  }
}
