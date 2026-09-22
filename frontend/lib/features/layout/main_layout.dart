import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/services/notification_service.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/server_config_dialog.dart';
import '../authentication/presentation/auth_cubit.dart';
import '../notifications/notification_center_screen.dart';

import 'branch_cubit.dart';

class MainLayout extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onIndexChanged;
  final Widget body;

  const MainLayout({
    super.key,
    required this.selectedIndex,
    required this.onIndexChanged,
    required this.body,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  String? _liveAgentPhoto;

  @override
  void initState() {
    super.initState();
    // Start live notification sync & register device push token
    NotificationService().startPeriodicSync();
    NotificationService().registerDeviceToken();
    _loadLiveAgentPhoto();
  }

  Future<void> _loadLiveAgentPhoto() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated && authState.role == 'AGENT') {
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

  void _openBranchSwitcher(BuildContext context) {
    String searchQuery = '';
    final branchCubit = context.read<BranchCubit>();
    final branchState = branchCubit.state;
    final companyBranches = branchState.branches;

    AppBottomSheet.show(
      context: context,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final currentActiveId = branchCubit.state.activeBranchId;

          final filteredBranches = companyBranches.where((b) {
            if (searchQuery.trim().isEmpty) return true;
            final name = (b['name']?.toString() ?? '').toLowerCase();
            final addr = b['address'] as Map<String, dynamic>? ?? {};
            final district = (addr['district']?.toString() ?? '').toLowerCase();
            final code = (b['branchCode']?.toString() ?? '').toLowerCase();
            final q = searchQuery.toLowerCase().trim();
            return name.contains(q) || district.contains(q) || code.contains(q);
          }).toList();

          return AppBottomSheet(
            title: 'Switch Active Branch',
            subtitle: 'Filter portfolio and collections by branch office',
            icon: AppIcons.building,
            iconColor: AppColors.accentCyan,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Search Input Field
                if (companyBranches.length > 3) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      onChanged: (val) => setSheetState(() => searchQuery = val),
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Search branch name, code or district...',
                        prefixIcon: Icon(AppIcons.search, size: 18, color: AppColors.textMuted),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                ],

                // All Branches Option Card
                InkWell(
                  onTap: () {
                    branchCubit.selectBranch(branchId: null, branchName: 'All Branches');
                    Navigator.pop(sheetCtx);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: currentActiveId == null
                          ? AppColors.primarySoft
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: currentActiveId == null
                            ? AppColors.primary.withValues(alpha: 0.4)
                            : AppColors.border,
                        width: currentActiveId == null ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: currentActiveId == null
                                ? AppColors.primaryGradient
                                : null,
                            color: currentActiveId == null
                                ? null
                                : AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            AppIcons.building2,
                            size: 18,
                            color: currentActiveId == null
                                ? Colors.white
                                : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'All Branches',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentIndigo.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Combined View',
                                      style: TextStyle(
                                        color: AppColors.accentIndigo,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Consolidated analytics across all operating districts',
                                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        if (currentActiveId == null)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(AppIcons.check, color: Colors.white, size: 12),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                const Divider(color: AppColors.border, height: 16),
                const SizedBox(height: 6),

                // Individual Branch Cards
                if (companyBranches.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(AppIcons.building, size: 32, color: AppColors.textMuted.withValues(alpha: 0.5)),
                        const SizedBox(height: 8),
                        const Text(
                          'No individual branch offices configured.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                else if (filteredBranches.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    child: const Text(
                      'No branches matching your search.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  )
                else
                  ...filteredBranches.map((b) {
                    final bId = b['_id']?.toString();
                    final name = b['name']?.toString() ?? 'Branch';
                    final code = b['branchCode']?.toString() ?? '';
                    final addr = b['address'] as Map<String, dynamic>? ?? {};
                    final district = addr['district']?.toString() ?? 'District';
                    final isSelected = currentActiveId == bId;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          branchCubit.selectBranch(
                            branchId: bId,
                            branchName: name,
                            code: code,
                            district: district,
                          );
                          Navigator.pop(sheetCtx);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primarySoft : AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.4)
                                  : AppColors.border,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withValues(alpha: 0.15)
                                      : AppColors.surfaceCard,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  AppIcons.building,
                                  size: 18,
                                  color: isSelected ? AppColors.primary : AppColors.accentCyan,
                                ),
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
                                            style: TextStyle(
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                              fontSize: 13,
                                              color: AppColors.textPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (code.isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceCard,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: AppColors.border),
                                            ),
                                            child: Text(
                                              code,
                                              style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textMuted),
                                        const SizedBox(width: 2),
                                        Text(
                                          district,
                                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(AppIcons.check, color: Colors.white, size: 12),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openChangePasswordModal(BuildContext context) {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool isSaving = false;
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    AppBottomSheet.show(
      context: context,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final newPassword = newPassCtrl.text;
          final hasMinLength = newPassword.length >= 6;
          final hasNumberOrSpecial = RegExp(r'[0-9!@#\$&*~]').hasMatch(newPassword);
          final hasUpperLower = RegExp(r'[A-Za-z]').hasMatch(newPassword);

          int strengthScore = 0;
          if (newPassword.isNotEmpty) {
            if (hasMinLength) strengthScore++;
            if (hasNumberOrSpecial) strengthScore++;
            if (hasUpperLower && newPassword.length >= 8) strengthScore++;
          }

          Color strengthColor = AppColors.danger;
          String strengthLabel = 'Weak';
          if (strengthScore == 2) {
            strengthColor = AppColors.warning;
            strengthLabel = 'Good';
          } else if (strengthScore >= 3) {
            strengthColor = AppColors.success;
            strengthLabel = 'Strong';
          }

          return AppBottomSheet(
            title: 'Change Password',
            subtitle: 'Update your security credentials',
            icon: AppIcons.lock,
            iconColor: AppColors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: oldPassCtrl,
                  obscureText: obscureOld,
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Current Password *',
                    prefixIcon: const Icon(AppIcons.lock, size: 18, color: AppColors.textMuted),
                    suffixIcon: IconButton(
                      icon: Icon(obscureOld ? AppIcons.eyeOff : AppIcons.eye, size: 18, color: AppColors.textMuted),
                      onPressed: () => setSheetState(() => obscureOld = !obscureOld),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: newPassCtrl,
                  obscureText: obscureNew,
                  onChanged: (_) => setSheetState(() {}),
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'New Password *',
                    hintText: 'At least 6 characters',
                    prefixIcon: const Icon(AppIcons.key, size: 18, color: AppColors.textMuted),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew ? AppIcons.eyeOff : AppIcons.eye, size: 18, color: AppColors.textMuted),
                      onPressed: () => setSheetState(() => obscureNew = !obscureNew),
                    ),
                  ),
                ),
                if (newPassword.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: strengthScore / 3.0,
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        strengthLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: strengthColor,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                TextField(
                  controller: confirmPassCtrl,
                  obscureText: obscureConfirm,
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password *',
                    prefixIcon: const Icon(AppIcons.key, size: 18, color: AppColors.textMuted),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm ? AppIcons.eyeOff : AppIcons.eye, size: 18, color: AppColors.textMuted),
                      onPressed: () => setSheetState(() => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                AppButton(
                  label: 'Update Password',
                  icon: AppIcons.checkCircle2,
                  isLoading: isSaving,
                  onPressed: () async {
                    final oldPass = oldPassCtrl.text.trim();
                    final newPass = newPassCtrl.text.trim();
                    final confirmPass = confirmPassCtrl.text.trim();

                    if (oldPass.isEmpty || newPass.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all required fields')),
                      );
                      return;
                    }
                    if (newPass.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('New password must be at least 6 characters long')),
                      );
                      return;
                    }
                    if (newPass != confirmPass) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Passwords do not match')),
                      );
                      return;
                    }

                    setSheetState(() => isSaving = true);
                    final res = await ApiClient().post(
                      ApiEndpoints.changePassword,
                      data: {
                        'oldPassword': oldPass,
                        'newPassword': newPass,
                      },
                    );
                    setSheetState(() => isSaving = false);

                    if (res.success) {
                      if (context.mounted) Navigator.pop(sheetCtx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password updated successfully!'),
                            backgroundColor: AppColors.success,
                          ),
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
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;

    String role = 'COMPANY_ADMIN';
    String userName = 'Admin';
    String companyName = 'Finance SaaS';
    String userEmail = '';
    String? companyLogo;
    String? userPhoto;

    if (authState is Authenticated) {
      role = authState.role;
      userName = authState.user['name']?.toString() ?? 'User';
      userEmail = authState.user['email']?.toString() ?? '';
      companyName = authState.companyName ?? 'Finance SaaS';
      companyLogo = authState.companyLogo;
      userPhoto = _liveAgentPhoto ?? authState.user['profileImage']?.toString();
    } else {
      userPhoto = _liveAgentPhoto;
    }

    final mobileNavTabs = _getMobileNavTabs(role);
    final activeIndex = widget.selectedIndex < mobileNavTabs.length ? widget.selectedIndex : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(66),
        child: _buildTopAppBar(context, userName, userEmail, role, companyName, companyLogo, userPhoto),
      ),
      body: SafeArea(
        child: widget.body,
      ),
      bottomNavigationBar: _buildModernBottomNav(mobileNavTabs, activeIndex),
    );
  }

  Widget _buildTopAppBar(
    BuildContext context,
    String userName,
    String userEmail,
    String role,
    String companyName,
    String? companyLogo,
    String? userPhoto,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.85),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            children: [
              // Left Group: Brand Capsule & Branch Selector in Expanded Row
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Company Brand Capsule
                    Flexible(
                      fit: FlexFit.loose,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primarySoft,
                              AppColors.primarySoft.withValues(alpha: 0.6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: AppAvatar(
                                imageSource: companyLogo,
                                radius: 10,
                                fallbackIcon: AppIcons.building2,
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                companyName,
                                style: const TextStyle(
                                  color: AppColors.primaryDark,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.success.withValues(alpha: 0.4),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Interactive Branch Selector Pill (For Multi-District Company Admin & Manager)
                    if (role == 'COMPANY_ADMIN' || role == 'MANAGER') ...[
                      const SizedBox(width: 6),
                      Flexible(
                        fit: FlexFit.loose,
                        child: InkWell(
                          onTap: () => _openBranchSwitcher(context),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceCard,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(AppIcons.mapPin, size: 11, color: AppColors.accentCyan),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    context.watch<BranchCubit>().state.activeBranchName,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 13, color: AppColors.textMuted),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ] else if (role == 'AGENT') ...[
                      const SizedBox(width: 6),
                      Flexible(
                        fit: FlexFit.loose,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.accentCyan.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(AppIcons.mapPin, size: 11, color: AppColors.accentCyan),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  context.watch<BranchCubit>().state.activeBranchName,
                                  style: const TextStyle(
                                    color: AppColors.accentCyan,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else if (role == 'CUSTOMER') ...[
                      const SizedBox(width: 6),
                      Flexible(
                        fit: FlexFit.loose,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(AppIcons.userCheck, size: 11, color: AppColors.primary),
                              SizedBox(width: 3),
                              Text(
                                'Borrower Portal',
                                style: TextStyle(
                                  color: AppColors.primaryDark,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),

              // Right Group: Notification Bell & Profile Avatar
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Notification Bell with Animated Glow Badge
                  ValueListenableBuilder<int>(
                    valueListenable: NotificationService().unreadCountNotifier,
                    builder: (context, unreadCount, _) {
                      final hasUnread = unreadCount > 0;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: hasUnread
                                  ? AppColors.primarySoft
                                  : AppColors.surfaceCard,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: hasUnread
                                    ? AppColors.primary.withValues(alpha: 0.3)
                                    : AppColors.border,
                              ),
                            ),
                            child: IconButton(
                              icon: Icon(
                                AppIcons.bell,
                                size: 17,
                                color: hasUnread ? AppColors.primary : AppColors.textSecondary,
                              ),
                              tooltip: 'Notification Center',
                              padding: const EdgeInsets.all(6),
                              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
                                );
                              },
                            ),
                          ),
                          if (hasUnread)
                            Positioned(
                              right: -1,
                              top: -1,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.surface, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.danger.withValues(alpha: 0.4),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                                child: Text(
                                  unreadCount > 99 ? '99+' : '$unreadCount',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(width: 8),

                  // Profile Avatar & Menu Trigger
                  PopupMenuButton<String>(
                    color: AppColors.surface,
                    elevation: 12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: AppColors.border, width: 1),
                    ),
                    offset: const Offset(0, 46),
                    onSelected: (val) {
                      if (val == 'server_ip') {
                        ServerConfigDialog.show(context);
                      } else if (val == 'change_password') {
                        _openChangePasswordModal(context);
                      } else if (val == 'notifications') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
                        );
                      } else if (val == 'logout') {
                        _showLogoutConfirmation(context);
                      }
                    },
                    itemBuilder: (ctx) => [
                      // User Summary Card Header
                      PopupMenuItem<String>(
                        enabled: false,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(1.5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
                                ),
                                child: AppAvatar(
                                  imageSource: userPhoto,
                                  radius: 18,
                                  fallbackText: userName,
                                  fallbackIcon: role == 'AGENT' ? AppIcons.userCheck : AppIcons.users,
                                  backgroundColor: AppColors.primarySoft,
                                  foregroundColor: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userName,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primarySoft,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        role.replaceAll('_', ' '),
                                        style: const TextStyle(
                                          color: AppColors.primaryDark,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const PopupMenuItem<String>(
                        height: 1,
                        enabled: false,
                        child: Divider(color: AppColors.border, height: 1),
                      ),
                      PopupMenuItem<String>(
                        value: 'notifications',
                        child: _buildMenuItemRow(AppIcons.bell, 'Notification Center', AppColors.primary),
                      ),
                      PopupMenuItem<String>(
                        value: 'change_password',
                        child: _buildMenuItemRow(AppIcons.key, 'Change Password', AppColors.accentIndigo),
                      ),
                      PopupMenuItem<String>(
                        value: 'server_ip',
                        child: _buildMenuItemRow(AppIcons.server, 'Server Connection', AppColors.accentCyan),
                      ),
                      const PopupMenuItem<String>(
                        height: 1,
                        enabled: false,
                        child: Divider(color: AppColors.border, height: 1),
                      ),
                      PopupMenuItem<String>(
                        value: 'logout',
                        child: _buildMenuItemRow(AppIcons.logOut, 'Sign Out', AppColors.danger, isDanger: true),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: AppAvatar(
                        imageSource: userPhoto,
                        radius: 15,
                        fallbackText: userName,
                        fallbackIcon: role == 'AGENT' ? AppIcons.userCheck : AppIcons.users,
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItemRow(IconData icon, String title, Color iconColor, {bool isDanger = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: iconColor),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: isDanger ? AppColors.danger : AppColors.textPrimary,
            fontSize: 13,
            fontWeight: isDanger ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
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
          'Are you sure you want to end your current session?',
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
              NotificationService().unregisterDeviceToken();
              context.read<AuthCubit>().logout();
            },
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildModernBottomNav(List<_NavTab> tabs, int activeIndex) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(tabs.length, (index) {
              final tab = tabs[index];
              final isSelected = index == activeIndex;

              return Expanded(
                child: InkWell(
                  onTap: () => widget.onIndexChanged(index),
                  borderRadius: BorderRadius.circular(20),
                  splashColor: AppColors.primary.withValues(alpha: 0.1),
                  highlightColor: Colors.transparent,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primarySoft
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected
                          ? Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 1)
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedScale(
                          scale: isSelected ? 1.10 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            tab.icon,
                            size: 21,
                            color: isSelected ? AppColors.primary : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 3),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                            color: isSelected ? AppColors.primaryDark : AppColors.textMuted,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                          child: Text(
                            tab.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Micro Active Glow Dot / Pill Indicator
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isSelected ? 14 : 0,
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  List<_NavTab> _getMobileNavTabs(String role) {
    if (role == 'SUPER_ADMIN') {
      return const [
        _NavTab(label: 'Console', icon: AppIcons.layoutDashboard),
        _NavTab(label: 'Companies', icon: AppIcons.building2),
        _NavTab(label: 'Plans', icon: AppIcons.badgeCheck),
        _NavTab(label: 'More', icon: AppIcons.grid),
      ];
    } else if (role == 'AGENT') {
      return const [
        _NavTab(label: 'Collect', icon: AppIcons.zap),
        _NavTab(label: 'Borrowers', icon: AppIcons.users),
        _NavTab(label: 'History', icon: AppIcons.receipt),
        _NavTab(label: 'More', icon: AppIcons.grid),
      ];
    } else if (role == 'CUSTOMER') {
      return const [
        _NavTab(label: 'Home', icon: AppIcons.layoutDashboard),
        _NavTab(label: 'My Loans', icon: AppIcons.wallet),
        _NavTab(label: 'Payments', icon: AppIcons.receipt),
        _NavTab(label: 'Profile', icon: AppIcons.user),
      ];
    } else {
      // Company Admin & Managers
      return const [
        _NavTab(label: 'Home', icon: AppIcons.layoutDashboard),
        _NavTab(label: 'Collect', icon: AppIcons.zap),
        _NavTab(label: 'Borrowers', icon: AppIcons.users),
        _NavTab(label: 'Loans', icon: AppIcons.wallet),
        _NavTab(label: 'More', icon: AppIcons.grid),
      ];
    }
  }
}

class _NavTab {
  final String label;
  final IconData icon;
  const _NavTab({required this.label, required this.icon});
}
