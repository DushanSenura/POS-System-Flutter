import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../sales/providers/sales_provider.dart';
import '../../employees/providers/employee_active_check_provider.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/navigation_drawer_widget.dart';

/// Home dashboard screen
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final todayRevenue = ref.watch(todayRevenueProvider);
    final totalSalesCount = ref.watch(salesCountProvider);
    final todaySalesCount = ref.watch(todaySalesCountProvider);
    final averageSaleValue = ref.watch(averageSaleValueProvider);

    final isLargeScreen = MediaQuery.of(context).size.width > 600;
    final isEmployee = currentUser?.role.toLowerCase() == 'employee';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          if (currentUser != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(
                      currentUser.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  if (isLargeScreen) ...[
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          currentUser.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          currentUser.role,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
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
      drawer: isLargeScreen ? null : const NavigationDrawerWidget(),
      body: Row(
        children: [
          if (isLargeScreen) const NavigationDrawerWidget(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isLargeScreen ? 32 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome message
                  Text(
                    'Welcome back, ${currentUser?.name ?? "User"}!',
                    style: TextStyle(
                      fontSize: isLargeScreen ? 28 : 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Here\'s what\'s happening today',
                    style: TextStyle(
                      fontSize: isLargeScreen ? 16 : 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Warning card for employees who haven't clocked in
                  if (isEmployee) ...[
                    Consumer(
                      builder: (context, ref, child) {
                        final isActive = ref.watch(isEmployeeActiveProvider);
                        if (!isActive) {
                          return Column(
                            children: [
                              Card(
                                color: AppColors.warning.withOpacity(0.1),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.lock_clock,
                                        color: AppColors.warning,
                                        size: 40,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Clock In Required',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            const Text(
                                              'You need to clock in before accessing any features',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/employees',
                                          );
                                        },
                                        icon: const Icon(Icons.schedule),
                                        label: const Text('Clock In'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.warning,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],

                  // Stats cards - Different for Employee vs Admin/Management
                  if (isEmployee) ...[
                    // Employee View - Simplified stats
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: isLargeScreen ? 3 : 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isLargeScreen ? 1.5 : 1.2,
                      children: [
                        DashboardCard(
                          title: 'Today\'s Sales',
                          value: '$todaySalesCount',
                          icon: Icons.receipt_long,
                          color: AppColors.primary,
                        ),
                        DashboardCard(
                          title: 'Active',
                          value: 'On Duty',
                          icon: Icons.check_circle,
                          color: AppColors.success,
                        ),
                        DashboardCard(
                          title: 'My Shift',
                          value: 'Current',
                          icon: Icons.access_time,
                          color: AppColors.info,
                        ),
                      ],
                    ),
                  ] else ...[
                    // Admin/Management View - Full stats
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: isLargeScreen ? 4 : 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isLargeScreen ? 1.5 : 1.2,
                      children: [
                        DashboardCard(
                          title: 'Today\'s Revenue',
                          value: CurrencyFormatter.format(todayRevenue),
                          icon: Icons.attach_money,
                          color: AppColors.success,
                        ),
                        DashboardCard(
                          title: 'Total Sales',
                          value: '$totalSalesCount',
                          icon: Icons.shopping_cart,
                          color: AppColors.primary,
                        ),
                        DashboardCard(
                          title: 'Today\'s Sales',
                          value: '$todaySalesCount',
                          icon: Icons.receipt_long,
                          color: AppColors.info,
                        ),
                        DashboardCard(
                          title: 'Avg. Sale',
                          value: CurrencyFormatter.format(averageSaleValue),
                          icon: Icons.trending_up,
                          color: AppColors.warning,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Quick actions - Different for Employee vs Admin/Management
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: isLargeScreen ? 20 : 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (isEmployee) ...[
                    // Employee View - Limited actions
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: isLargeScreen ? 3 : 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isLargeScreen ? 1.3 : 1.1,
                      children: [
                        _QuickActionCard(
                          title: 'New Sale',
                          icon: Icons.add_shopping_cart,
                          color: AppColors.primary,
                          onTap: () => Navigator.pushNamed(context, '/pos'),
                        ),
                        _QuickActionCard(
                          title: 'View Employees',
                          icon: Icons.people_outline,
                          color: AppColors.info,
                          onTap: () =>
                              Navigator.pushNamed(context, '/employees'),
                        ),
                        _QuickActionCard(
                          title: 'Settings',
                          icon: Icons.settings_outlined,
                          color: AppColors.darkGrey,
                          onTap: () =>
                              Navigator.pushNamed(context, '/settings'),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Admin/Management View - Full actions
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: isLargeScreen ? 4 : 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isLargeScreen ? 1.3 : 1.1,
                      children: [
                        _QuickActionCard(
                          title: 'New Sale',
                          icon: Icons.add_shopping_cart,
                          color: AppColors.primary,
                          onTap: () => Navigator.pushNamed(context, '/pos'),
                        ),
                        _QuickActionCard(
                          title: 'Products',
                          icon: Icons.inventory_2_outlined,
                          color: AppColors.accent,
                          onTap: () =>
                              Navigator.pushNamed(context, '/products'),
                        ),
                        _QuickActionCard(
                          title: 'Sales History',
                          icon: Icons.history,
                          color: AppColors.info,
                          onTap: () => Navigator.pushNamed(context, '/sales'),
                        ),
                        _QuickActionCard(
                          title: 'Employees',
                          icon: Icons.people_outline,
                          color: AppColors.success,
                          onTap: () =>
                              Navigator.pushNamed(context, '/employees'),
                        ),
                        _QuickActionCard(
                          title: 'Settings',
                          icon: Icons.settings_outlined,
                          color: AppColors.darkGrey,
                          onTap: () =>
                              Navigator.pushNamed(context, '/settings'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
