import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/create_account_screen.dart';
import 'features/auth/screens/accounts_screen.dart';
import 'features/dashboard/screens/home_screen.dart';
import 'features/pos/screens/pos_screen.dart';
import 'features/products/screens/products_screen.dart';
import 'features/sales/screens/sales_history_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/settings/screens/receipt_settings_screen.dart';
import 'features/settings/providers/settings_provider.dart';
import 'features/products/models/product_model.dart';
import 'features/auth/models/user_model.dart';
import 'features/cart/models/cart_item_model.dart';
import 'features/sales/models/sale_model.dart';
import 'features/settings/models/store_settings_model.dart';
import 'features/employees/models/employee_model.dart';
import 'features/employees/models/employee_log_model.dart';
import 'features/employees/screens/employees_screen.dart';
import 'features/employees/screens/employee_summary_logs_screen.dart';
import 'features/employees/screens/employee_earnings_screen.dart';
import 'features/employees/screens/employee_profile_edit_screen.dart';
import 'features/employees/screens/employee_change_requests_screen.dart';
import 'features/sales/screens/income_summary_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(CartItemAdapter());
  Hive.registerAdapter(SaleAdapter());
  Hive.registerAdapter(StoreSettingsAdapter());
  Hive.registerAdapter(EmployeeAdapter());
  Hive.registerAdapter(EmployeeLogAdapter());

  // Open boxes
  await Hive.openBox<Product>('products');
  await Hive.openBox<User>(AppConstants.userBoxName);
  await Hive.openBox<Sale>('sales');
  await Hive.openBox<Employee>('employees');
  await Hive.openBox<EmployeeLog>('employee_logs');
  await Hive.openBox('settings');
  await Hive.openBox('categories');
  await Hive.openBox('companies');

  runApp(
    // Wrap app with ProviderScope for Riverpod
    const ProviderScope(child: MyApp()),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,

          // Theme configuration
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,

          // Routing configuration
          initialRoute: '/login',
          routes: {
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const HomeScreen(),
            '/pos': (context) => const PosScreen(),
            '/products': (context) => const ProductsScreen(),
            '/sales': (context) => const SalesHistoryScreen(),
            '/employees': (context) => const EmployeesScreen(),
            '/employee-summary-logs': (context) =>
                const EmployeeSummaryLogsScreen(),
            '/employee-earnings': (context) => const EmployeeEarningsScreen(),
            '/employee-profile-edit': (context) =>
                const EmployeeProfileEditScreen(),
            '/employee-change-requests': (context) =>
                const EmployeeChangeRequestsScreen(),
            '/income-summary': (context) => const IncomeSummaryScreen(),
            '/create-account': (context) => const CreateAccountScreen(),
            '/accounts': (context) => const AccountsScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/receipt-settings': (context) => const ReceiptSettingsScreen(),
          },

          // Handle unknown routes
          onUnknownRoute: (settings) {
            return MaterialPageRoute(builder: (context) => const LoginScreen());
          },
        );
      },
    );
  }
}
