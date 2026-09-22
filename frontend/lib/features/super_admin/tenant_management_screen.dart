import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/app_widgets.dart';

class TenantManagementScreen extends StatefulWidget {
  const TenantManagementScreen({super.key});

  @override
  State<TenantManagementScreen> createState() => _TenantManagementScreenState();
}

class _TenantManagementScreenState extends State<TenantManagementScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _companies = [];
  String _searchQuery = '';
  String _statusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  Future<void> _fetchCompanies() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get(
        ApiEndpoints.companies,
        queryParameters: {
          if (_searchQuery.isNotEmpty) 'search': _searchQuery,
          if (_statusFilter != 'ALL') 'status': _statusFilter,
        },
      );
      if (res.success && res.data is List) {
        setState(() {
          _companies = res.data as List<dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredCompanies {
    return _companies.where((c) {
      final status = c['status']?.toString() ?? 'ACTIVE';
      if (_statusFilter != 'ALL' && status != _statusFilter) return false;

      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final name = (c['name']?.toString() ?? '').toLowerCase();
      final code = (c['companyCode']?.toString() ?? '').toLowerCase();
      final email = (c['email']?.toString() ?? '').toLowerCase();
      final phone = (c['phone']?.toString() ?? '').toLowerCase();
      return name.contains(q) || code.contains(q) || email.contains(q) || phone.contains(q);
    }).toList();
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
          title: 'Onboard Finance Company',
          subtitle: 'Create tenant database & admin credentials',
          icon: AppIcons.building2,
          iconColor: AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Company Legal Name *',
                  hintText: 'e.g. Royal Microfinance Ltd',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: codeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Company Code *',
                        hintText: 'ROYAL',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Owner Phone *',
                        hintText: '9876500000',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Company Admin Email *',
                  hintText: 'admin@royalfinance.com',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: adminNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Admin Name *',
                        hintText: 'Anand Varma',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: adminPassCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Admin Password *',
                      ),
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
                  if (nameCtrl.text.trim().isEmpty || codeCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) {
                    return;
                  }

                  setSheetState(() => isSaving = true);
                  final res = await _apiClient.post(
                    ApiEndpoints.companies,
                    data: {
                      'name': nameCtrl.text.trim(),
                      'companyCode': codeCtrl.text.trim().toUpperCase(),
                      'email': emailCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'adminName': adminNameCtrl.text.trim().isNotEmpty ? adminNameCtrl.text.trim() : 'Company Admin',
                      'adminPassword': adminPassCtrl.text.trim(),
                    },
                  );
                  setSheetState(() => isSaving = false);

                  if (res.success) {
                    if (context.mounted) Navigator.pop(sheetCtx);
                    _fetchCompanies();
                    if (context.mounted) {
                      _showOnboardingSuccessDialog(
                        companyName: nameCtrl.text.trim(),
                        companyCode: codeCtrl.text.trim().toUpperCase(),
                        phone: phoneCtrl.text.trim(),
                        adminEmail: emailCtrl.text.trim(),
                        adminName: adminNameCtrl.text.trim().isNotEmpty ? adminNameCtrl.text.trim() : 'Company Admin',
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
              final msg = '''🌟 Welcome to Media Wave Technologies Finance SaaS!

Dear $adminName,
Your finance company "$companyName" has been provisioned.

🔑 Admin Login Credentials:
• Company Code: $companyCode
• Admin Email: $adminEmail
• Password: $adminPassword

Next Steps:
1. Log in to your Mobile App or Web Console.
2. Create your Multi-District Branches and add Finance Products.
3. Onboard Field Collection Officers.

Best regards,
Media Wave Technologies Team''';

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

  void _openEditCompanySheet(Map<String, dynamic> company) {
    final compId = company['_id']?.toString() ?? '';
    final nameCtrl = TextEditingController(text: company['name']?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: company['phone']?.toString() ?? '');
    final emailCtrl = TextEditingController(text: company['email']?.toString() ?? '');
    String status = company['status']?.toString() ?? 'ACTIVE';
    bool isSaving = false;

    AppBottomSheet.show(
      context: context,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) => AppBottomSheet(
          title: 'Edit Company Details',
          subtitle: 'Update company settings and status',
          icon: AppIcons.edit,
          iconColor: AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Company Legal Name'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Company Phone'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: 'Company Email'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButton<String>(
                  value: status,
                  isExpanded: true,
                  underline: const SizedBox(),
                  dropdownColor: AppColors.surfaceElevated,
                  items: const [
                    DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE (Full Access)')),
                    DropdownMenuItem(value: 'SUSPENDED', child: Text('SUSPENDED (Locked)')),
                    DropdownMenuItem(value: 'TRIAL', child: Text('TRIAL (Evaluating)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setSheetState(() => status = val);
                  },
                ),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Save Changes',
                icon: AppIcons.check,
                isLoading: isSaving,
                onPressed: () async {
                  setSheetState(() => isSaving = true);
                  final res = await _apiClient.put(
                    '${ApiEndpoints.companies}/$compId',
                    data: {
                      'name': nameCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'email': emailCtrl.text.trim(),
                      'status': status,
                    },
                  );
                  setSheetState(() => isSaving = false);

                  if (res.success) {
                    if (context.mounted) Navigator.pop(sheetCtx);
                    _fetchCompanies();
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

  void _openResetPasswordModal(Map<String, dynamic> company) {
    final compId = company['_id']?.toString() ?? '';
    final name = company['name']?.toString() ?? 'Company';
    final email = company['email']?.toString() ?? '';
    final newPassCtrl = TextEditingController(text: 'CompanyAdmin@2026!');
    bool isSaving = false;

    AppBottomSheet.show(
      context: context,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) => AppBottomSheet(
          title: 'Reset Admin Password',
          subtitle: 'Set new login password for $name ($email)',
          icon: AppIcons.lock,
          iconColor: AppColors.warning,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: newPassCtrl,
                decoration: const InputDecoration(
                  labelText: 'New Admin Password *',
                  hintText: 'e.g. CompanyAdmin@2026!',
                ),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Update Password',
                icon: AppIcons.check,
                isLoading: isSaving,
                onPressed: () async {
                  if (newPassCtrl.text.trim().length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password must be at least 6 characters'), backgroundColor: AppColors.danger),
                    );
                    return;
                  }

                  setSheetState(() => isSaving = true);
                  final res = await _apiClient.put(
                    '${ApiEndpoints.companies}/$compId',
                    data: {
                      'adminPassword': newPassCtrl.text.trim(),
                    },
                  );
                  setSheetState(() => isSaving = false);

                  if (res.success) {
                    if (context.mounted) {
                      Navigator.pop(sheetCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Admin password updated successfully for $name!'), backgroundColor: AppColors.success),
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

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCompanies;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _fetchCompanies,
        color: AppColors.primary,
        child: Column(
          children: [
            // Top Search and Onboard Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              color: AppColors.surface,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search company name, code, phone...',
                            prefixIcon: const Icon(AppIcons.search, size: 16),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _openOnboardCompanyBottomSheet,
                        icon: const Icon(AppIcons.building2, size: 15, color: Colors.white),
                        label: const Text('Add Client', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('ALL', 'All Companies (${_companies.length})'),
                        const SizedBox(width: 8),
                        _buildFilterChip('ACTIVE', 'Active'),
                        const SizedBox(width: 8),
                        _buildFilterChip('SUSPENDED', 'Suspended'),
                        const SizedBox(width: 8),
                        _buildFilterChip('TRIAL', 'Trial'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Companies List
            Expanded(
              child: _isLoading
                  ? const AppLoading(message: 'Loading client companies...')
                  : filtered.isEmpty
                      ? const AppEmptyState(
                          title: 'No Client Companies Found',
                          subtitle: 'Tap "+ Add Client" above to onboard your first finance company.',
                          icon: AppIcons.building2,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final comp = filtered[index];
                            final name = comp['name']?.toString() ?? 'Company';
                            final code = comp['companyCode']?.toString() ?? '';
                            final phone = comp['phone']?.toString() ?? '';
                            final email = comp['email']?.toString() ?? '';
                            final status = comp['status']?.toString() ?? 'ACTIVE';
                            final logo = comp['logo']?.toString();

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      AppAvatar(
                                        imageSource: logo,
                                        radius: 20,
                                        fallbackText: name,
                                        fallbackIcon: AppIcons.building2,
                                        backgroundColor: AppColors.primarySoft,
                                        foregroundColor: AppColors.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    name,
                                                    style: const TextStyle(
                                                      color: AppColors.textPrimary,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.surfaceCard,
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: AppColors.border),
                                                  ),
                                                  child: Text(
                                                    code,
                                                    style: const TextStyle(
                                                      color: AppColors.primary,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '$phone • $email',
                                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      StatusBadge(status: status, isSmall: true),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  const Divider(color: AppColors.border, height: 1),
                                  const SizedBox(height: 8),

                                  Row(
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _openEditCompanySheet(comp),
                                        icon: const Icon(AppIcons.edit, size: 14, color: AppColors.primary),
                                        label: const Text('Edit Details', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                      ),
                                      const SizedBox(width: 4),
                                      TextButton.icon(
                                        onPressed: () => _openResetPasswordModal(comp),
                                        icon: const Icon(AppIcons.key, size: 14, color: AppColors.warning),
                                        label: const Text('Reset Password', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.warning)),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(AppIcons.messageCircle, size: 16, color: AppColors.success),
                                        tooltip: 'Share Credentials on WhatsApp',
                                        onPressed: () async {
                                          final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
                                          final targetPhone = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
                                          final msg = 'Hello from Media Wave Technologies! Your finance SaaS account for "$name" (Code: $code) is active. Login email: $email';
                                          final url = Uri.parse('https://wa.me/$targetPhone?text=${Uri.encodeComponent(msg)}');
                                          if (await canLaunchUrl(url)) {
                                            await launchUrl(url, mode: LaunchMode.externalApplication);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _statusFilter == value;
    return InkWell(
      onTap: () => setState(() => _statusFilter = value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
