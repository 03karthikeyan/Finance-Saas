import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../authentication/presentation/auth_cubit.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _portalData;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final results = await Future.wait([
        ApiClient().get(ApiEndpoints.customerPortal),
        ApiClient().get(ApiEndpoints.branches),
        ApiClient().get(ApiEndpoints.agents),
      ]);

      final portalRes = results[0];
      final branchesRes = results[1];
      final agentsRes = results[2];

      if (portalRes.success && portalRes.data is Map<String, dynamic>) {
        final data = Map<String, dynamic>.from(portalRes.data as Map<String, dynamic>);
        final customer = (data['customer'] is Map) ? Map<String, dynamic>.from(data['customer'] as Map) : <String, dynamic>{};

        final branchesList = (branchesRes.success && branchesRes.data is List)
            ? (branchesRes.data as List).whereType<Map<String, dynamic>>().toList()
            : <Map<String, dynamic>>[];

        final agentsList = (agentsRes.success && agentsRes.data is List)
            ? (agentsRes.data as List).whereType<Map<String, dynamic>>().toList()
            : <Map<String, dynamic>>[];

        // 1. Resolve Branch Details
        if (data['branch'] == null || (data['branch'] is Map && (data['branch'] as Map)['name'] == null)) {
          final bId = customer['branchId']?.toString() ?? '';
          if (bId.isNotEmpty && branchesList.isNotEmpty) {
            final match = branchesList.firstWhere(
              (b) => b['_id']?.toString() == bId || b['id']?.toString() == bId,
              orElse: () => branchesList.first,
            );
            data['branch'] = match;
          } else if (branchesList.isNotEmpty) {
            data['branch'] = branchesList.first;
          }
        }

        // 2. Resolve Primary Assigned Agent Details
        final branchObj = data['branch'] as Map<String, dynamic>?;
        final resolvedBranchId = branchObj?['_id']?.toString() ?? branchObj?['id']?.toString() ?? customer['branchId']?.toString() ?? '';

        if (data['assignedAgent'] == null || (data['assignedAgent'] is Map && (data['assignedAgent'] as Map)['name'] == null)) {
          final aId = customer['assignedAgentId']?.toString() ?? '';
          if (aId.isNotEmpty && agentsList.isNotEmpty) {
            final match = agentsList.firstWhere(
              (a) => a['_id']?.toString() == aId || a['id']?.toString() == aId,
              orElse: () => <String, dynamic>{},
            );
            if (match.isNotEmpty) {
              final userObj = match['userId'] is Map ? match['userId'] as Map<String, dynamic> : <String, dynamic>{};
              data['assignedAgent'] = {
                'id': match['_id'] ?? match['id'],
                'agentCode': match['agentCode'] ?? 'AGENT',
                'name': userObj['name'] ?? match['name'] ?? 'Field Officer',
                'phone': userObj['phone'] ?? match['phone'] ?? branchObj?['phone'] ?? '',
                'email': userObj['email'] ?? match['email'] ?? '',
                'profileImage': match['profileImage'] ?? userObj['profileImage'] ?? '',
                'assignedRoutes': match['assignedRoutes'] ?? [],
              };
            }
          }

          if (data['assignedAgent'] == null && agentsList.isNotEmpty) {
            final route = customer['address'] is Map ? (customer['address']['routeArea']?.toString() ?? '') : '';
            Map<String, dynamic>? match;
            if (route.isNotEmpty) {
              match = agentsList.firstWhere(
                (a) {
                  final routes = (a['assignedRoutes'] as List<dynamic>?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
                  return routes.contains(route.toLowerCase());
                },
                orElse: () => <String, dynamic>{},
              );
            }
            if (match == null || match.isEmpty) {
              if (resolvedBranchId.isNotEmpty) {
                match = agentsList.firstWhere(
                  (a) => a['branchId']?.toString() == resolvedBranchId || (a['branchId'] is Map && (a['branchId'] as Map)['_id']?.toString() == resolvedBranchId),
                  orElse: () => agentsList.first,
                );
              } else {
                match = agentsList.first;
              }
            }

            if (match.isNotEmpty) {
              final userObj = match['userId'] is Map ? match['userId'] as Map<String, dynamic> : <String, dynamic>{};
              data['assignedAgent'] = {
                'id': match['_id'] ?? match['id'],
                'agentCode': match['agentCode'] ?? 'AGENT',
                'name': userObj['name'] ?? match['name'] ?? 'Field Officer',
                'phone': userObj['phone'] ?? match['phone'] ?? branchObj?['phone'] ?? '',
                'email': userObj['email'] ?? match['email'] ?? '',
                'profileImage': match['profileImage'] ?? userObj['profileImage'] ?? '',
                'assignedRoutes': match['assignedRoutes'] ?? [],
              };
            }
          }
        }

        if (mounted) {
          setState(() {
            _portalData = data;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openChangePasswordSheet() {
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
          subtitle: 'Update your borrower app login password',
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
                  final oldP = oldPasswordCtrl.text.trim();
                  final newP = newPasswordCtrl.text.trim();
                  final confP = confirmPasswordCtrl.text.trim();

                  if (oldP.isEmpty || newP.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all required password fields')),
                    );
                    return;
                  }
                  if (newP.length < 4) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password must be at least 4 characters long')),
                    );
                    return;
                  }
                  if (newP != confP) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('New passwords do not match')),
                    );
                    return;
                  }

                  setSheetState(() => isSaving = true);
                  final res = await ApiClient().post(
                    ApiEndpoints.changePassword,
                    data: {
                      'oldPassword': oldP,
                      'newPassword': newP,
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

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(AppIcons.logOut, color: AppColors.danger, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Sign Out',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out from your borrower portal?',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<AuthCubit>().logout();
            },
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final user = authState is Authenticated ? authState.user : <String, dynamic>{};

    final customer = _portalData?['customer'] as Map<String, dynamic>? ?? {};
    final assignedAgent = _portalData?['assignedAgent'] as Map<String, dynamic>?;
    final branch = _portalData?['branch'] as Map<String, dynamic>?;
    final company = _portalData?['company'] as Map<String, dynamic>?;

    final customerName = customer['name']?.toString() ?? user['name']?.toString() ?? 'Borrower';
    final customerPhone = customer['phone']?.toString() ?? user['phone']?.toString() ?? '';
    final customerEmail = customer['email']?.toString() ?? user['email']?.toString() ?? '';
    final customerCode = customer['customerCode']?.toString() ?? 'BORROWER';
    final address = customer['address'] as Map<String, dynamic>? ?? {};
    final guarantor = customer['guarantor'] as Map<String, dynamic>? ?? {};
    final street = address['street']?.toString() ?? '';
    final city = address['city']?.toString() ?? '';
    final routeArea = address['routeArea']?.toString() ?? '';
    final guarantorName = guarantor['name']?.toString() ?? '';
    final guarantorPhone = guarantor['phone']?.toString() ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'My Profile & Support',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Profile Avatar Banner
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      AppAvatar(
                        radius: 30,
                        fallbackText: customerName,
                        fallbackIcon: AppIcons.user,
                        backgroundColor: AppColors.primarySoft,
                        foregroundColor: AppColors.primary,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customerName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              customerPhone,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Code: $customerCode',
                                style: const TextStyle(color: AppColors.primaryDark, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Borrower KYC & Address Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(AppIcons.idCard, size: 16, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text('KYC & Registered Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _item('Mobile Number', customerPhone),
                      if (customerEmail.isNotEmpty && !customerEmail.contains('@customer.mwt')) ...[
                        const Divider(color: AppColors.border, height: 16),
                        _item('Email', customerEmail),
                      ],
                      if (routeArea.isNotEmpty) ...[
                        const Divider(color: AppColors.border, height: 16),
                        _item('Assigned Route / Line', routeArea),
                      ],
                      if (street.isNotEmpty || city.isNotEmpty) ...[
                        const Divider(color: AppColors.border, height: 16),
                        _item('Address', '$street, $city'.trim()),
                      ],
                      if (guarantorName.isNotEmpty) ...[
                        const Divider(color: AppColors.border, height: 16),
                        _item('Guarantor', '$guarantorName ${guarantorPhone.isNotEmpty ? '($guarantorPhone)' : ''}'),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Servicing Agent & Branch
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(AppIcons.building, size: 16, color: AppColors.accentCyan),
                          SizedBox(width: 8),
                          Text('Servicing Branch & Agent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (assignedAgent != null) ...[
                        _item('Line Collector', '${assignedAgent['name']} (${assignedAgent['agentCode']})'),
                        if (assignedAgent['phone'] != null && assignedAgent['phone'].toString().isNotEmpty) ...[
                          const Divider(color: AppColors.border, height: 16),
                          _item('Agent Phone', assignedAgent['phone'].toString()),
                        ],
                        const Divider(color: AppColors.border, height: 16),
                      ] else if (branch != null) ...[
                        _item('Branch Officer', '${branch['name']} Collection Officer'),
                        const Divider(color: AppColors.border, height: 16),
                      ],
                      if (branch != null) ...[
                        _item('Branch Office', '${branch['name']} (${branch['branchCode']})'),
                        if (branch['phone'] != null) ...[
                          const Divider(color: AppColors.border, height: 16),
                          _item('Branch Phone', branch['phone'].toString()),
                        ],
                        const Divider(color: AppColors.border, height: 16),
                      ],
                      if (company != null)
                        _item('Finance Issuer', '${company['name']} (${company['companyCode']})'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Account Security Actions
                ListTile(
                  tileColor: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
                  leading: const Icon(AppIcons.lock, color: AppColors.primary, size: 20),
                  title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textPrimary)),
                  subtitle: const Text('Update your login credentials', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  trailing: const Icon(AppIcons.chevronRight, size: 16, color: AppColors.textMuted),
                  onTap: _openChangePasswordSheet,
                ),
                const SizedBox(height: 12),

                ListTile(
                  tileColor: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
                  leading: const Icon(AppIcons.logOut, color: AppColors.danger, size: 20),
                  title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.danger)),
                  subtitle: const Text('End your session on this device', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  onTap: _showLogoutConfirmation,
                ),
                const SizedBox(height: 30),
              ],
            ),
    );
  }

  Widget _item(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12.5),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
