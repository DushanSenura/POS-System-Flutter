import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../providers/users_provider.dart';
import '../providers/auth_provider.dart';
import '../../employees/providers/employees_provider.dart';
import '../../../core/utils/snackbar_helper.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  String _selectedRoleFilter = 'All';
  String _searchQuery = '';

  final List<String> _roleFilters = ['All', 'Admin', 'Management', 'Employee'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final users = ref.watch(usersProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = currentUser?.role.toLowerCase() == 'admin';

    // Filter users
    var filteredUsers = users.where((user) {
      final matchesRole =
          _selectedRoleFilter == 'All' || user.role == _selectedRoleFilter;
      final matchesSearch =
          _searchQuery.isEmpty ||
          user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesRole && matchesSearch;
    }).toList();

    // Sort by creation date (newest first)
    filteredUsers.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Accounts'),
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
          // Stats Card
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  'Total Accounts',
                  users.length.toString(),
                  Icons.people,
                  theme.colorScheme.primary,
                ),
                _buildStatItem(
                  context,
                  'Admins',
                  users.where((u) => u.role == 'Admin').length.toString(),
                  Icons.admin_panel_settings,
                  Colors.purple,
                ),
                _buildStatItem(
                  context,
                  'Management',
                  users.where((u) => u.role == 'Management').length.toString(),
                  Icons.manage_accounts,
                  Colors.orange,
                ),
                _buildStatItem(
                  context,
                  'Employees',
                  users.where((u) => u.role == 'Employee').length.toString(),
                  Icons.person,
                  Colors.blue,
                ),
              ],
            ),
          ),

          // Search and Filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Role Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _roleFilters.map((role) {
                      final isSelected = _selectedRoleFilter == role;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(role),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedRoleFilter = role;
                            });
                          },
                          avatar: Icon(
                            _getRoleIcon(role),
                            size: 18,
                            color: isSelected
                                ? theme.colorScheme.onSecondaryContainer
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Results Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${filteredUsers.length} ${filteredUsers.length == 1 ? 'account' : 'accounts'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Accounts List
          Expanded(
            child: filteredUsers.isEmpty
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
                          'No accounts found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Try a different search term'
                              : 'Create your first account',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return _buildAccountCard(context, user, theme);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountCard(BuildContext context, User user, ThemeData theme) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showAccountDetails(context, user),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    backgroundColor: _getRoleColor(user.role).withOpacity(0.2),
                    radius: 28,
                    child: Icon(
                      _getRoleIcon(user.role),
                      color: _getRoleColor(user.role),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                user.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Role Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getRoleColor(
                                  user.role,
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                user.role,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getRoleColor(user.role),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 14,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                user.email,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.lock_outlined,
                              size: 14,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Password: ${_extractPassword(user.qrCode)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                  fontFamily: 'monospace',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Additional Info
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      context,
                      Icons.calendar_today_outlined,
                      'Created: ${dateFormat.format(user.createdAt)}',
                    ),
                  ),
                ],
              ),
              if (user.employeeId != null) ...[
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final employees = ref.watch(employeesProvider);
                    final employee = employees
                        .where((e) => e.id == user.employeeId)
                        .firstOrNull;
                    return _buildInfoChip(
                      context,
                      Icons.badge_outlined,
                      employee != null
                          ? 'Linked to: ${employee.name}'
                          : 'Linked to Employee',
                      color: Colors.green,
                    );
                  },
                ),
              ],
              if (user.mustChangePassword) ...[
                const SizedBox(height: 8),
                _buildInfoChip(
                  context,
                  Icons.lock_reset,
                  'Must change password',
                  color: Colors.orange,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    IconData icon,
    String text, {
    Color? color,
  }) {
    final theme = Theme.of(context);
    final chipColor = color ?? theme.colorScheme.onSurface.withOpacity(0.6);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: chipColor),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(color: chipColor),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showAccountDetails(BuildContext context, User user) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm:ss');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: _getRoleColor(user.role).withOpacity(0.2),
              child: Icon(
                _getRoleIcon(user.role),
                color: _getRoleColor(user.role),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: const TextStyle(fontSize: 18)),
                  Text(
                    user.role,
                    style: TextStyle(
                      fontSize: 14,
                      color: _getRoleColor(user.role),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(context, 'Email', user.email, Icons.email),
              const SizedBox(height: 12),
              _buildDetailRow(
                context,
                'Created',
                dateFormat.format(user.createdAt),
                Icons.calendar_today,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                context,
                'Last Login',
                dateFormat.format(user.lastLogin),
                Icons.login,
              ),
              if (user.employeeId != null) ...[
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    final employees = ref.watch(employeesProvider);
                    final employee = employees
                        .where((e) => e.id == user.employeeId)
                        .firstOrNull;
                    return _buildDetailRow(
                      context,
                      'Linked Employee',
                      employee != null
                          ? '${employee.name} (${employee.role})'
                          : user.employeeId!,
                      Icons.badge,
                    );
                  },
                ),
              ],
              if (user.qrCode != null) ...[
                const SizedBox(height: 12),
                _buildPasswordRow(context, user.qrCode!),
              ],
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    user.mustChangePassword
                        ? Icons.lock_reset
                        : Icons.lock_open,
                    size: 20,
                    color: user.mustChangePassword
                        ? Colors.orange
                        : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      user.mustChangePassword
                          ? 'Must change password on next login'
                          : 'Password is set',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: user.mustChangePassword
                            ? Colors.orange
                            : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showLinkEmployeeDialog(context, user);
            },
            child: Text(
              user.employeeId != null ? 'Change Employee' : 'Link Employee',
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showResetPasswordDialog(context, user);
            },
            child: const Text('Reset Password'),
          ),
          if (user.id != 'admin-default')
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _confirmDeleteAccount(context, user);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordRow(BuildContext context, String qrCode) {
    final theme = Theme.of(context);
    // Extract password from QR code (format: email:password)
    final parts = qrCode.split(':');
    final password = parts.length > 1 ? parts[1] : 'N/A';
    bool isPasswordVisible = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.password, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Password',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isPasswordVisible ? password : '••••••••',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            letterSpacing: isPasswordVisible ? 0 : 2,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        },
                        tooltip: isPasswordVisible
                            ? 'Hide password'
                            : 'Show password',
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: password),
                          );
                          if (context.mounted) {
                            SnackBarHelper.showSuccess(
                              context,
                              'Password copied to clipboard',
                            );
                          }
                        },
                        tooltip: 'Copy password',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteAccount(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text(
          'Are you sure you want to delete the account for "${user.name}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(usersProvider.notifier).deleteUser(user.id);
              Navigator.pop(context);
              SnackBarHelper.showSuccess(
                context,
                'Account deleted successfully',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context, User user) {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscurePassword = true;
    bool obscureConfirmPassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.lock_reset, color: Colors.orange),
              const SizedBox(width: 12),
              const Text('Reset Password'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reset password for: ${user.name}'),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'User will be required to change this password on next login',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                passwordController.dispose();
                confirmPasswordController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final password = passwordController.text;
                final confirmPassword = confirmPasswordController.text;

                if (password.isEmpty) {
                  SnackBarHelper.showError(context, 'Please enter a password');
                  return;
                }

                if (password.length < 6) {
                  SnackBarHelper.showError(
                    context,
                    'Password must be at least 6 characters',
                  );
                  return;
                }

                if (password != confirmPassword) {
                  SnackBarHelper.showError(context, 'Passwords do not match');
                  return;
                }

                ref
                    .read(usersProvider.notifier)
                    .changePassword(user.id, password);
                passwordController.dispose();
                confirmPasswordController.dispose();
                Navigator.pop(context);
                SnackBarHelper.showSuccess(
                  context,
                  'Password reset successfully for ${user.name}',
                );
              },
              child: const Text('Reset Password'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLinkEmployeeDialog(BuildContext context, User user) {
    final theme = Theme.of(context);
    final employees = ref.read(employeesProvider);
    String? selectedEmployeeId = user.employeeId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Link Employee Account'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select an employee to link with ${user.name}\'s account',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (user.employeeId != null) ...[
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          selectedEmployeeId = null;
                        });
                      },
                      icon: const Icon(Icons.link_off),
                      label: const Text('Remove Employee Link'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: employees.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No employees available'),
                          )
                        : ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 300),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: employees.length,
                              itemBuilder: (context, index) {
                                final employee = employees[index];
                                final isSelected =
                                    selectedEmployeeId == employee.id;

                                // Check if employee is already linked to another account
                                final isLinked = ref
                                    .read(usersProvider)
                                    .any(
                                      (u) =>
                                          u.employeeId == employee.id &&
                                          u.id != user.id,
                                    );

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isSelected
                                        ? theme.colorScheme.primary.withOpacity(
                                            0.2,
                                          )
                                        : theme
                                              .colorScheme
                                              .surfaceContainerHighest,
                                    child: Text(
                                      employee.name[0].toUpperCase(),
                                      style: TextStyle(
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  title: Text(employee.name),
                                  subtitle: Row(
                                    children: [
                                      Text(employee.role),
                                      if (isLinked) ...[
                                        const Text(' • '),
                                        Icon(
                                          Icons.link,
                                          size: 14,
                                          color: Colors.orange,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          'Linked',
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  trailing: isSelected
                                      ? Icon(
                                          Icons.check_circle,
                                          color: theme.colorScheme.primary,
                                        )
                                      : null,
                                  selected: isSelected,
                                  onTap: () {
                                    setState(() {
                                      selectedEmployeeId = employee.id;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Update user with selected employee ID
                  ref
                      .read(usersProvider.notifier)
                      .updateUser(
                        user.copyWith(employeeId: selectedEmployeeId),
                      );

                  Navigator.pop(context);

                  if (selectedEmployeeId == null) {
                    SnackBarHelper.showSuccess(
                      context,
                      'Employee link removed from ${user.name}',
                    );
                  } else {
                    final employee = employees.firstWhere(
                      (e) => e.id == selectedEmployeeId,
                    );
                    SnackBarHelper.showSuccess(
                      context,
                      '${user.name} linked to ${employee.name}',
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'Admin':
        return Icons.admin_panel_settings;
      case 'Management':
        return Icons.manage_accounts;
      case 'Employee':
        return Icons.person;
      case 'All':
        return Icons.people;
      default:
        return Icons.person_outline;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Admin':
        return Colors.purple;
      case 'Management':
        return Colors.orange;
      case 'Employee':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All User Accounts'),
        content: const Text(
          'Are you sure you want to delete all user accounts? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final users = ref.read(usersProvider);
              final usersNotifier = ref.read(usersProvider.notifier);

              for (final user in users) {
                usersNotifier.deleteUser(user.id);
              }

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All user accounts cleared successfully'),
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

  String _extractPassword(String? qrCode) {
    if (qrCode == null || qrCode.isEmpty) {
      return '••••••••';
    }

    // QR code format is "email:password"
    final parts = qrCode.split(':');
    if (parts.length >= 2) {
      return parts[1];
    }

    return '••••••••';
  }
}
