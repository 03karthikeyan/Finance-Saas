import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_widgets.dart';
import '../layout/branch_cubit.dart';
import 'agent_route_map_screen.dart';
import 'agent_salary_screen.dart';

class AgentListScreen extends StatefulWidget {
  const AgentListScreen({super.key});

  @override
  State<AgentListScreen> createState() => _AgentListScreenState();
}

class _AgentListScreenState extends State<AgentListScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  String _search = '';
  String? _lastLoadedBranchId = 'INIT';
  List<dynamic> _agents = [];

  @override
  void initState() {
    super.initState();
    _fetchAgents();
  }

  Future<void> _fetchAgents([String? branchIdOverride]) async {
    setState(() => _isLoading = true);
    final branchId = branchIdOverride ??
        (mounted ? context.read<BranchCubit>().state.activeBranchId : null);
    _lastLoadedBranchId = branchId;

    try {
      final res = await _apiClient.get(
        ApiEndpoints.agents,
        queryParameters: {
          if (_search.isNotEmpty) 'search': _search,
          if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
        },
      );
      if (res.success && res.data is List) {
        if (mounted) {
          setState(() {
            _agents = res.data as List<dynamic>;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openAddAgentBottomSheet() {
    final branchState = context.read<BranchCubit>().state;
    final branches = branchState.branches;
    String? selectedBranchId = branchState.activeBranchId ?? (branches.isNotEmpty ? branches.first['_id']?.toString() : null);

    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController(text: 'Agent@2026!');
    final targetCtrl = TextEditingController(text: '25000');
    final salaryCtrl = TextEditingController(text: '15000');
    final routesCtrl = TextEditingController(text: 'Line 1 - Market Bazaar');
    final proofNumberCtrl = TextEditingController();
    final emgNameCtrl = TextEditingController();
    final emgPhoneCtrl = TextEditingController();

    String selectedProofType = 'Aadhaar Card';
    String selectedEmgRelation = 'Spouse';
    String? profilePhotoBase64;
    bool isSaving = false;

    final proofTypes = [
      'Aadhaar Card',
      'PAN Card',
      'Driving License',
      'Voter ID',
      'Staff ID',
      'Passport',
      'Other',
    ];

    final relations = [
      'Spouse',
      'Parent',
      'Sibling',
      'Child',
      'Friend',
      'Relative',
      'Other',
    ];

    AppBottomSheet.show(
      context: context,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) => AppBottomSheet(
          title: 'Onboard Field Collection Officer',
          subtitle: 'Branch allocation, photo KYC & line assignments',
          icon: AppIcons.userCheck,
          iconColor: AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo Avatar Picker
              Center(
                child: Column(
                  children: [
                    AppAvatar(
                      imageSource: profilePhotoBase64,
                      radius: 36,
                      fallbackText: nameCtrl.text.isNotEmpty ? nameCtrl.text : 'Agent',
                      fallbackIcon: AppIcons.userPlus,
                      isEditable: true,
                      onTap: () async {
                        final picked = await AppImagePicker.showImageSourceDialog(
                          context,
                          title: 'Upload Officer Photo',
                          allowRemove: profilePhotoBase64 != null && profilePhotoBase64!.isNotEmpty,
                        );
                        if (picked != null) {
                          setSheetState(() => profilePhotoBase64 = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      profilePhotoBase64 != null && profilePhotoBase64!.isNotEmpty ? 'Tap photo to change or remove' : 'Tap to upload officer photo',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Branch Allocation Dropdown
              if (branches.isNotEmpty) ...[
                const Text('Branch Allocation *', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButton<String>(
                    value: selectedBranchId,
                    isExpanded: true,
                    dropdownColor: AppColors.surfaceElevated,
                    underline: const SizedBox(),
                    items: branches.map((b) {
                      final bId = b['_id']?.toString() ?? '';
                      final name = b['name']?.toString() ?? 'Branch';
                      final code = b['branchCode']?.toString() ?? '';
                      return DropdownMenuItem<String>(
                        value: bId,
                        child: Text('$name ($code)', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) => setSheetState(() => selectedBranchId = val),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Name & Photo
              TextField(
                controller: nameCtrl,
                onChanged: (_) => setSheetState(() {}),
                decoration: const InputDecoration(labelText: 'Agent Full Name *', hintText: 'e.g. Rajesh Kumar'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email *', hintText: 'agent@company.com'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone *', hintText: '9876500000'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // KYC Identification Proof
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
                        Icon(AppIcons.badgeCheck, size: 16, color: AppColors.accentCyan),
                        SizedBox(width: 6),
                        Text('Officer Identity KYC Proof', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButton<String>(
                              value: selectedProofType,
                              isExpanded: true,
                              dropdownColor: AppColors.surfaceElevated,
                              underline: const SizedBox(),
                              items: proofTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12)))).toList(),
                              onChanged: (val) {
                                if (val != null) setSheetState(() => selectedProofType = val);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 6,
                          child: TextField(
                            controller: proofNumberCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Proof Number',
                              hintText: 'e.g. ABCDE1234F',
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Emergency Contact Section
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
                        Icon(AppIcons.shield, size: 16, color: AppColors.warning),
                        SizedBox(width: 6),
                        Text('Emergency Contact', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: emgNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Contact Name',
                              hintText: 'Family Member',
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: emgPhoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Contact Phone',
                              hintText: '9876500000',
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButton<String>(
                        value: selectedEmgRelation,
                        isExpanded: true,
                        dropdownColor: AppColors.surfaceElevated,
                        underline: const SizedBox(),
                        items: relations.map((r) => DropdownMenuItem(value: r, child: Text('Relation: $r', style: const TextStyle(fontSize: 12)))).toList(),
                        onChanged: (val) {
                          if (val != null) setSheetState(() => selectedEmgRelation = val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Target & Monthly Salary
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: targetCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Daily Target (₹) *'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: salaryCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Monthly Salary (₹) *'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordCtrl,
                decoration: const InputDecoration(labelText: 'Login Password *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: routesCtrl,
                decoration: const InputDecoration(labelText: 'Assigned Routes / Lines', hintText: 'Line 1, Line 2'),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Create Agent Account',
                icon: AppIcons.check,
                isLoading: isSaving,
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) return;

                  final routes = routesCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                  setSheetState(() => isSaving = true);
                  final res = await _apiClient.post(
                    ApiEndpoints.agents,
                    data: {
                      'name': nameCtrl.text.trim(),
                      'email': emailCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'password': passwordCtrl.text.trim(),
                      'branchId': selectedBranchId,
                      'proofType': selectedProofType,
                      'proofNumber': proofNumberCtrl.text.trim(),
                      'emergencyContact': {
                        'name': emgNameCtrl.text.trim(),
                        'phone': emgPhoneCtrl.text.trim(),
                        'relation': selectedEmgRelation,
                      },
                      'dailyTarget': double.tryParse(targetCtrl.text.trim()) ?? 0,
                      'monthlySalary': double.tryParse(salaryCtrl.text.trim()) ?? 0,
                      'assignedRoutes': routes,
                      if (profilePhotoBase64 != null && profilePhotoBase64!.isNotEmpty) 'profileImage': profilePhotoBase64,
                    },
                  );
                  setSheetState(() => isSaving = false);

                  if (res.success) {
                    if (context.mounted) Navigator.pop(sheetCtx);
                    _fetchAgents();
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

  void _openEditAgentBottomSheet(Map<String, dynamic> agent) {
    final branchState = context.read<BranchCubit>().state;
    final branches = branchState.branches;
    String? selectedBranchId = agent['branchId'] is Map
        ? agent['branchId']['_id']?.toString()
        : agent['branchId']?.toString();

    final agentId = agent['_id']?.toString() ?? '';
    final user = agent['userId'] as Map<String, dynamic>? ?? {};
    final nameCtrl = TextEditingController(text: user['name']?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: user['phone']?.toString() ?? '');
    final targetCtrl = TextEditingController(text: (agent['dailyTarget'] ?? 0).toString());
    final salaryCtrl = TextEditingController(text: (agent['monthlySalary'] ?? 0).toString());
    final routes = agent['assignedRoutes'] as List<dynamic>? ?? [];
    final routesCtrl = TextEditingController(text: routes.join(', '));
    final passwordCtrl = TextEditingController();
    final proofNumberCtrl = TextEditingController(text: agent['proofNumber']?.toString() ?? '');
    final emg = agent['emergencyContact'] as Map<String, dynamic>? ?? {};
    final emgNameCtrl = TextEditingController(text: emg['name']?.toString() ?? '');
    final emgPhoneCtrl = TextEditingController(text: emg['phone']?.toString() ?? '');

    String selectedProofType = agent['proofType']?.toString() ?? 'Aadhaar Card';
    String selectedEmgRelation = emg['relation']?.toString() ?? 'Spouse';
    String? profilePhotoBase64 = user['profileImage']?.toString() ?? agent['profileImage']?.toString();
    String status = agent['status']?.toString() ?? 'ACTIVE';
    bool isSaving = false;

    final proofTypes = [
      'Aadhaar Card',
      'PAN Card',
      'Driving License',
      'Voter ID',
      'Staff ID',
      'Passport',
      'Other',
    ];

    final relations = [
      'Spouse',
      'Parent',
      'Sibling',
      'Child',
      'Friend',
      'Relative',
      'Other',
    ];

    if (!proofTypes.contains(selectedProofType)) {
      proofTypes.insert(0, selectedProofType);
    }
    if (!relations.contains(selectedEmgRelation)) {
      relations.insert(0, selectedEmgRelation);
    }

    AppBottomSheet.show(
      context: context,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) => AppBottomSheet(
          title: 'Edit Officer Profile',
          subtitle: 'Update photo, targets, branch & KYC for ${nameCtrl.text}',
          icon: AppIcons.edit,
          iconColor: AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo Avatar Picker
              Center(
                child: Column(
                  children: [
                    AppAvatar(
                      imageSource: profilePhotoBase64,
                      radius: 36,
                      fallbackText: nameCtrl.text.isNotEmpty ? nameCtrl.text : 'Agent',
                      fallbackIcon: AppIcons.userCheck,
                      isEditable: true,
                      onTap: () async {
                        final picked = await AppImagePicker.showImageSourceDialog(
                          context,
                          title: 'Update Officer Photo',
                          allowRemove: profilePhotoBase64 != null && profilePhotoBase64!.isNotEmpty,
                        );
                        if (picked != null) {
                          setSheetState(() => profilePhotoBase64 = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      profilePhotoBase64 != null && profilePhotoBase64!.isNotEmpty ? 'Tap photo to change or remove' : 'Tap to upload officer photo',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Branch Allocation Dropdown
              if (branches.isNotEmpty) ...[
                const Text('Branch Allocation *', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButton<String>(
                    value: selectedBranchId,
                    isExpanded: true,
                    dropdownColor: AppColors.surfaceElevated,
                    underline: const SizedBox(),
                    items: branches.map((b) {
                      final bId = b['_id']?.toString() ?? '';
                      final name = b['name']?.toString() ?? 'Branch';
                      final code = b['branchCode']?.toString() ?? '';
                      return DropdownMenuItem<String>(
                        value: bId,
                        child: Text('$name ($code)', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) => setSheetState(() => selectedBranchId = val),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Agent Full Name *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number *'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: targetCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Daily Target (₹) *'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: salaryCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Monthly Salary (₹) *'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Officer KYC Section
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
                        Icon(AppIcons.badgeCheck, size: 16, color: AppColors.accentCyan),
                        SizedBox(width: 6),
                        Text('Officer Identity KYC Proof', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButton<String>(
                              value: selectedProofType,
                              isExpanded: true,
                              dropdownColor: AppColors.surfaceElevated,
                              underline: const SizedBox(),
                              items: proofTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12)))).toList(),
                              onChanged: (val) {
                                if (val != null) setSheetState(() => selectedProofType = val);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 6,
                          child: TextField(
                            controller: proofNumberCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Proof Number',
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Emergency Contact Section
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
                        Icon(AppIcons.shield, size: 16, color: AppColors.warning),
                        SizedBox(width: 6),
                        Text('Emergency Contact', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: emgNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Contact Name',
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: emgPhoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Contact Phone',
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButton<String>(
                        value: selectedEmgRelation,
                        isExpanded: true,
                        dropdownColor: AppColors.surfaceElevated,
                        underline: const SizedBox(),
                        items: relations
                            .map((r) => DropdownMenuItem(
                                  value: r,
                                  child: Text('Relation: $r', style: const TextStyle(fontSize: 12)),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setSheetState(() => selectedEmgRelation = val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: routesCtrl,
                decoration: const InputDecoration(labelText: 'Assigned Routes (comma separated)', hintText: 'Line 1, Line 2'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordCtrl,
                decoration: const InputDecoration(labelText: 'Reset Password (Optional)', hintText: 'Leave empty to keep current'),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButton<String>(
                  value: status,
                  isExpanded: true,
                  dropdownColor: AppColors.surfaceElevated,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE (Can Collect)')),
                    DropdownMenuItem(value: 'INACTIVE', child: Text('INACTIVE (Suspended)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setSheetState(() => status = val);
                  },
                ),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Save Officer Updates',
                icon: AppIcons.check,
                isLoading: isSaving,
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;

                  final routeList = routesCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                  setSheetState(() => isSaving = true);
                  final res = await _apiClient.put(
                    '${ApiEndpoints.agents}/$agentId',
                    data: {
                      'name': nameCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      if (selectedBranchId != null) 'branchId': selectedBranchId,
                      'proofType': selectedProofType,
                      'proofNumber': proofNumberCtrl.text.trim(),
                      'emergencyContact': {
                        'name': emgNameCtrl.text.trim(),
                        'phone': emgPhoneCtrl.text.trim(),
                        'relation': selectedEmgRelation,
                      },
                      'dailyTarget': double.tryParse(targetCtrl.text.trim()) ?? 0,
                      'monthlySalary': double.tryParse(salaryCtrl.text.trim()) ?? 0,
                      'assignedRoutes': routeList,
                      'status': status,
                      if (passwordCtrl.text.trim().isNotEmpty) 'password': passwordCtrl.text.trim(),
                      if (profilePhotoBase64 != null) 'profileImage': profilePhotoBase64,
                    },
                  );
                  setSheetState(() => isSaving = false);

                  if (res.success) {
                    if (context.mounted) Navigator.pop(sheetCtx);
                    _fetchAgents();
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

  void _confirmDeleteAgent(Map<String, dynamic> agent) {
    final agentId = agent['_id']?.toString() ?? '';
    final user = agent['userId'] as Map<String, dynamic>? ?? {};
    final name = user['name']?.toString() ?? 'Officer';

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(AppIcons.trash, color: AppColors.danger, size: 20),
            const SizedBox(width: 8),
            const Text('Delete Officer?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ],
        ),
        content: Text('Are you sure you want to delete collection officer "$name"?', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final res = await _apiClient.delete('${ApiEndpoints.agents}/$agentId');
              if (res.success) {
                _fetchAgents();
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res.message), backgroundColor: AppColors.danger),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPerformanceModal(BuildContext context, Map<String, dynamic> agent) {
    final agentId = agent['_id']?.toString() ?? '';
    final user = agent['userId'] as Map<String, dynamic>? ?? {};
    final name = user['name']?.toString() ?? 'Agent';

    AppBottomSheet.show(
      context: context,
      builder: (sheetCtx) => FutureBuilder<dynamic>(
        future: _apiClient.get(ApiEndpoints.agentPerformance(agentId)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 200,
              child: Center(child: AppLoading(message: 'Loading live performance...')),
            );
          }

          final res = snapshot.data;
          final data = (res != null && res.success && res.data is Map<String, dynamic>)
              ? res.data as Map<String, dynamic>
              : <String, dynamic>{};

          final perf = data['performance'] as Map<String, dynamic>? ?? {};
          final target = (perf['dailyTarget'] as num?)?.toDouble() ?? 0.0;
          final collectedToday = (perf['collectedToday'] as num?)?.toDouble() ?? 0.0;
          final completion = (perf['targetCompletionPercentage'] as num?)?.toDouble() ?? 0.0;
          final activeBorrowers = perf['assignedCustomersCount'] ?? 0;
          final monthlySalary = (perf['monthlySalary'] as num?)?.toDouble() ?? (agent['monthlySalary'] as num?)?.toDouble() ?? 0.0;

          return AppBottomSheet(
            title: '$name — Performance',
            subtitle: 'Real-time collection efficiency & target completion',
            icon: AppIcons.barChart3,
            iconColor: AppColors.accentIndigo,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Completion Progress Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Today\'s Target Progress', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('${completion.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (completion / 100).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentEmerald),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Target: ${CurrencyFormatter.format(target)}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          Text('Collected: ${CurrencyFormatter.format(collectedToday)}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Metrics Grid
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Active Borrowers', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text('$activeBorrowers Accounts', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
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
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Monthly Base Salary', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text(CurrencyFormatter.format(monthlySalary), style: const TextStyle(color: AppColors.accentEmerald, fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Quick Navigation Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(AppIcons.mapPin, size: 16, color: AppColors.accentIndigo),
                        label: const Text('Route Map', style: TextStyle(color: AppColors.accentIndigo, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.accentIndigo),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AgentRouteMapScreen(agentId: agentId, agentName: name),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(AppIcons.wallet, size: 16, color: Colors.white),
                        label: const Text('Salary Ledger', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AgentSalaryScreen(agentId: agentId, agentName: name),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
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
    final branchState = context.watch<BranchCubit>().state;
    final currentBranchId = branchState.activeBranchId;

    if (_lastLoadedBranchId != 'INIT' && _lastLoadedBranchId != currentBranchId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fetchAgents(currentBranchId);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => _fetchAgents(currentBranchId),
        color: AppColors.primary,
        child: Column(
          children: [
            // Top Controls
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                children: [
                  if (!branchState.isAllBranches) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.accentCyan.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(AppIcons.building, size: 13, color: AppColors.accentCyan),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Officers Branch: ${branchState.activeBranchName}',
                              style: const TextStyle(color: AppColors.accentCyan, fontSize: 11, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search agent name, code, phone...',
                            prefixIcon: const Icon(AppIcons.search, size: 18, color: AppColors.textMuted),
                            suffixIcon: _search.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(AppIcons.x, size: 16, color: AppColors.textMuted),
                                    onPressed: () {
                                      setState(() => _search = '');
                                      _fetchAgents(currentBranchId);
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          onChanged: (val) {
                            _search = val;
                            _fetchAgents(currentBranchId);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _openAddAgentBottomSheet,
                        icon: const Icon(AppIcons.userPlus, size: 16, color: Colors.white),
                        label: const Text('Add Officer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Agents List
            Expanded(
              child: _isLoading
                  ? const AppLoading(message: 'Loading collection officers...')
                  : _agents.isEmpty
                      ? const AppEmptyState(
                          title: 'No Agents Registered',
                          subtitle: 'Tap "+ Add Officer" above to onboard your first field officer.',
                          icon: AppIcons.users,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: _agents.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final agent = _agents[index];
                            final code = agent['agentCode'] ?? '';
                            final user = agent['userId'] as Map<String, dynamic>?;
                            final name = user?['name'] ?? 'Agent';
                            final email = user?['email'] ?? '';
                            final phone = user?['phone'] ?? '';
                            final photo = user?['profileImage']?.toString() ?? agent['profileImage']?.toString();
                            final branchObj = agent['branchId'] as Map<String, dynamic>?;
                            final branchName = branchObj?['name']?.toString();
                            final proofType = agent['proofType']?.toString();
                            final proofNumber = agent['proofNumber']?.toString();
                            final emgContact = agent['emergencyContact'] as Map<String, dynamic>?;
                            final target = (agent['dailyTarget'] as num?)?.toDouble() ?? 0.0;
                            final monthlySalary = (agent['monthlySalary'] as num?)?.toDouble() ?? 0.0;
                            final collected = (agent['totalCollected'] as num?)?.toDouble() ?? 0.0;
                            final routes = agent['assignedRoutes'] as List<dynamic>? ?? [];
                            final status = agent['status']?.toString() ?? 'ACTIVE';

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
                                        imageSource: photo,
                                        radius: 20,
                                        fallbackText: name,
                                        fallbackIcon: AppIcons.userCheck,
                                        backgroundColor: AppColors.info.withValues(alpha: 0.15),
                                        foregroundColor: AppColors.info,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(4)),
                                                  child: Text(code, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text('$phone • $email', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                      StatusBadge(status: status, isSmall: true),
                                    ],
                                  ),

                                  // Branch & KYC Row
                                  if (branchName != null || (proofNumber != null && proofNumber.isNotEmpty)) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        if (branchName != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.accentCyan.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(AppIcons.building, size: 10, color: AppColors.accentCyan),
                                                const SizedBox(width: 3),
                                                Text(branchName, style: const TextStyle(color: AppColors.accentCyan, fontSize: 9.5, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                        if (proofNumber != null && proofNumber.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceCard,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: AppColors.border),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(AppIcons.badgeCheck, size: 10, color: AppColors.primary),
                                                const SizedBox(width: 3),
                                                Text('${proofType ?? "KYC"}: $proofNumber', style: const TextStyle(color: AppColors.textSecondary, fontSize: 9.5)),
                                              ],
                                            ),
                                          ),
                                        if (emgContact != null && (emgContact['phone']?.toString().isNotEmpty ?? false))
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.warning.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(AppIcons.shield, size: 10, color: AppColors.warning),
                                                const SizedBox(width: 3),
                                                Text(
                                                  'Emg: ${emgContact['name'] ?? ''}${emgContact['relation'] != null && emgContact['relation'].toString().isNotEmpty ? " (${emgContact['relation']})" : ""} • ${emgContact['phone']}',
                                                  style: const TextStyle(color: AppColors.warning, fontSize: 9.5),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 10),

                                  // Financial Stats Box (3 Columns)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceCard,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Daily Target', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                                            Text(CurrencyFormatter.format(target), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12.5)),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            const Text('Monthly Salary', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                                            Text(CurrencyFormatter.format(monthlySalary), style: const TextStyle(color: AppColors.accentEmerald, fontWeight: FontWeight.bold, fontSize: 12.5)),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            const Text('Lifetime Collected', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                                            Text(CurrencyFormatter.format(collected), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12.5)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (routes.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Lines: ${routes.join(", ")}',
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  const Divider(color: AppColors.border),
                                  Row(
                                    children: [
                                      // Quick Route Map Button
                                      InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => AgentRouteMapScreen(
                                                agentId: agent['_id']?.toString(),
                                                agentName: name,
                                              ),
                                            ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppColors.accentIndigo.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: AppColors.accentIndigo.withValues(alpha: 0.3)),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(AppIcons.mapPin, size: 12, color: AppColors.accentIndigo),
                                              SizedBox(width: 4),
                                              Text('Route Map', style: TextStyle(color: AppColors.accentIndigo, fontSize: 11, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      // Quick Salary Ledger Button
                                      InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => AgentSalaryScreen(
                                                agentId: agent['_id']?.toString(),
                                                agentName: name,
                                              ),
                                            ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppColors.accentEmerald.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: AppColors.accentEmerald.withValues(alpha: 0.3)),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(AppIcons.wallet, size: 12, color: AppColors.accentEmerald),
                                              SizedBox(width: 4),
                                              Text('Salary', style: TextStyle(color: AppColors.accentEmerald, fontSize: 11, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      // Performance Modal Button
                                      IconButton(
                                        icon: const Icon(AppIcons.barChart3, size: 16, color: AppColors.accentIndigo),
                                        tooltip: 'Performance Report',
                                        onPressed: () => _showPerformanceModal(context, agent),
                                        style: IconButton.styleFrom(
                                          backgroundColor: AppColors.surfaceCard,
                                          padding: const EdgeInsets.all(6),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(AppIcons.edit, size: 16, color: AppColors.primary),
                                        tooltip: 'Edit Officer',
                                        onPressed: () => _openEditAgentBottomSheet(agent),
                                        style: IconButton.styleFrom(
                                          backgroundColor: AppColors.surfaceCard,
                                          padding: const EdgeInsets.all(6),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(AppIcons.trash, size: 16, color: AppColors.danger),
                                        tooltip: 'Delete Officer',
                                        onPressed: () => _confirmDeleteAgent(agent),
                                        style: IconButton.styleFrom(
                                          backgroundColor: AppColors.surfaceCard,
                                          padding: const EdgeInsets.all(6),
                                        ),
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
}
