import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_widgets.dart';
import '../authentication/presentation/auth_cubit.dart';
import '../agents/agent_list_screen.dart';
import '../agents/agent_route_map_screen.dart';
import '../agents/agent_salary_screen.dart';
import '../company_admin/company_profile_screen.dart';
import '../company_admin/branch_management_screen.dart';
import '../finance_products/product_list_screen.dart';
import '../payments/payment_history_screen.dart';
import '../reports/reports_screen.dart';
import '../super_admin/super_admin_dashboard_screen.dart';
import '../super_admin/tenant_management_screen.dart';
import '../super_admin/subscription_plans_screen.dart';
import '../super_admin/audit_logs_screen.dart';
import '../../core/widgets/server_config_dialog.dart';
import '../../core/localization/app_localization.dart';
import '../expenses/expense_management_screen.dart';
import '../staff/staff_ledger_screen.dart';
import 'branch_cubit.dart';

class MoreHubScreen extends StatefulWidget {
  final String role;
  const MoreHubScreen({super.key, required this.role});

  @override
  State<MoreHubScreen> createState() => _MoreHubScreenState();
}

class _MoreHubScreenState extends State<MoreHubScreen> {
  String? _liveAgentPhoto;

  @override
  void initState() {
    super.initState();
    _loadLiveAgentPhoto();
  }

  Future<void> _loadLiveAgentPhoto() async {
    if (widget.role == 'AGENT') {
      try {
        final res = await ApiClient().get(ApiEndpoints.agentProfile);
        if (res.success && res.data is Map<String, dynamic>) {
          final data = res.data as Map<String, dynamic>;
          final photo = data['profileImage']?.toString() ??
              (data['userId'] is Map ? data['userId']['profileImage']?.toString() : null);
          if (photo != null && photo.isNotEmpty && mounted) {
            setState(() {
              _liveAgentPhoto = photo;
            });
          }
        }
      } catch (_) {}
    }
  }

