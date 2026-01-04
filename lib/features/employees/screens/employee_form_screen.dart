import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/custom_buttons.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/employee_model.dart';
import '../providers/employees_provider.dart';

const _uuid = Uuid();

/// Employee Form Screen for adding/editing employees
class EmployeeFormScreen extends ConsumerStatefulWidget {
  final Employee? employee; // null for new employee, existing for edit

  const EmployeeFormScreen({super.key, this.employee});

  @override
  ConsumerState<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends ConsumerState<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _salaryController;
  late TextEditingController _addressController;
  late TextEditingController _workHoursController;
  late String _selectedRole;
  late String _selectedSalaryMethod;
  late DateTime _selectedJoinDate;
  bool _isLoading = false;

  final List<String> _roles = [
    'Cashier',
    'Manager',
    'Sales Associate',
    'Inventory Manager',
    'Accountant',
    'Supervisor',
    'Other',
  ];

  final List<String> _salaryMethods = [
    AppConstants.salaryDaily,
    AppConstants.salaryWeekly,
    AppConstants.salaryMonthly,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee?.name ?? '');
    _emailController = TextEditingController(
      text: widget.employee?.email ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.employee?.phone ?? '',
    );
    _salaryController = TextEditingController(
      text: widget.employee?.salary.toStringAsFixed(2) ?? '',
    );
    _addressController = TextEditingController(
      text: widget.employee?.address ?? '',
    );
    _workHoursController = TextEditingController(
      text: widget.employee?.workHoursPerDay.toString() ?? '8.0',
    );
    _selectedRole = widget.employee?.role ?? _roles.first;
    _selectedSalaryMethod =
        widget.employee?.salaryMethod ?? AppConstants.salaryMonthly;
    _selectedJoinDate = widget.employee?.joinDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _salaryController.dispose();
    _addressController.dispose();
    _workHoursController.dispose();
    super.dispose();
  }

  void _saveEmployee() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _proceedWithSave();
  }

  void _proceedWithSave() {
    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final employeeId = widget.employee?.id ?? _uuid.v4();
      final employee = Employee(
        id: employeeId,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _selectedRole,
        salary: double.parse(_salaryController.text),
        salaryMethod: _selectedSalaryMethod,
        joinDate: _selectedJoinDate,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        isActive: widget.employee?.isActive ?? true,
        createdAt: widget.employee?.createdAt ?? now,
        updatedAt: now,
        workHoursPerDay: double.parse(_workHoursController.text),
      );

      if (widget.employee == null) {
        ref.read(employeesProvider.notifier).addEmployee(employee);
        SnackBarHelper.showSuccess(context, 'Employee added successfully');
        Navigator.pop(context);
      } else {
        ref.read(employeesProvider.notifier).updateEmployee(employee);
        SnackBarHelper.showSuccess(context, 'Employee updated successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _deleteEmployee() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: const Text(
          'Are you sure you want to delete this employee? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(employeesProvider.notifier)
                  .deleteEmployee(widget.employee!.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close form
              SnackBarHelper.showSuccess(
                context,
                'Employee deleted successfully',
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectJoinDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedJoinDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedJoinDate) {
      setState(() {
        _selectedJoinDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isEmployee = currentUser?.role.toLowerCase() == 'employee';
    final isEdit = widget.employee != null;

    // Prevent employees from accessing this screen
    if (isEmployee) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
          SnackBarHelper.showError(
            context,
            'You do not have permission to add or edit employee accounts',
          );
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Employee' : 'Add New Employee'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteEmployee,
              tooltip: 'Delete Employee',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name
            CustomTextField(
              label: 'Full Name *',
              controller: _nameController,
              hint: 'e.g., John Doe',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter employee name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email
            CustomTextField(
              label: 'Email ',
              controller: _emailController,
              hint: 'e.g., john@example.com',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Phone
            CustomTextField(
              label: 'Phone Number *',
              controller: _phoneController,
              hint: 'e.g., 07X XXX XXXX',
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Role Dropdown
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Role *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.work_outline),
              ),
              items: _roles.map((role) {
                return DropdownMenuItem(value: role, child: Text(role));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedRole = value;
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a role';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Salary
            CustomTextField(
              label: 'Salary *',
              controller: _salaryController,
              hint: '0.00',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                final salary = double.tryParse(value);
                if (salary == null || salary < 0) {
                  return 'Invalid salary';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Salary Method Dropdown
            DropdownButtonFormField<String>(
              value: _selectedSalaryMethod,
              decoration: const InputDecoration(
                labelText: 'Salary Method *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payment),
              ),
              items: _salaryMethods.map((method) {
                return DropdownMenuItem(value: method, child: Text(method));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedSalaryMethod = value;
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a salary method';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Work Hours Per Day
            CustomTextField(
              label: 'Work Hours Per Day *',
              controller: _workHoursController,
              hint: '8.0',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                final hours = double.tryParse(value);
                if (hours == null || hours <= 0 || hours > 24) {
                  return 'Invalid hours (must be between 0 and 24)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Join Date
            InkWell(
              onTap: _selectJoinDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Join Date *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  '${_selectedJoinDate.day}/${_selectedJoinDate.month}/${_selectedJoinDate.year}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Address
            CustomTextField(
              label: 'Address',
              controller: _addressController,
              hint: 'Employee address',
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Save Button
            PrimaryButton(
              text: isEdit ? 'Update Employee' : 'Add Employee',
              onPressed: _isLoading ? null : _saveEmployee,
              isLoading: _isLoading,
            ),

            if (isEdit) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _deleteEmployee,
                icon: const Icon(Icons.delete),
                label: const Text('Delete Employee'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
