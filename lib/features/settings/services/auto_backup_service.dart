import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../auth/providers/users_provider.dart';
import '../../products/providers/products_provider.dart';
import '../../sales/providers/sales_provider.dart';
import '../../employees/providers/employees_provider.dart';
import '../../employees/providers/employee_logs_provider.dart';
import '../../employees/providers/employee_change_request_provider.dart';
import 'google_drive_service.dart';

/// Auto Backup Service - Runs backup every 30 minutes and removes old backups
class AutoBackupService {
  static final AutoBackupService _instance = AutoBackupService._internal();
  factory AutoBackupService() => _instance;
  AutoBackupService._internal();

  Timer? _backupTimer;
  final GoogleDriveService _driveService = GoogleDriveService();
  dynamic _ref; // Can be WidgetRef or ProviderRef
  bool _isRunning = false;
  DateTime? _lastBackupTime;

  /// Initialize the auto backup service
  Future<void> initialize(dynamic ref) async {
    _ref = ref;

    // Check if signed in
    final isSignedIn = await _driveService.isSignedIn();
    if (isSignedIn) {
      startAutoBackup();
    }
  }

  /// Start automatic backup every 30 minutes
  void startAutoBackup() {
    if (_isRunning) return;

    _isRunning = true;

    // Create backup immediately
    _performAutoBackup();

    // Schedule backup every 30 minutes
    _backupTimer = Timer.periodic(
      const Duration(minutes: 30),
      (timer) => _performAutoBackup(),
    );

    print('Auto backup started - will run every 30 minutes');
  }

  /// Stop automatic backup
  void stopAutoBackup() {
    _backupTimer?.cancel();
    _backupTimer = null;
    _isRunning = false;
    print('Auto backup stopped');
  }

  /// Check if auto backup is running
  bool get isRunning => _isRunning;

  /// Get last backup time
  DateTime? get lastBackupTime => _lastBackupTime;

  /// Perform automatic backup
  Future<void> _performAutoBackup() async {
    if (_ref == null) {
      print('Auto backup error: Reference not initialized');
      return;
    }

    try {
      print('Starting automatic backup...');

      // Check if signed in
      final isSignedIn = await _driveService.isSignedIn();
      if (!isSignedIn) {
        print('Auto backup skipped: Not signed in to Google Drive');
        stopAutoBackup();
        return;
      }

      // Collect all data
      final users = _ref!.read(usersProvider);
      final products = _ref!.read(productsProvider);
      final sales = _ref!.read(salesProvider);
      final employees = _ref!.read(employeesProvider);
      final employeeLogs = _ref!.read(employeeLogsProvider);
      final changeRequests = _ref!.read(employeeChangeRequestProvider);

      final backupData = {
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'autoBackup': true,
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
          'pos_auto_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';

      // Save to local storage
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      // Upload to Google Drive
      final success = await _driveService.uploadBackup(file, fileName);

      if (success) {
        _lastBackupTime = DateTime.now();
        print('Auto backup completed successfully: $fileName');

        // Delete old backups after successful backup
        await _deleteOldBackups();
      } else {
        print('Auto backup upload failed');
      }

      // Clean up local file
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Auto backup error: $e');
    }
  }

  /// Delete all old backups except the most recent one
  Future<void> _deleteOldBackups() async {
    try {
      // Get all backup files
      final backupFiles = await _driveService.listBackupFiles();

      if (backupFiles.length <= 1) {
        print('No old backups to delete');
        return;
      }

      print('Found ${backupFiles.length} backups. Deleting old ones...');

      // Sort by modification time (newest first)
      backupFiles.sort((a, b) {
        // The list is already sorted by modifiedTime desc from the service
        return 0;
      });

      // Delete all except the most recent one
      int deletedCount = 0;
      for (int i = 1; i < backupFiles.length; i++) {
        final backup = backupFiles[i];
        final success = await _driveService.deleteBackup(backup['id']);
        if (success) {
          deletedCount++;
          print('Deleted old backup: ${backup['name']}');
        }
      }

      print(
        'Deleted $deletedCount old backup(s). Keeping only the latest backup.',
      );
    } catch (e) {
      print('Error deleting old backups: $e');
    }
  }

  /// Manually trigger backup (used by UI)
  Future<bool> manualBackup(dynamic ref) async {
    _ref = ref;
    await _performAutoBackup();
    return _lastBackupTime != null;
  }

  /// Dispose and clean up
  void dispose() {
    stopAutoBackup();
    _ref = null;
  }
}

/// Provider for auto backup service
final autoBackupServiceProvider = Provider<AutoBackupService>((ref) {
  final service = AutoBackupService();

  // Don't initialize here, let the UI initialize it
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider to check if auto backup is running
final isAutoBackupRunningProvider = Provider<bool>((ref) {
  final service = ref.watch(autoBackupServiceProvider);
  return service.isRunning;
});

/// Provider for last backup time
final lastBackupTimeProvider = Provider<DateTime?>((ref) {
  final service = ref.watch(autoBackupServiceProvider);
  return service.lastBackupTime;
});
