import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../employees/providers/employee_change_request_provider.dart';
import '../../employees/providers/employee_active_check_provider.dart';

/// Navigation drawer widget
class NavigationDrawerWidget extends ConsumerWidget {
  const NavigationDrawerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final isLargeScreen = MediaQuery.of(context).size.width > 600;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isEmployee = currentUser?.role.toLowerCase() == 'employee';

    final drawer = Container(
      width: 280,
      color: isDarkMode ? const Color(0xFF1E1E1E) : AppColors.surface,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary,
              border: Border(
                bottom: BorderSide(
                  color: isDarkMode ? Colors.grey[800]! : AppColors.border,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.point_of_sale_rounded,
                      size: 32,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'POS System',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                if (currentUser != null) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Text(
                          currentUser.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentUser.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              currentUser.role,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Menu items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Clock-in warning for employees
                if (isEmployee) ...[
                  Consumer(
                    builder: (context, ref, child) {
                      final isActive = ref.watch(isEmployeeActiveProvider);
                      if (!isActive) {
                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.warning,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lock_clock,
                                    color: AppColors.warning,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Clock In Required',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Please clock in to access features',
                                style: TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/employees');
                                  },
                                  icon: const Icon(Icons.schedule, size: 16),
                                  label: const Text('Clock In Now'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.warning,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
                _NavItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                ),
                _NavItem(
                  icon: Icons.add_shopping_cart,
                  label: 'New Sale',
                  onTap: () {
                    Navigator.pushNamed(context, '/pos');
                  },
                ),
                // Show these items only for non-Employee roles
                if (!isEmployee) ...[
                  _NavItem(
                    icon: Icons.inventory_2_outlined,
                    label: 'Products',
                    onTap: () {
                      Navigator.pushNamed(context, '/products');
                    },
                  ),
                  _NavItem(
                    icon: Icons.receipt_long_outlined,
                    label: 'Sales History',
                    onTap: () {
                      Navigator.pushNamed(context, '/sales');
                    },
                  ),
                ],
                _NavItem(
                  icon: Icons.people_outline,
                  label: isEmployee ? 'My Account' : 'Employees',
                  onTap: () {
                    Navigator.pushNamed(context, '/employees');
                  },
                ),
                // Show these items only for non-Employee roles
                if (!isEmployee) ...[
                  _NavItem(
                    icon: Icons.analytics_outlined,
                    label: 'Employee Logs',
                    onTap: () {
                      Navigator.pushNamed(context, '/employee-summary-logs');
                    },
                  ),
                  _NavItem(
                    icon: Icons.attach_money_outlined,
                    label: 'Employee Sales',
                    onTap: () {
                      Navigator.pushNamed(context, '/employee-earnings');
                    },
                  ),
                  _NavItem(
                    icon: Icons.schedule_outlined,
                    label: 'Income Summary',
                    onTap: () {
                      Navigator.pushNamed(context, '/income-summary');
                    },
                  ),
                  _NavItem(
                    icon: Icons.person_add_outlined,
                    label: 'Create Account',
                    onTap: () {
                      Navigator.pushNamed(context, '/create-account');
                    },
                  ),
                  _NavItem(
                    icon: Icons.people_alt_outlined,
                    label: 'View Accounts',
                    onTap: () {
                      Navigator.pushNamed(context, '/accounts');
                    },
                  ),
                ],
                // Show for Admin and Management only
                if (currentUser?.role.toLowerCase() == 'admin' ||
                    currentUser?.role.toLowerCase() == 'management') ...[
                  _NavItemWithBadge(
                    icon: Icons.pending_actions_outlined,
                    label: 'Change Requests',
                    badge: ref.watch(pendingRequestsCountProvider),
                    onTap: () {
                      Navigator.pushNamed(context, '/employee-change-requests');
                    },
                  ),
                ],
                const Divider(height: 24),
                _NavItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () {
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
                _NavItem(
                  icon: Icons.logout,
                  label: 'Logout',
                  textColor: AppColors.error,
                  onTap: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isLargeScreen) {
      return drawer;
    }

    return Drawer(child: drawer);
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? textColor;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDarkMode ? Colors.white : AppColors.textPrimary;

    return ListTile(
      leading: Icon(icon, color: textColor ?? defaultColor),
      title: Text(
        label,
        style: TextStyle(
          color: textColor ?? defaultColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      hoverColor: isDarkMode ? Colors.white.withOpacity(0.1) : null,
    );
  }
}

class _NavItemWithBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badge;
  final VoidCallback onTap;
  final Color? textColor;

  const _NavItemWithBadge({
    required this.icon,
    required this.label,
    required this.badge,
    required this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDarkMode ? Colors.white : AppColors.textPrimary;

    return ListTile(
      leading: Icon(icon, color: textColor ?? defaultColor),
      title: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: textColor ?? defaultColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (badge > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$badge',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      hoverColor: isDarkMode ? Colors.white.withOpacity(0.1) : null,
    );
  }
}