  void _navigateToScreen(BuildContext context, Widget screen, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            leading: IconButton(
              icon: const Icon(AppIcons.chevronLeft, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
          body: screen,
        ),
      ),
    );
  }

  void _showLanguageSelectorSheet(BuildContext context) {
    AppBottomSheet.show(
      context: context,
      builder: (sheetCtx) {
        return AppBottomSheet(
          title: 'Select Language / மொழி',
          subtitle: 'Choose your preferred display language',
          icon: AppIcons.globe,
          iconColor: AppColors.primary,
          child: Column(
            children: [
              ListTile(
                title: const Text('English', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Default English UI'),
                trailing: AppLocalization.currentLanguage.value == AppLanguage.en
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () {
                  AppLocalization.setLanguage(AppLanguage.en);
                  Navigator.pop(sheetCtx);
                  setState(() {});
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('தமிழ் (Tamil)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('தமிழ் இடைமுகம்'),
                trailing: AppLocalization.currentLanguage.value == AppLanguage.ta
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () {
                  AppLocalization.setLanguage(AppLanguage.ta);
                  Navigator.pop(sheetCtx);
                  setState(() {});
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('हिंदी (Hindi)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('हिंदी भाषा'),
                trailing: AppLocalization.currentLanguage.value == AppLanguage.hi
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () {
                  AppLocalization.setLanguage(AppLanguage.hi);
                  Navigator.pop(sheetCtx);
                  setState(() {});
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('తెలుగు (Telugu)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('తెలుగు భాష'),
                trailing: AppLocalization.currentLanguage.value == AppLanguage.te
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () {
                  AppLocalization.setLanguage(AppLanguage.te);
                  Navigator.pop(sheetCtx);
                  setState(() {});
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openChangePasswordSheet(BuildContext context) {
    final oldPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    bool isSaving = false;
    bool obscureOld = true;
    bool obscureNew = true;

    AppBottomSheet.show(
      context: context,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) => AppBottomSheet(
          title: 'Change Password',
          subtitle: 'Update your account login security password',
          icon: AppIcons.lock,
          iconColor: AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: oldPasswordCtrl,
                obscureText: obscureOld,
                decoration: InputDecoration(
                  labelText: 'Current Password *',
                  prefixIcon: const Icon(AppIcons.lock, size: 18, color: AppColors.textMuted),
                  suffixIcon: IconButton(
                    icon: Icon(obscureOld ? AppIcons.eyeOff : AppIcons.eye, size: 18, color: AppColors.textMuted),
                    onPressed: () => setSheetState(() => obscureOld = !obscureOld),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordCtrl,
                obscureText: obscureNew,
                decoration: InputDecoration(
                  labelText: 'New Password (min 6 chars) *',
                  prefixIcon: const Icon(AppIcons.lock, size: 18, color: AppColors.textMuted),
                  suffixIcon: IconButton(
                    icon: Icon(obscureNew ? AppIcons.eyeOff : AppIcons.eye, size: 18, color: AppColors.textMuted),
                    onPressed: () => setSheetState(() => obscureNew = !obscureNew),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordCtrl,
                obscureText: obscureNew,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password *',
                  prefixIcon: Icon(AppIcons.badgeCheck, size: 18, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Update Password',
                icon: AppIcons.check,
                isLoading: isSaving,
                onPressed: () async {
                  if (oldPasswordCtrl.text.trim().isEmpty || newPasswordCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all required password fields')),
                    );
                    return;
                  }
                  if (newPasswordCtrl.text.trim() != confirmPasswordCtrl.text.trim()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('New passwords do not match')),
                    );
                    return;
                  }

                  setSheetState(() => isSaving = true);
                  final res = await ApiClient().post(
                    ApiEndpoints.changePassword,
                    data: {
                      'oldPassword': oldPasswordCtrl.text.trim(),
                      'newPassword': newPasswordCtrl.text.trim(),
                    },
                  );
                  setSheetState(() => isSaving = false);

                  if (res.success) {
                    if (context.mounted) {
                      Navigator.pop(sheetCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password updated successfully!'), backgroundColor: AppColors.success),
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

  void _showAgentProfileModal(BuildContext context, Map<String, dynamic> user, String companyName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    final res = await ApiClient().get(ApiEndpoints.agentProfile);
    if (context.mounted) Navigator.pop(context);
    if (!context.mounted) return;

    final agentData = res.success && res.data is Map ? res.data as Map<String, dynamic> : null;
    final agentUser = agentData?['userId'] as Map<String, dynamic>? ?? user;
    final agentName = agentUser['name']?.toString() ?? user['name']?.toString() ?? 'Field Officer';
    final agentCode = agentData?['agentCode']?.toString() ?? 'OFFICER';
    final agentEmail = agentUser['email']?.toString() ?? user['email']?.toString() ?? '';
    final agentPhone = agentUser['phone']?.toString() ?? user['phone']?.toString() ?? '';
    final agentPhoto = agentUser['profileImage']?.toString() ?? agentData?['profileImage']?.toString();
    final branchObj = agentData?['branchId'] as Map<String, dynamic>?;
    final branchName = branchObj?['name']?.toString() ?? 'Main Branch';
    final proofType = agentData?['proofType']?.toString() ?? 'Aadhaar Card';
    final proofNumber = agentData?['proofNumber']?.toString() ?? 'Not Verified';
    final emg = agentData?['emergencyContact'] as Map<String, dynamic>? ?? {};
    final emgName = emg['name']?.toString() ?? 'Not Provided';
    final emgPhone = emg['phone']?.toString() ?? '';
    final emgRelation = emg['relation']?.toString() ?? '';
    final target = (agentData?['dailyTarget'] as num?)?.toDouble() ?? 0.0;
    final collected = (agentData?['totalCollected'] as num?)?.toDouble() ?? 0.0;
    final routes = agentData?['assignedRoutes'] as List<dynamic>? ?? [];
    final status = agentData?['status']?.toString() ?? 'ACTIVE';
    final createdAt = agentData?['createdAt']?.toString();
    final joinDate = createdAt != null ? DateFormat('dd MMM yyyy').format(DateTime.tryParse(createdAt) ?? DateTime.now()) : 'Active';

    AppBottomSheet.show(
      context: context,
      builder: (sheetCtx) => AppBottomSheet(
        title: 'Officer Profile & Allocations',
        subtitle: '$agentName • $companyName',
        icon: AppIcons.badgeCheck,
        iconColor: AppColors.primary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Profile Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  AppAvatar(
                    imageSource: agentPhoto,
                    radius: 32,
                    fallbackText: agentName,
                    fallbackIcon: AppIcons.userCheck,
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.primary,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                agentName,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                agentCode,
                                style: const TextStyle(color: AppColors.primaryDark, fontSize: 10.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$agentPhone | $agentEmail',
                          style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            StatusBadge(status: status, isSmall: true),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accentCyan.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(AppIcons.building, size: 10, color: AppColors.accentCyan),
                                  const SizedBox(width: 4),
                                  Text(branchName, style: const TextStyle(color: AppColors.accentCyan, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Performance & Targets Grid
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(AppIcons.award, size: 14, color: AppColors.warning),
                            SizedBox(width: 4),
                            Text('Daily Target', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(target),
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(AppIcons.coins, size: 14, color: AppColors.success),
                            SizedBox(width: 4),
                            Text('Total Collected', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(collected),
                          style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Assigned Lines & Routes
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(AppIcons.globe, size: 14, color: AppColors.accentIndigo),
                      SizedBox(width: 6),
                      Text('Assigned Line Routes', style: TextStyle(color: AppColors.textPrimary, fontSize: 12.5, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  routes.isNotEmpty
                      ? Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: routes.map((r) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(r.toString(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          )).toList(),
                        )
                      : const Text('All general branch routes', style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Identity KYC & Emergency Details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Identity Proof KYC', style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                      Text('$proofType: $proofNumber', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11.5)),
                    ],
                  ),
                  const Divider(color: AppColors.border, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Emergency Contact', style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                      Text(
                        emgPhone.isNotEmpty ? '$emgName ($emgRelation) • $emgPhone' : emgName,
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11.5),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.border, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Onboarding Date', style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                      Text(joinDate, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11.5)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Actions
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(sheetCtx);
                _openChangePasswordSheet(context);
              },
              icon: const Icon(AppIcons.lock, size: 16, color: Colors.white),
              label: const Text('Change My Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdminProfileModal(BuildContext context, Map<String, dynamic> user, String companyName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    final res = await ApiClient().get(ApiEndpoints.companyProfile);
    if (context.mounted) Navigator.pop(context);
    if (!context.mounted) return;

    final companyData = res.success && res.data is Map ? res.data as Map<String, dynamic> : {};
    final cName = companyData['name']?.toString() ?? companyName;
    final cCode = companyData['companyCode']?.toString() ?? '';
    final logo = companyData['logo']?.toString();
    final regNum = companyData['registrationNumber']?.toString() ?? 'Not Configured';
    final taxNum = companyData['taxNumber']?.toString() ?? 'Not Configured';
    final phone = companyData['phone']?.toString() ?? '';
    final email = companyData['email']?.toString() ?? '';
    final supportPhone = companyData['supportPhone']?.toString() ?? '';
    final addr = companyData['address'] as Map<String, dynamic>? ?? {};
    final city = addr['city']?.toString() ?? '';
    final district = addr['district']?.toString() ?? '';

    AppBottomSheet.show(
      context: context,
      builder: (sheetCtx) => AppBottomSheet(
        title: 'Company & Admin Credentials',
        subtitle: '$cName • Multi-Tenant SaaS',
        icon: AppIcons.building2,
        iconColor: AppColors.primary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Company Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  AppAvatar(
                    imageSource: logo,
                    radius: 28,
                    fallbackIcon: AppIcons.building2,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tenant Code: $cCode',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          district.isNotEmpty ? '$district, Tamil Nadu' : 'Tamil Nadu',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Business Legal Details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('MSME / Reg Number', style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                      Text(regNum, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11.5)),
                    ],
                  ),
                  const Divider(color: AppColors.border, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('GSTIN / Tax ID', style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                      Text(taxNum, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11.5)),
                    ],
                  ),
                  const Divider(color: AppColors.border, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Billing Email', style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                      Text(email.isNotEmpty ? email : 'Not Configured', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11.5)),
                    ],
                  ),
                  const Divider(color: AppColors.border, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('City / Location', style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                      Text(city.isNotEmpty ? city : district, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11.5)),
                    ],
                  ),
                  const Divider(color: AppColors.border, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Primary Office Phone', style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                      Text(phone.isNotEmpty ? phone : 'Not Configured', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11.5)),
                    ],
                  ),
                  const Divider(color: AppColors.border, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Support WhatsApp', style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                      Text(supportPhone.isNotEmpty ? supportPhone : 'Not Configured', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11.5)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      _navigateToScreen(context, const CompanyProfileScreen(), 'Company Profile & Branding');
                    },
                    icon: const Icon(AppIcons.edit, size: 15, color: Colors.white),
                    label: const Text('Edit Branding', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      _openChangePasswordSheet(context);
                    },
                    icon: const Icon(AppIcons.lock, size: 15, color: AppColors.textPrimary),
                    label: const Text('Change Password', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12.5)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final branchState = context.watch<BranchCubit>().state;

    String userName = 'User';
    String email = '';
    String companyName = 'Finance SaaS';
    String? profilePhoto;
    Map<String, dynamic> userMap = {};

    if (authState is Authenticated) {
      userMap = authState.user;
      userName = userMap['name']?.toString() ?? 'User';
      email = userMap['email']?.toString() ?? '';
      profilePhoto = _liveAgentPhoto ?? userMap['profileImage']?.toString();
      companyName = authState.companyName ?? 'Finance SaaS';
    } else {
      profilePhoto = _liveAgentPhoto;
    }

    final isAgent = widget.role == 'AGENT';
    final isSuperAdmin = widget.role == 'SUPER_ADMIN';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // Top Interactive Profile Card
        InkWell(
          onTap: () {
            if (isAgent) {
              _showAgentProfileModal(context, userMap, companyName);
            } else {
              _showAdminProfileModal(context, userMap, companyName);
            }
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                AppAvatar(
                  imageSource: profilePhoto,
                  radius: 26,
                  fallbackText: userName,
                  fallbackIcon: isAgent ? AppIcons.userCheck : AppIcons.building2,
                  backgroundColor: AppColors.primarySoft,
                  foregroundColor: AppColors.primary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              userName,
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.role.replaceAll('_', ' '),
                              style: const TextStyle(color: AppColors.primaryDark, fontSize: 9.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceCard,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              companyName,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (!isSuperAdmin && !branchState.isAllBranches)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accentCyan.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(AppIcons.building, size: 9, color: AppColors.accentCyan),
                                  const SizedBox(width: 3),
                                  Text(
                                    branchState.activeBranchName,
                                    style: const TextStyle(color: AppColors.accentCyan, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(AppIcons.chevronRight, color: AppColors.textMuted, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 1. Super Admin Platform Management (Media Wave Technologies)
        if (isSuperAdmin) ...[
          const Text(
            'SAAS PLATFORM OWNER TOOLS',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),
          _buildMenuTile(
            context,
            icon: AppIcons.layoutDashboard,
            iconColor: AppColors.primary,
            title: 'Master Executive Console',
            subtitle: 'Overview of all companies, total platform volume & stats',
            onTap: () => _navigateToScreen(context, const SuperAdminDashboardScreen(), 'Executive Console'),
          ),
          _buildMenuTile(
            context,
            icon: AppIcons.building2,
            iconColor: AppColors.accentCyan,
            title: 'Client Companies (Tenants)',
            subtitle: 'Onboard finance companies, provision credentials & WhatsApp share',
            onTap: () => _navigateToScreen(context, const TenantManagementScreen(), 'Client Companies'),
          ),
          _buildMenuTile(
            context,
            icon: AppIcons.badgeCheck,
            iconColor: AppColors.accentIndigo,
            title: 'SaaS Subscription Plans',
            subtitle: 'Define pricing tiers, branch quotas, agent limits & features',
            onTap: () => _navigateToScreen(context, const SubscriptionPlansScreen(), 'Subscription Plans'),
          ),
          _buildMenuTile(
            context,
            icon: AppIcons.shield,
            iconColor: AppColors.accentPurple,
            title: 'Global System Audit Trail',
            subtitle: 'Live activity log of tenant provisioning, logins & system events',
            onTap: () => _navigateToScreen(context, const AuditLogsScreen(), 'Global Audit Logs'),
          ),
          _buildMenuTile(
            context,
            icon: AppIcons.settings,
            iconColor: AppColors.info,
            title: 'Server & Database Configuration',
            subtitle: 'Switch backend host (Cloud / Localhost) and test connection',
            onTap: () => showDialog(context: context, builder: (_) => const ServerConfigDialog()),
          ),
          _buildMenuTile(
            context,
            icon: AppIcons.lock,
            iconColor: AppColors.warning,
            title: 'Change Master Password',
            subtitle: 'Update Super Admin security credentials',
            onTap: () => _openChangePasswordSheet(context),
          ),
        ]
        // 2. Field Agent Operational Tools
        else if (isAgent) ...[
          const Text(
            'FIELD OFFICER TOOLS',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),
          _buildMenuTile(
            context,
            icon: AppIcons.badgeCheck,
            iconColor: AppColors.primary,
            title: "Today's Collection Activity",
            subtitle: 'View receipts collected today across your lines',
            onTap: () => TodayCollectionActivitySheet.show(context),
          ),
          _buildMenuTile(
            context,
            icon: Icons.map_rounded,
            iconColor: AppColors.accentCyan,
            title: 'Route Map',
            subtitle: 'See your customers on the map — paid, pending, overdue pins',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentRouteMapScreen())),
          ),
          _buildMenuTile(
            context,
            icon: Icons.account_balance_wallet_rounded,
            iconColor: AppColors.success,
            title: 'My Salary & Allowance Ledger',
            subtitle: 'Monthly salary, advances, cash handover history',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentSalaryScreen())),
          ),
          _buildMenuTile(
            context,
            icon: Icons.bar_chart_rounded,
            iconColor: AppColors.accentIndigo,
            title: 'My Performance Report',
            subtitle: 'Collection vs target, commission earned by month',
            onTap: () => _navigateToScreen(context, const ExpenseManagementScreen(), 'My Cashbook & Expenses'),
          ),
          _buildMenuTile(
            context,
            icon: AppIcons.receipt,
            iconColor: AppColors.warning,
            title: 'My Collection History',
            subtitle: 'Past payment receipts & WhatsApp share history',
            onTap: () => _navigateToScreen(context, const PaymentHistoryScreen(), 'My Collection History'),
          ),
          _buildMenuTile(
            context,
            icon: AppIcons.wallet,
            iconColor: AppColors.accentPurple,
            title: 'My Expenses Today',
            subtitle: 'Log petrol, tea, field expenses for the day',
            onTap: () => _navigateToScreen(context, const ExpenseManagementScreen(), 'My Expenses'),
          ),
          _buildMenuTile(
            context,
            icon: AppIcons.lock,
            iconColor: AppColors.textMuted,
            title: 'Change Password',
            subtitle: 'Update your account login security password',
            onTap: () => _openChangePasswordSheet(context),
          ),
        ]
        // 3. Company Admin Management Modules
        else ...[
          const Text(
            'MANAGEMENT MODULES',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),
          _buildMenuTile(
            context,
            icon: AppIcons.building,
            iconColor: AppColors.accentCyan,
            title: 'Multi-District Branches',
            subtitle: 'Branch offices, district lines, branch codes & managers',
            onTap: () => _navigateToScreen(context, const BranchManagementScreen(), 'Multi-District Branches'),
          ),
          _buildMenuTile(
            context,
            icon: AppIcons.userCheck,
            iconColor: AppColors.accentIndigo,
            title: 'Field Agents & Routes',
            subtitle: 'Manage collection staff, photo KYC, daily targets, line assignments',
            onTap: () => _navigateToScreen(context, const AgentListScreen(), 'Agents & Routes'),
          ),
          _buildMenuTile(
            context,
            icon: Icons.wb_sunny_rounded,
            iconColor: AppColors.warning,
            title: 'Morning Cash Handover Report',
            subtitle: 'Daily cash given to each agent + their today collections',
            onTap: () => _navigateToScreen(context, const AgentListScreen(), 'Morning Cash Report'),
          ),
          _buildMenuTile(
            context,
            icon: AppIcons.badgeCheck,
            iconColor: AppColors.success,
            title: "Today's Collections Breakdown",
            subtitle: 'Real-time list of payments collected today with agent names',
            onTap: () => TodayCollectionActivitySheet.show(context),
          ),
          _buildMenuTile(
            context,
            icon: AppIcons.barChart3,
            iconColor: AppColors.primary,
            title: 'Financial Reports & Analytics',
            subtitle: 'Daily inflow, recovery rates, agent rankings, defaulters',
            onTap: () => _navigateToScreen(context, const ReportsScreen(), 'Financial Reports'),
          ),
          _buildMenuTile(
            context,
            icon: AppIcons.packagePlus,
            iconColor: AppColors.primaryDark,
            title: 'Finance Schemes & Products',
            subtitle: 'Daily micro-loans, weekly SME loans, doc charges',
            onTap: () => _navigateToScreen(context, const ProductListScreen(), 'Finance Schemes'),
          ),
          _buildMenuTile(
            context,
            icon: AppIcons.receipt,
            iconColor: AppColors.warning,
            title: 'Payment Transactions Ledger',
            subtitle: 'Complete collection log, digital receipts & audit history',
            onTap: () => _navigateToScreen(context, const PaymentHistoryScreen(), 'Payment Transactions'),
          ),
          _buildMenuTile(
            context,
            icon: AppIcons.wallet,
            iconColor: AppColors.success,
            title: 'Expense & Daily Cashbook',
            subtitle: 'Log petrol, rent, tea expenses & daily cash in hand P&L',
            onTap: () => _navigateToScreen(context, const ExpenseManagementScreen(), 'Cashbook & Expenses'),
          ),
          _buildMenuTile(
            context,
            icon: AppIcons.users,
            iconColor: AppColors.accentIndigo,
            title: 'Staff Salary & Advance Ledger',
            subtitle: 'Record staff salary payouts, petrol allowances & advances',
            onTap: () => _navigateToScreen(context, const StaffLedgerScreen(), 'Staff & Salary Ledger'),
          ),
          _buildMenuTile(
            context,
            icon: AppIcons.globe,
            iconColor: AppColors.primary,
            title: 'App Language / மொழி',
            subtitle: 'Switch English, Tamil (தமிழ்), Hindi (हिंदी), Telugu (తెలుగు)',
            onTap: () => _showLanguageSelectorSheet(context),
          ),
          _buildMenuTile(
            context,
            icon: AppIcons.lock,
            iconColor: AppColors.info,
            title: 'Change Password',
            subtitle: 'Update your account login security password',
            onTap: () => _openChangePasswordSheet(context),
          ),
        ],

        const SizedBox(height: 20),

        // System & Connectivity Section
        const Text(
          'SYSTEM & SESSION',
          style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
        ),
        const SizedBox(height: 10),

        _buildMenuTile(
          context,
          icon: AppIcons.logOut,
          iconColor: AppColors.danger,
          title: 'Sign Out',
          subtitle: 'Securely logout from this device',
          textColor: AppColors.danger,
          onTap: () => context.read<AuthCubit>().logout(),
        ),

        const SizedBox(height: 24),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${AppConfig.appFullName} • v${AppConfig.appVersion}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text(
                AppConfig.poweredBy,
                style: TextStyle(color: AppColors.textMuted, fontSize: 10.5, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(AppIcons.chevronRight, color: AppColors.textMuted, size: 16),
      ),
    );
  }
}
