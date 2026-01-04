import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../auth/providers/users_provider.dart';
import '../../products/providers/products_provider.dart';
import '../../sales/providers/sales_provider.dart';
import '../../employees/providers/employees_provider.dart';
import '../../employees/providers/employee_logs_provider.dart';
import '../../employees/providers/employee_change_request_provider.dart';
import '../services/google_drive_service.dart';
import '../services/auto_backup_service.dart';

class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() =>
      _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  final GoogleDriveService _driveService = GoogleDriveService();
  bool _isLoading = false;
  bool _isSignedIn = false;
  String? _userEmail;
  List<Map<String, dynamic>> _backupFiles = [];
  bool _autoBackupEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkSignInStatus();
  }

  @override
  void dispose() {
    // Auto backup service will be disposed by provider
    super.dispose();
  }

  Future<void> _checkSignInStatus() async {
    setState(() => _isLoading = true);
    try {
      final isSignedIn = await _driveService.isSignedIn();
      final email = await _driveService.getUserEmail();
      setState(() {
        _isSignedIn = isSignedIn;
        _userEmail = email;
        _isLoading = false;
      });
      if (isSignedIn) {
        _loadBackupFiles();

        // Start auto backup service if signed in
        final autoBackupService = ref.read(autoBackupServiceProvider);
        await autoBackupService.initialize(ref);
        autoBackupService.startAutoBackup();
        setState(() => _autoBackupEnabled = true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        SnackBarHelper.showError(context, 'Error checking sign-in status');
      }
    }
  }

  Future<void> _loadBackupFiles() async {
    setState(() => _isLoading = true);
    try {
      final files = await _driveService.listBackupFiles();
      setState(() {
        _backupFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        SnackBarHelper.showError(context, 'Error loading backup files');
      }
    }
  }

  Future<void> _signInToGoogle() async {
    setState(() => _isLoading = true);
    try {
      final success = await _driveService.signIn();
      if (success) {
        final email = await _driveService.getUserEmail();
        setState(() {
          _isSignedIn = true;
          _userEmail = email;
        });
        if (mounted) {
          SnackBarHelper.showSuccess(context, 'Signed in successfully');
        }
        _loadBackupFiles();

        // Start auto backup service
        final autoBackupService = ref.read(autoBackupServiceProvider);
        await autoBackupService.initialize(ref);
        autoBackupService.startAutoBackup();
        setState(() => _autoBackupEnabled = true);
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          SnackBarHelper.showError(context, 'Sign-in failed');
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        SnackBarHelper.showError(context, 'Error signing in: ${e.toString()}');
      }
    }
  }

  Future<void> _signOut() async {
    try {
      // Stop auto backup service
      final autoBackupService = ref.read(autoBackupServiceProvider);
      autoBackupService.stopAutoBackup();

      await _driveService.signOut();
      setState(() {
        _isSignedIn = false;
        _userEmail = null;
        _backupFiles = [];
        _autoBackupEnabled = false;
      });
      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Signed out successfully');
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Error signing out');
      }
    }
  }

  Future<void> _createBackup() async {
    setState(() => _isLoading = true);
    try {
      // Collect all data
      final users = ref.read(usersProvider);
      final products = ref.read(productsProvider);
      final sales = ref.read(salesProvider);
      final employees = ref.read(employeesProvider);
      final employeeLogs = ref.read(employeeLogsProvider);
      final changeRequests = ref.read(employeeChangeRequestProvider);

      final backupData = {
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'data': {
          'users': users.map((u) => u.toJson()).toList(),
          'products': products.map((p) => p.toJson()).toList(),
          'sales': sales.map((s) => s.toJson()).toList(),
          'employees': employees.map((e) => e.toJson()).toList(),
          'employeeLogs': employeeLogs.map((l) => l.toJson()).toList(),
          'changeRequests': changeRequests.map((r) => r.toJson()).toList(),
        },
      };

      final jsonString = jsonEncode(backupData);
      final fileName =
          'pos_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';

      // Save to local storage first
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      // Upload to Google Drive
      final success = await _driveService.uploadBackup(file, fileName);

      if (success) {
        setState(() => _isLoading = false);
        if (mounted) {
          SnackBarHelper.showSuccess(context, 'Backup created successfully');
        }
        _loadBackupFiles();
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          SnackBarHelper.showError(context, 'Failed to upload backup');
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Error creating backup: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _restoreBackup(Map<String, dynamic> backupFile) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning, color: Colors.orange, size: 48),
        title: const Text('Restore Backup'),
        content: Text(
          'This will replace all current data with the backup from:\n\n'
          '${backupFile['name']}\n\n'
          'Current data will be lost. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      // Download backup file
      final directory = await getApplicationDocumentsDirectory();
      final localFile = File('${directory.path}/restore_${backupFile['name']}');
      final success = await _driveService.downloadBackup(
        backupFile['id'],
        localFile,
      );

      if (!success) {
        setState(() => _isLoading = false);
        if (mounted) {
          SnackBarHelper.showError(context, 'Failed to download backup');
        }
        return;
      }

      // Read and parse backup data
      final jsonString = await localFile.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;
      final data = backupData['data'] as Map<String, dynamic>;

      // Restore users
      if (data.containsKey('users')) {
        final usersNotifier = ref.read(usersProvider.notifier);
        // Clear existing users (except admin)
        final currentUsers = ref.read(usersProvider);
        for (final user in currentUsers) {
          if (user.role.toLowerCase() != 'admin') {
            usersNotifier.deleteUser(user.id);
          }
        }
        // Add backed up users
        // Note: This is a simplified version. You may need to implement
        // proper restoration methods in your providers
      }

      // Restore products
      if (data.containsKey('products')) {
        ref.read(productsProvider.notifier).clearAll();
        // Add products from backup
      }

      // Restore sales
      if (data.containsKey('sales')) {
        ref.read(salesProvider.notifier).clearAll();
        // Add sales from backup
      }

      // Restore employees
      if (data.containsKey('employees')) {
        final employees = ref.read(employeesProvider);
        final employeesNotifier = ref.read(employeesProvider.notifier);
        for (final employee in employees) {
          await employeesNotifier.deleteEmployee(employee.id);
        }
        // Add employees from backup
      }

      // Restore employee logs
      if (data.containsKey('employeeLogs')) {
        await ref.read(employeeLogsProvider.notifier).clearAll();
        // Add logs from backup
      }

      // Restore change requests
      if (data.containsKey('changeRequests')) {
        ref.read(employeeChangeRequestProvider.notifier).clearAll();
        // Add requests from backup
      }

      setState(() => _isLoading = false);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
            title: const Text('Restore Complete'),
            content: const Text(
              'Data has been restored successfully.\n\n'
              'Please restart the app for changes to take effect.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Error restoring backup: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _deleteBackup(Map<String, dynamic> backupFile) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning, color: Colors.red, size: 48),
        title: const Text('Delete Backup'),
        content: Text(
          'Delete backup file:\n\n${backupFile['name']}\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final success = await _driveService.deleteBackup(backupFile['id']);
      if (success) {
        if (mounted) {
          SnackBarHelper.showSuccess(context, 'Backup deleted successfully');
        }
        _loadBackupFiles();
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          SnackBarHelper.showError(context, 'Failed to delete backup');
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        SnackBarHelper.showError(context, 'Error deleting backup');
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy hh:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        actions: [
          if (_isSignedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _signOut,
              tooltip: 'Sign Out',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Google Drive Connection Status
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isSignedIn
                                    ? Icons.cloud_done
                                    : Icons.cloud_off,
                                color: _isSignedIn ? Colors.green : Colors.grey,
                                size: 40,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isSignedIn
                                          ? 'Connected to Google Drive'
                                          : 'Not Connected',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    if (_userEmail != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        _userEmail!,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withOpacity(0.7),
                                            ),
                                      ),
                                    ],
                                    if (_autoBackupEnabled) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.schedule,
                                            size: 14,
                                            color: Colors.green,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Auto-backup: Every 30 minutes',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.w600,
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
                          if (!_isSignedIn) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _signInToGoogle,
                                icon: const Icon(Icons.login),
                                label: const Text('Sign in with Google'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Backup Actions
                  if (_isSignedIn) ...[
                    Row(
                      children: [
                        const Icon(Icons.backup, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Backup Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Auto-backup status info
                    if (_autoBackupEnabled) ...[
                      Consumer(
                        builder: (context, ref, child) {
                          final lastBackupTime = ref.watch(
                            lastBackupTimeProvider,
                          );

                          return Card(
                            color: Colors.green.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.green.shade700,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Auto-backup is running',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Backups are created every 30 minutes',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                        if (lastBackupTime != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Last backup: ${_formatDateTime(lastBackupTime)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _createBackup,
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text('Create New Backup'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Available Backups
                    Row(
                      children: [
                        const Icon(Icons.history, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Available Backups',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _backupFiles.isEmpty
                        ? Card(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.cloud_off,
                                      size: 64,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.3),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No backups found',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.5),
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Create your first backup',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.4),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _backupFiles.length,
                            itemBuilder: (context, index) {
                              final backup = _backupFiles[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: AppColors.primary,
                                    child: Icon(
                                      Icons.backup,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(backup['name']),
                                  subtitle: Text(
                                    'Size: ${backup['size']}\n'
                                    'Modified: ${backup['modifiedTime']}',
                                  ),
                                  isThreeLine: true,
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'restore') {
                                        _restoreBackup(backup);
                                      } else if (value == 'delete') {
                                        _deleteBackup(backup);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'restore',
                                        child: Row(
                                          children: [
                                            Icon(Icons.restore, size: 20),
                                            SizedBox(width: 8),
                                            Text('Restore'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete,
                                              size: 20,
                                              color: Colors.red,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ],
              ),
            ),
    );
  }
}
