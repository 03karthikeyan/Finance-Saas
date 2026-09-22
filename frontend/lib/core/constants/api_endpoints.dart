class ApiEndpoints {
  // Auth
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyResetOtp = '/auth/verify-reset-otp';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';
  static const String profile = '/auth/profile';

  // Super Admin
  static const String superAdminDashboard = '/super-admin/dashboard';
  static const String companies = '/super-admin/companies';
  static const String subscriptionPlans = '/super-admin/subscription-plans';
  static const String auditLogs = '/super-admin/audit-logs';

  // Company & Branches
  static const String companyDashboard = '/company/dashboard';
  static const String companyProfile = '/company/profile';
  static const String companySettings = '/company/settings';
  static const String branches = '/branches';

  // Agents
  static const String agents = '/agents';
  static const String agentProfile = '/agents/me';
  static const String agentDashboard = '/agents/my-dashboard';
  static const String agentAssignedCustomers = '/agents/my-customers';

  // Customers
  static const String customers = '/customers';
  static const String customerPortal = '/customers/portal-dashboard';
  static const String customerPortalSchedule = '/customers/portal-loans';
  static const String customerPortalPayments = '/customers/portal-payments';

  // Products & Accounts
  static const String financeProducts = '/finance-products';
  static const String financeAccounts = '/finance-accounts';
  static const String previewDisbursement = '/finance-accounts/preview-disbursement';
  static const String disburseLoan = '/finance-accounts/disburse';

  // Collections & Payments
  static const String recordCollection = '/collections/record';
  static const String todayCollectionSheet = '/collections/today-sheet';
  static const String todayCollections = '/collections/today-collections';
  static const String bulkCollection = '/collections/bulk';
  static const String payments = '/payments';
  static const String receipts = '/receipts';

  // Reports
  static const String reportDaily = '/reports/daily';
  static const String reportWeekly = '/reports/weekly';
  static const String reportMonthly = '/reports/monthly';
  static const String reportAgents = '/reports/agents';
  static const String reportDefaulters = '/reports/defaulters';
  static const String exportCsv = '/reports/export-csv';

  // Notifications & Documents
  static const String notifications = '/notifications';
  static const String deviceToken = '/notifications/device-token';
  static const String notificationsClearAll = '/notifications/clear-all';
  static const String notificationsBroadcast = '/notifications/broadcast';
  static const String documents = '/documents';

  // Expenses & Cashbook
  static const String expenses = '/expenses';
  static const String expensesAgentWise = '/expenses/agent-wise';
  static const String staffLedger = '/staff-ledger';

  // Agent Special Endpoints
  static const String agentMorningCashReport = '/agents/morning-cash-report';
  static String agentSalaryHistory(String id) => '/agents/$id/salary-history';
  static String agentPerformance(String id) => '/agents/$id/performance';
}
