import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/custom_buttons.dart';
import '../providers/settings_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/users_provider.dart';
import '../../employees/providers/employee_change_request_provider.dart';
import '../../employees/providers/employees_provider.dart';
import '../../employees/providers/employee_logs_provider.dart';
import '../../employees/models/employee_change_request_model.dart';
import '../../products/providers/products_provider.dart';
import '../../sales/providers/sales_provider.dart';
import 'receipt_settings_screen.dart';
import 'backup_restore_screen.dart';

/// Settings screen
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _cashierNameController;
  late TextEditingController _cashierEmailController;
  late TextEditingController _cashierPhoneController;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).value;
    final employee = user?.employeeId != null
        ? ref
              .read(employeesProvider.notifier)
              .getEmployeeById(user!.employeeId!)
        : null;

    _cashierNameController = TextEditingController(text: user?.name ?? '');
    _cashierEmailController = TextEditingController(
      text: employee?.email ?? user?.email ?? '',
    );
    _cashierPhoneController = TextEditingController(
      text: employee?.phone ?? '',
    );
  }

  @override
  void dispose() {
    _cashierNameController.dispose();
    _cashierEmailController.dispose();
    _cashierPhoneController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final currentUser = ref.read(authProvider).value;
    if (currentUser == null) return;

    final isEmployee = currentUser.role.toLowerCase() == 'employee';

    // Get current employee data if available
    final currentEmployeeData = currentUser.employeeId != null
        ? ref
              .read(employeesProvider.notifier)
              .getEmployeeById(currentUser.employeeId!)
        : null;

    // Check if there are any changes
    final nameChanged = _cashierNameController.text != currentUser.name;
    final emailChanged =
        _cashierEmailController.text !=
        (currentEmployeeData?.email ?? currentUser.email);
    final phoneChanged =
        _cashierPhoneController.text.isNotEmpty &&
        _cashierPhoneController.text != (currentEmployeeData?.phone ?? '');

    if (!nameChanged && !emailChanged && !phoneChanged) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No changes to save'),
          backgroundColor: AppColors.info,
        ),
      );
      return;
    }

    if (isEmployee) {
      // Employee: Create a change request
      if (currentUser.employeeId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Employee ID not found'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Check if there's already a pending request
      final requestNotifier = ref.read(employeeChangeRequestProvider.notifier);
      if (requestNotifier.hasePendingRequest(currentUser.employeeId!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You already have a pending change request'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      final request = EmployeeChangeRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        employeeId: currentUser.employeeId!,
        employeeName: currentUser.name,
        requestedName: nameChanged ? _cashierNameController.text : null,
        requestedEmail: emailChanged ? _cashierEmailController.text : null,
        requestedPhone: phoneChanged ? _cashierPhoneController.text : null,
        currentName: currentUser.name,
        currentEmail: currentEmployeeData?.email ?? currentUser.email,
        currentPhone: currentEmployeeData?.phone,
        requestedAt: DateTime.now(),
        status: 'pending',
      );

      requestNotifier.createRequest(request);

      // Show approval message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.schedule, color: AppColors.warning, size: 48),
          title: const Text('Request Submitted'),
          content: const Text(
            'Your profile change request has been submitted and is awaiting approval from Admin or Management.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      // Reset fields to original values
      _cashierNameController.text = currentUser.name;
      _cashierEmailController.text =
          currentEmployeeData?.email ?? currentUser.email;
      _cashierPhoneController.text = currentEmployeeData?.phone ?? '';
    } else {
      // Admin/Management: Save directly
      final authNotifier = ref.read(authProvider.notifier);
      final employeesNotifier = ref.read(employeesProvider.notifier);

      // Update user account
      final updatedUser = currentUser.copyWith(
        name: _cashierNameController.text,
        email: _cashierEmailController.text,
      );
      authNotifier.updateUser(updatedUser);

      // Update employee record if exists
      if (currentUser.employeeId != null && currentEmployeeData != null) {
        final updatedEmployee = currentEmployeeData.copyWith(
          name: _cashierNameController.text,
          email: _cashierEmailController.text,
          phone: _cashierPhoneController.text.isNotEmpty
              ? _cashierPhoneController.text
              : currentEmployeeData.phone,
          updatedAt: DateTime.now(),
        );
        employeesNotifier.updateEmployee(updatedEmployee);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final user = ref.watch(authProvider).value;
    final isEmployee = user?.role.toLowerCase() == 'employee';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Actions Card - Hidden from Employees
            if (!isEmployee)
              Card(
                elevation: 2,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.receipt_long,
                        color: AppColors.primary,
                      ),
                      title: const Text('Receipt Settings'),
                      subtitle: const Text(
                        'Configure receipt and printer settings',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ReceiptSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.backup,
                        color: AppColors.primary,
                      ),
                      title: const Text('Backup & Restore'),
                      subtitle: const Text('Manage your data'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BackupRestoreScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.restart_alt, color: Colors.red),
                      title: const Text(
                        'Reset App',
                        style: TextStyle(color: Colors.red),
                      ),
                      subtitle: const Text('Clear all app data'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _showResetAppDialog,
                    ),
                  ],
                ),
              ),
            if (!isEmployee) const SizedBox(height: 24),

            // Cashier Details Section
            _buildSectionHeader('Cashier Details', Icons.person),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Cashier Name',
              controller: _cashierNameController,
              hint: 'Enter your name',
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Cashier Email',
              controller: _cashierEmailController,
              hint: 'cashier@example.com',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Cashier Phone',
              controller: _cashierPhoneController,
              hint: '+1 (555) 123-4567',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 8),
            if (user != null)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'Role: ${user.role}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            const SizedBox(height: 32),

            // Appearance Section
            _buildSectionHeader('Appearance', Icons.palette),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Use dark theme'),
              value: settings.isDarkMode,
              onChanged: (_) {
                ref.read(settingsProvider.notifier).toggleDarkMode();
              },
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.primary,
            ),
            const SizedBox(height: 32),

            // Save Button
            PrimaryButton(
              text: 'Save Settings',
              onPressed: _saveSettings,
              width: double.infinity,
              icon: Icons.save,
            ),
          ],
        ),
      ),
    );
  }

  void _showResetAppDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning, color: Colors.red, size: 48),
        title: const Text('Reset App'),
        content: const Text(
          'This will delete ALL data including:\n\n'
          '• Products\n'
          '• Sales History\n'
          '• Employees\n'
          '• Employee Logs\n'
          '• User Accounts (except Admin)\n'
          '• Change Requests\n\n'
          'Admin accounts will be preserved.\n\n'
          'This action cannot be undone!\n\n'
          'Enter admin password to continue:',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showPasswordVerificationDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showPasswordVerificationDialog() {
    final passwordController = TextEditingController();
    bool isPasswordVisible = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Admin Password Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter admin password to reset the app:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Admin Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                passwordController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final enteredPassword = passwordController.text;

                // Get current user to verify it's an admin
                final currentUser = ref.read(authProvider).value;
                if (currentUser == null ||
                    currentUser.role.toLowerCase() != 'admin') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Only admins can reset the app'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Verify admin password
                final usersNotifier = ref.read(usersProvider.notifier);
                if (usersNotifier.verifyCredentials(
                  currentUser.email,
                  enteredPassword,
                )) {
                  passwordController.dispose();
                  Navigator.pop(context);
                  await _performAppReset();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Incorrect password'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reset App'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performAppReset() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Resetting app...'),
          ],
        ),
      ),
    );

    try {
      // Clear all data
      ref.read(productsProvider.notifier).clearAll();
      ref.read(salesProvider.notifier).clearAll();

      final employees = ref.read(employeesProvider);
      final employeesNotifier = ref.read(employeesProvider.notifier);
      for (final employee in employees) {
        await employeesNotifier.deleteEmployee(employee.id);
      }

      await ref.read(employeeLogsProvider.notifier).clearAll();
      ref.read(employeeChangeRequestProvider.notifier).clearAll();

      // Delete all user accounts except admin accounts
      final users = ref.read(usersProvider);
      final usersNotifier = ref.read(usersProvider.notifier);
      for (final user in users) {
        // Skip admin accounts
        if (user.role.toLowerCase() != 'admin') {
          usersNotifier.deleteUser(user.id);
        }
      }

      // Wait a moment for operations to complete
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        // Show success message
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
            title: const Text('App Reset Complete'),
            content: const Text(
              'All data has been cleared successfully.\n\n'
              'The app will now restart.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  // Log out user
                  ref.read(authProvider.notifier).logout();
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/login', (route) => false);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resetting app: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
