import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/custom_buttons.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/employee_change_request_model.dart';
import '../providers/employee_change_request_provider.dart';
import '../providers/employees_provider.dart';

const _uuid = Uuid();

class EmployeeProfileEditScreen extends ConsumerStatefulWidget {
  const EmployeeProfileEditScreen({super.key});

  @override
  ConsumerState<EmployeeProfileEditScreen> createState() =>
      _EmployeeProfileEditScreenState();
}

class _EmployeeProfileEditScreenState
    extends ConsumerState<EmployeeProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    final employees = ref.read(employeesProvider);
    final employee = employees.firstWhere(
      (emp) => emp.id == user?.employeeId,
      orElse: () => employees.first,
    );

    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: employee.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final employees = ref.read(employeesProvider);
    final employee = employees.firstWhere(
      (emp) => emp.id == user.employeeId,
      orElse: () => employees.first,
    );

    final requestsNotifier = ref.read(employeeChangeRequestProvider.notifier);

    // Check if there's already a pending request
    if (requestsNotifier.hasePendingRequest(user.id)) {
      SnackBarHelper.showError(
        context,
        'You already have a pending change request',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newName = _nameController.text.trim();
      final newEmail = _emailController.text.trim();
      final newPhone = _phoneController.text.trim();

      // Check if anything actually changed
      if (newName == user.name &&
          newEmail == user.email &&
          newPhone == employee.phone) {
        SnackBarHelper.showError(context, 'No changes detected');
        setState(() => _isLoading = false);
        return;
      }

      final request = EmployeeChangeRequest(
        id: _uuid.v4(),
        employeeId: employee.id,
        employeeName: user.name,
        requestedName: newName != user.name ? newName : null,
        requestedEmail: newEmail != user.email ? newEmail : null,
        requestedPhone: newPhone != employee.phone ? newPhone : null,
        currentName: user.name,
        currentEmail: user.email,
        currentPhone: employee.phone,
        requestedAt: DateTime.now(),
        status: 'pending',
      );

      requestsNotifier.createRequest(request);

      if (mounted) {
        SnackBarHelper.showSuccess(
          context,
          'Change request submitted successfully. Waiting for approval.',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Error submitting request: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final hasPendingRequest = ref
        .watch(employeeChangeRequestProvider.notifier)
        .hasePendingRequest(user?.id ?? '');

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile Information')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (hasPendingRequest)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pending, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pending Request',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'You have a pending change request. Please wait for approval.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Request Profile Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Submit a request to update your profile information. Changes will be reviewed by management before being applied.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            CustomTextField(
              label: 'Full Name',
              controller: _nameController,
              hint: 'Enter your full name',
              prefixIcon: const Icon(Icons.person_outline),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Email Address',
              controller: _emailController,
              hint: 'Enter your email',
              prefixIcon: const Icon(Icons.email_outlined),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Phone Number',
              controller: _phoneController,
              hint: 'Enter your phone number',
              prefixIcon: const Icon(Icons.phone_outlined),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Card(
              color: Colors.blue.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info, size: 20, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Important Information',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Your changes will be saved as a draft\n'
                      '• Management or Admin must approve the changes\n'
                      '• You will be notified once your request is reviewed\n'
                      '• Only one pending request is allowed at a time',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'Submit Request for Approval',
              onPressed: hasPendingRequest ? null : _submitRequest,
              isLoading: _isLoading,
              icon: Icons.send,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}
