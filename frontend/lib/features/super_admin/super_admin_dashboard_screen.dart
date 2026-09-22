import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_widgets.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  State<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  Map<String, dynamic>? _platformMetrics;
  List<dynamic> _companies = [];

  @override
  void initState() {
    super.initState();
    _fetchSuperAdminData();
  }

  Future<void> _fetchSuperAdminData() async {
    setState(() => _isLoading = true);
    try {
      final metricsRes = await _apiClient.get(ApiEndpoints.superAdminDashboard);
      final compRes = await _apiClient.get(ApiEndpoints.companies);

      setState(() {
        _platformMetrics = metricsRes.data is Map ? metricsRes.data as Map<String, dynamic> : null;
        _companies = compRes.data is List ? compRes.data as List<dynamic> : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _openOnboardCompanyBottomSheet() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final adminNameCtrl = TextEditingController();
    final adminPassCtrl = TextEditingController(text: 'CompanyAdmin@2026!');
    bool isSaving = false;

    AppBottomSheet.show(
      context: context,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) => AppBottomSheet(
          title: 'Onboard New Finance Tenant',
          subtitle: 'Provision company database & admin account',
          icon: AppIcons.building2,
          iconColor: AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Company Legal Name *', hintText: 'e.g. Royal Microfinance Ltd'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: codeCtrl,
                      decoration: const InputDecoration(labelText: 'Company Code *', hintText: 'ROYAL'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Company Phone *', hintText: '9876500000'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Company Admin Email *', hintText: 'admin@royalfinance.com'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: adminNameCtrl,
                      decoration: const InputDecoration(labelText: 'Admin Name *', hintText: 'Anand Varma'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: adminPassCtrl,
                      decoration: const InputDecoration(labelText: 'Admin Password *'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Provision Company & Create Admin',
                icon: AppIcons.check,
                isLoading: isSaving,
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty || codeCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) return;

                  setSheetState(() => isSaving = true);
                  final res = await _apiClient.post(
                    ApiEndpoints.companies,
                    data: {
                      'name': nameCtrl.text.trim(),
                      'companyCode': codeCtrl.text.trim().toUpperCase(),
                      'email': emailCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'adminName': adminNameCtrl.text.trim(),
                      'adminPassword': adminPassCtrl.text.trim(),
                    },
                  );
                  setSheetState(() => isSaving = false);

                  if (res.success) {
                    if (context.mounted) Navigator.pop(sheetCtx);
                    _fetchSuperAdminData();
                    if (context.mounted) {
                      _showOnboardingSuccessDialog(
                        companyName: nameCtrl.text.trim(),
                        companyCode: codeCtrl.text.trim().toUpperCase(),
                        phone: phoneCtrl.text.trim(),
                        adminEmail: emailCtrl.text.trim(),
                        adminName: adminNameCtrl.text.trim(),
                        adminPassword: adminPassCtrl.text.trim(),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(res.message), backgroundColor: AppColors.danger),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOnboardingSuccessDialog({
    required String companyName,
    required String companyCode,
    required String phone,
    required String adminEmail,
    required String adminName,
    required String adminPassword,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(AppIcons.checkCircle2, color: AppColors.success, size: 24),
            SizedBox(width: 8),
            Text('Tenant Provisioned!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Company "$companyName" has been created successfully.', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🏢 Code: $companyCode', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text('👤 Admin: $adminName', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('✉️ Email: $adminEmail', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('🔑 Password: $adminPassword', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(AppIcons.messageCircle, size: 16, color: Colors.white),
            label: const Text('Share on WhatsApp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            onPressed: () async {
              final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
              final targetPhone = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
              final msg = '''🌟 Welcome to FinanceMaster Pro (FMP) Platform!

Dear $adminName,
Your finance company "$companyName" has been successfully provisioned.

🔑 Admin Login Credentials:
• Company Code: $companyCode
• Admin Email: $adminEmail
• Password: $adminPassword

Next Steps:
1. Log in and open "Company Profile & Branding" to update your address & helpline.
2. Create your Multi-District Branches and add Finance Schemes.
3. Register your Field Collection Officers.

Best regards,
Mediawave Technologies Team''';

              final url = Uri.parse('https://wa.me/$targetPhone?text=${Uri.encodeComponent(msg)}');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const AppLoading(message: 'Loading platform console...');

    final m = _platformMetrics ?? {};
    final totalCompanies = m['totalCompanies'] ?? 0;
    final activeCompanies = m['activeCompanies'] ?? 0;
    final totalUsers = m['totalUsers'] ?? 0;
    final totalPlatformVol = (m['totalPlatformCollectionVolume'] as num?)?.toDouble() ?? 0.0;

    final isDesktop = MediaQuery.of(context).size.width >= 750;

    return RefreshIndicator(
      onRefresh: _fetchSuperAdminData,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Media Wave Technologies Platform Master Hero Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(AppIcons.shield, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Media Wave Technologies',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        Text(
                          'Finance SaaS Master Console',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 7, color: AppColors.success),
                      SizedBox(width: 4),
                      Text('ONLINE', style: TextStyle(color: AppColors.success, fontSize: 9.5, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Platform Overview',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _openOnboardCompanyBottomSheet,
                icon: const Icon(AppIcons.building2, size: 15, color: Colors.white),
                label: const Text('Onboard Client', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2-Column Responsive Metric Grid
          GridView.count(
            crossAxisCount: isDesktop ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: isDesktop ? 1.5 : 1.15,
            children: [
              StatMetricCard(
                title: 'Total Tenants',
                value: totalCompanies.toString(),
                subtitle: '$activeCompanies Active',
                icon: AppIcons.building2,
                iconColor: AppColors.primary,
              ),
              StatMetricCard(
                title: 'Platform Volume',
                value: CurrencyFormatter.format(totalPlatformVol),
                subtitle: 'Total processed',
                icon: AppIcons.trendingUp,
                iconColor: AppColors.info,
              ),
              StatMetricCard(
                title: 'Total Users',
                value: totalUsers.toString(),
                subtitle: 'Staff & Agents',
                icon: AppIcons.users,
                iconColor: AppColors.accentIndigo,
              ),
              StatMetricCard(
                title: 'Subscriptions',
                value: '$activeCompanies / $totalCompanies',
                subtitle: 'Active plans',
                icon: AppIcons.creditCard,
                iconColor: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 20),

          const Text(
            'Onboarded Finance Tenants',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // Companies List
          if (_companies.isEmpty)
            const AppEmptyState(title: 'No Companies Onboarded', icon: AppIcons.building)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _companies.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final comp = _companies[idx];
                final name = comp['name']?.toString() ?? '';
                final code = comp['companyCode']?.toString() ?? '';
                final email = comp['email']?.toString() ?? '';
                final phone = comp['phone']?.toString() ?? '';
                final status = comp['status']?.toString() ?? 'ACTIVE';

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                        child: const Icon(AppIcons.building2, color: AppColors.primary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(4)),
                                  child: Text(code, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text('$email • $phone', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          ],
                        ),
                      ),
                      StatusBadge(status: status, isSmall: true),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
