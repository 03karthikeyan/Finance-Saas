import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/services/notification_service.dart';
import 'core/storage/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/authentication/presentation/auth_cubit.dart';
import 'features/authentication/presentation/login_screen.dart';
import 'features/collections/quick_collection_pad_screen.dart';
import 'features/company_admin/company_dashboard_screen.dart';
import 'features/customers/customer_list_screen.dart';
import 'features/finance_accounts/account_list_screen.dart';
import 'features/customer_portal/presentation/customer_dashboard_screen.dart';
import 'features/customer_portal/presentation/customer_loans_screen.dart';
import 'features/customer_portal/presentation/customer_payments_screen.dart';
import 'features/customer_portal/presentation/customer_profile_screen.dart';
import 'features/layout/branch_cubit.dart';
import 'features/layout/main_layout.dart';
import 'features/layout/more_hub_screen.dart';
import 'features/payments/payment_history_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/super_admin/super_admin_dashboard_screen.dart';
import 'features/super_admin/tenant_management_screen.dart';
import 'features/super_admin/subscription_plans_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = StorageService();
  await storage.init();

  // Load custom server URL if previously saved by user (default to Render Cloud)
  final savedUrl = storage.getBaseApiUrl();
  if (savedUrl != null && savedUrl.isNotEmpty && !savedUrl.contains('192.168.29.30')) {
    AppConfig.setBaseApiUrl(savedUrl);
  } else {
    AppConfig.setBaseApiUrl(AppConfig.presetRenderCloud);
  }

  // Ensure ApiClient is configured with the resolved base URL
  ApiClient().updateBaseUrl(AppConfig.baseApiUrl);

  // Initialize Firebase Cloud Messaging & Local Notifications
  await NotificationService().init();

  runApp(const FinanceSaasApp());
}

class FinanceSaasApp extends StatelessWidget {
  const FinanceSaasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit()..checkAuthStatus()),
        BlocProvider(create: (_) => BranchCubit()..loadBranches()),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          context.read<BranchCubit>().syncWithUser(user: state.user, role: state.role);
          context.read<BranchCubit>().loadBranches(user: state.user, role: state.role);
        } else if (state is Unauthenticated) {
          context.read<BranchCubit>().resetOnLogout();
        }
      },
      builder: (context, state) {
        if (state is AuthInitial) {
          return const SplashScreen();
        }
        if (state is Authenticated) {
          return AppHomeScreen(role: state.role);
        }
        return const LoginScreen();
      },
    );
  }
}

class AppHomeScreen extends StatefulWidget {
  final String role;
  const AppHomeScreen({super.key, required this.role});

  @override
  State<AppHomeScreen> createState() => _AppHomeScreenState();
}

class _AppHomeScreenState extends State<AppHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = _getScreensForRole(widget.role);
    final activeIndex = _selectedIndex < screens.length ? _selectedIndex : 0;

    return MainLayout(
      selectedIndex: activeIndex,
      onIndexChanged: (index) => setState(() => _selectedIndex = index),
      body: screens[activeIndex],
    );
  }

  List<Widget> _getScreensForRole(String role) {
    if (role == 'SUPER_ADMIN') {
      return [
        const SuperAdminDashboardScreen(),
        const TenantManagementScreen(),
        const SubscriptionPlansScreen(),
        MoreHubScreen(role: role),
      ];
    } else if (role == 'AGENT') {
      return [
        const QuickCollectionPadScreen(),
        const CustomerListScreen(),
        const PaymentHistoryScreen(),
        MoreHubScreen(role: role),
      ];
    } else if (role == 'CUSTOMER') {
      return [
        CustomerDashboardScreen(
          onNavigateToLoans: () => setState(() => _selectedIndex = 1),
          onNavigateToPayments: () => setState(() => _selectedIndex = 2),
        ),
        const CustomerLoansScreen(),
        const CustomerPaymentsScreen(),
        const CustomerProfileScreen(),
      ];
    } else {
      // Company Admin & Managers (5 Core Android Tabs)
      return [
        CompanyDashboardScreen(
          onNavigateToCollections: () => setState(() => _selectedIndex = 1),
          onNavigateToCustomers: () => setState(() => _selectedIndex = 2),
          onNavigateToDisburse: () => setState(() => _selectedIndex = 3),
        ),
        const QuickCollectionPadScreen(),
        const CustomerListScreen(),
        const AccountListScreen(),
        MoreHubScreen(role: role),
      ];
    }
  }
}
