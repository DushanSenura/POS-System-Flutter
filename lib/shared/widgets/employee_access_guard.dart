import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../features/employees/providers/employee_active_check_provider.dart';

/// Widget that guards access to features for employees who haven't clocked in
class EmployeeAccessGuard extends ConsumerWidget {
  final Widget child;
  final bool showDialogOnBlock;

  const EmployeeAccessGuard({
    super.key,
    required this.child,
    this.showDialogOnBlock = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = ref.watch(isEmployeeActiveProvider);
    final blockReason = ref.watch(employeeAccessBlockReasonProvider);

    // If employee is not active and has a block reason, show dialog or overlay
    if (!isActive && blockReason != null) {
      if (showDialogOnBlock) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showAccessBlockedDialog(context, blockReason);
        });
      }

      return _BlockedOverlay(reason: blockReason, child: child);
    }

    return child;
  }

  void _showAccessBlockedDialog(BuildContext context, String reason) {
    if (ModalRoute.of(context)?.isCurrent != true) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.lock_clock, color: AppColors.warning, size: 48),
        title: const Text('Clock In Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              reason,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Go to Employees page and clock in to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/employees');
            },
            child: const Text('Go to Employees'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/home');
            },
            child: const Text('Go to Dashboard'),
          ),
        ],
      ),
    );
  }
}

class _BlockedOverlay extends StatelessWidget {
  final String reason;
  final Widget child;

  const _BlockedOverlay({required this.reason, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AbsorbPointer(
          absorbing: true,
          child: Opacity(opacity: 0.3, child: child),
        ),
        Center(
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_clock,
                    color: AppColors.warning,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Clock In Required',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    reason,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/employees');
                    },
                    icon: const Icon(Icons.schedule),
                    label: const Text('Go to Clock In'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
