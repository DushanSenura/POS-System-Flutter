import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/employee_change_request_model.dart';
import '../providers/employee_change_request_provider.dart';
import '../providers/employees_provider.dart';

class EmployeeChangeRequestsScreen extends ConsumerStatefulWidget {
  const EmployeeChangeRequestsScreen({super.key});

  @override
  ConsumerState<EmployeeChangeRequestsScreen> createState() =>
      _EmployeeChangeRequestsScreenState();
}

class _EmployeeChangeRequestsScreenState
    extends ConsumerState<EmployeeChangeRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = currentUser?.role.toLowerCase() == 'admin';
    final isAdminOrManagement =
        currentUser?.role.toLowerCase() == 'admin' ||
        currentUser?.role.toLowerCase() == 'management';

    // Redirect if not authorized
    if (!isAdminOrManagement) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
          SnackBarHelper.showError(
            context,
            'Access denied: Admin or Management role required',
          );
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final allRequests = ref.watch(employeeChangeRequestProvider);
    final pendingCount = ref.watch(pendingRequestsCountProvider);

    final pendingRequests = allRequests.where((r) => r.isPending).toList()
      ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    final approvedRequests = allRequests.where((r) => r.isApproved).toList()
      ..sort((a, b) => b.reviewedAt!.compareTo(a.reviewedAt!));
    final rejectedRequests = allRequests.where((r) => r.isRejected).toList()
      ..sort((a, b) => b.reviewedAt!.compareTo(a.reviewedAt!));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Change Requests'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _showClearDataDialog(context, ref),
              tooltip: 'Clear Data',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Pending'),
                  if (pendingCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$pendingCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Approved'),
            const Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestsList(pendingRequests, 'pending'),
          _buildRequestsList(approvedRequests, 'approved'),
          _buildRequestsList(rejectedRequests, 'rejected'),
        ],
      ),
    );
  }

  Widget _buildRequestsList(
    List<EmployeeChangeRequest> requests,
    String status,
  ) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == 'pending'
                  ? Icons.inbox_outlined
                  : status == 'approved'
                  ? Icons.check_circle_outline
                  : Icons.cancel_outlined,
              size: 64,
              color: AppColors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              status == 'pending'
                  ? 'No pending requests'
                  : status == 'approved'
                  ? 'No approved requests'
                  : 'No rejected requests',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final request = requests[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildRequestCard(EmployeeChangeRequest request) {
    final currentUser = ref.watch(currentUserProvider);

    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: request.isPending
              ? Colors.orange.withOpacity(0.1)
              : request.isApproved
              ? AppColors.success.withOpacity(0.1)
              : AppColors.error.withOpacity(0.1),
          child: Icon(
            request.isPending
                ? Icons.pending
                : request.isApproved
                ? Icons.check_circle
                : Icons.cancel,
            color: request.isPending
                ? Colors.orange
                : request.isApproved
                ? AppColors.success
                : AppColors.error,
          ),
        ),
        title: Text(
          request.employeeName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Requested: ${DateFormat('MMM dd, yyyy HH:mm:ss').format(request.requestedAt)}',
              style: const TextStyle(fontSize: 12),
            ),
            if (!request.isPending) ...[
              const SizedBox(height: 2),
              Text(
                'Reviewed by: ${request.reviewedBy}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Requested Changes:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (request.hasNameChange)
                  _buildChangeRow(
                    'Name',
                    request.currentName!,
                    request.requestedName!,
                  ),
                if (request.hasEmailChange)
                  _buildChangeRow(
                    'Email',
                    request.currentEmail!,
                    request.requestedEmail!,
                  ),
                if (request.hasPhoneChange)
                  _buildChangeRow(
                    'Phone',
                    request.currentPhone!,
                    request.requestedPhone!,
                  ),
                if (request.isRejected && request.rejectionReason != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.error.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: AppColors.error,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Rejection Reason:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          request.rejectionReason!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (request.isPending) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showRejectDialog(request),
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _approveRequest(request, currentUser!.name),
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeRow(String label, String oldValue, String newValue) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current:',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        oldValue,
                        style: const TextStyle(
                          fontSize: 13,
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New:',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        newValue,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveRequest(
    EmployeeChangeRequest request,
    String reviewerName,
  ) async {
    try {
      // Update the employee record
      final employees = ref.read(employeesProvider);
      final employee = employees.firstWhere(
        (emp) => emp.id == request.employeeId,
      );

      final updatedEmployee = employee.copyWith(
        name: request.requestedName ?? employee.name,
        email: request.requestedEmail ?? employee.email,
        phone: request.requestedPhone ?? employee.phone,
        updatedAt: DateTime.now(),
      );

      await ref
          .read(employeesProvider.notifier)
          .updateEmployee(updatedEmployee);

      // Update the user record in Hive if name or email changed
      if (request.requestedName != null || request.requestedEmail != null) {
        final userBox = await Hive.openBox<User>(AppConstants.userBoxName);

        // Find the user account associated with this employee
        User? userToUpdate;
        String? userKey;

        for (var key in userBox.keys) {
          final user = userBox.get(key);
          if (user != null && user.employeeId == request.employeeId) {
            userToUpdate = user;
            userKey = key;
            break;
          }
        }

        if (userToUpdate != null && userKey != null) {
          final updatedUser = userToUpdate.copyWith(
            name: request.requestedName ?? userToUpdate.name,
            email: request.requestedEmail ?? userToUpdate.email,
          );
          await userBox.put(userKey, updatedUser);

          // If the updated user is currently logged in, update the auth state
          final currentUser = ref.read(currentUserProvider);
          if (currentUser != null && currentUser.id == updatedUser.id) {
            ref.read(authProvider.notifier).updateUser(updatedUser);
          }
        }
      }

      // Mark request as approved
      ref
          .read(employeeChangeRequestProvider.notifier)
          .approveRequest(request.id, reviewerName);

      if (mounted) {
        SnackBarHelper.showSuccess(
          context,
          'Request approved and changes applied successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Error approving request: ${e.toString()}',
        );
      }
    }
  }

  void _showRejectDialog(EmployeeChangeRequest request) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Change Request'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rejecting request from ${request.employeeName}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Rejection Reason',
                controller: reasonController,
                hint: 'Explain why this request is being rejected',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide a reason';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext);
                await _rejectRequest(
                  request,
                  ref.read(currentUserProvider)!.name,
                  reasonController.text.trim(),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectRequest(
    EmployeeChangeRequest request,
    String reviewerName,
    String reason,
  ) async {
    try {
      ref
          .read(employeeChangeRequestProvider.notifier)
          .rejectRequest(request.id, reviewerName, reason);

      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Request rejected');
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Error rejecting request: ${e.toString()}',
        );
      }
    }
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Change Requests'),
        content: const Text(
          'Are you sure you want to delete all employee change requests? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(employeeChangeRequestProvider.notifier).clearAll();

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All change requests cleared successfully'),
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
