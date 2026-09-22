import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../layout/branch_cubit.dart';

class BranchManagementScreen extends StatefulWidget {
  const BranchManagementScreen({super.key});

  @override
  State<BranchManagementScreen> createState() => _BranchManagementScreenState();
}

class _BranchManagementScreenState extends State<BranchManagementScreen> {
  final ApiClient _apiClient = ApiClient();
  List<dynamic> _branches = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedDistrictFilter = 'ALL';

  final List<String> _districts = [
    'Chennai',
    'Coimbatore',
    'Cuddalore',
    'Dharmapuri',
    'Dindigul',
    'Erode',
    'Kallakurichi',
    'Kanchipuram',
    'Kanyakumari',
    'Karur',
    'Krishnagiri',
    'Madurai',
    'Mayiladuthurai',
    'Nagapattinam',
    'Namakkal',
    'Nilgiris',
    'Perambalur',
    'Pudukkottai',
    'Ramanathapuram',
    'Ranipet',
    'Salem',
    'Sivaganga',
    'Tenkasi',
    'Thanjavur',
    'Theni',
    'Thoothukudi',
    'Tiruchirappalli',
    'Tirunelveli',
    'Tirupathur',
    'Tiruppur',
    'Tiruvallur',
    'Tiruvannamalai',
    'Tiruvarur',
    'Vellore',
    'Viluppuram',
    'Virudhunagar',
    'Other District'
  ];

  @override
  void initState() {
    super.initState();
    _fetchBranches();
  }

  Future<void> _fetchBranches() async {
    setState(() => _isLoading = true);
    final res = await _apiClient.get(ApiEndpoints.branches);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res.success && res.data is List) {
          _branches = res.data as List<dynamic>;
        }
      });
      // Also refresh the global branch list in layout cubit
      context.read<BranchCubit>().loadBranches();
    }
  }

  void _openBranchModal({Map<String, dynamic>? existingBranch}) {
    final isEditing = existingBranch != null;
    final branchId = existingBranch?['_id']?.toString() ?? '';
    final nameCtrl = TextEditingController(text: existingBranch?['name']?.toString() ?? '');
    final codeCtrl = TextEditingController(text: existingBranch?['branchCode']?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: existingBranch?['phone']?.toString() ?? '');
    final emailCtrl = TextEditingController(text: existingBranch?['email']?.toString() ?? '');

    final addr = existingBranch?['address'] as Map<String, dynamic>? ?? {};
    final streetCtrl = TextEditingController(text: addr['street']?.toString() ?? '');
    final cityCtrl = TextEditingController(text: addr['city']?.toString() ?? '');
    final pincodeCtrl = TextEditingController(text: addr['pincode']?.toString() ?? '');

    String selectedDistrict = addr['district']?.toString() ?? 'Tiruchirappalli';
    if (!_districts.contains(selectedDistrict)) selectedDistrict = _districts.first;

    String currentStatus = existingBranch?['status']?.toString() ?? 'ACTIVE';
    bool isSaving = false;

    AppBottomSheet.show(
      context: context,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) => AppBottomSheet(
          title: isEditing ? 'Edit Branch Office' : 'Add New Branch Office',
          subtitle: isEditing ? 'Update address & contact details' : 'Register a new district operational branch',
          icon: AppIcons.building2,
          iconColor: AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Branch Name Field
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Branch Office Name *',
                  hintText: 'e.g. Trichy Town Main Branch',
                  prefixIcon: Icon(AppIcons.building2, size: 18, color: AppColors.textMuted),
                ),
                onChanged: (val) {
                  if (!isEditing && codeCtrl.text.isEmpty && val.trim().length >= 3) {
                    final words = val.trim().split(' ');
                    if (words.isNotEmpty) {
                      final prefix = words.map((w) => w.isNotEmpty ? w[0] : '').take(3).join().toUpperCase();
                      setSheetState(() => codeCtrl.text = 'BR-$prefix-01');
                    }
                  }
                },
              ),
              const SizedBox(height: 12),

              // Code & District Row
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: TextField(
                      controller: codeCtrl,
                      readOnly: isEditing,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Branch Code *',
                        hintText: 'BR-TRI-01',
                        prefixIcon: const Icon(AppIcons.hash, size: 16, color: AppColors.textMuted),
                        filled: isEditing,
                        fillColor: isEditing ? AppColors.surfaceCard : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('District *', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedDistrict,
                              isExpanded: true,
                              isDense: true,
                              dropdownColor: AppColors.surfaceElevated,
                              items: _districts.map((d) => DropdownMenuItem(
                                value: d,
                                child: Text(d, style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary)),
                              )).toList(),
                              onChanged: (val) {
                                if (val != null) setSheetState(() => selectedDistrict = val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Street Address
              TextField(
                controller: streetCtrl,
                decoration: const InputDecoration(
                  labelText: 'Street Address',
                  hintText: 'e.g. 14/2 Anna Salai, Opp. Bus Stand',
                  prefixIcon: Icon(AppIcons.mapPin, size: 18, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 12),

              // City & Pincode
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: cityCtrl,
                      decoration: const InputDecoration(
                        labelText: 'City / Town',
                        hintText: 'Trichy',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: pincodeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Pincode',
                        hintText: '620001',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Phone & Email
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Contact Phone',
                        hintText: '9876543210',
                        prefixIcon: Icon(AppIcons.phone, size: 16, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Official Email',
                        hintText: 'trichy@fin.com',
                        prefixIcon: Icon(AppIcons.mail, size: 16, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Status Selector (If Editing)
              if (isEditing) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Operational Status', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('ACTIVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            selected: currentStatus == 'ACTIVE',
                            selectedColor: AppColors.success.withValues(alpha: 0.2),
                            side: BorderSide(color: currentStatus == 'ACTIVE' ? AppColors.success : AppColors.border),
                            onSelected: (val) => setSheetState(() => currentStatus = 'ACTIVE'),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('INACTIVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            selected: currentStatus == 'INACTIVE',
                            selectedColor: AppColors.danger.withValues(alpha: 0.2),
                            side: BorderSide(color: currentStatus == 'INACTIVE' ? AppColors.danger : AppColors.border),
                            onSelected: (val) => setSheetState(() => currentStatus = 'INACTIVE'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Save Action Button
              AppButton(
                label: isEditing ? 'Save Branch Changes' : 'Register Branch Office',
                icon: AppIcons.check,
                isLoading: isSaving,
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final code = codeCtrl.text.trim();
                  if (name.isEmpty || code.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Branch Name and Branch Code are required')),
                    );
                    return;
                  }

                  setSheetState(() => isSaving = true);
                  final payload = {
                    'name': name,
                    'branchCode': code.toUpperCase(),
                    'phone': phoneCtrl.text.trim(),
                    'email': emailCtrl.text.trim(),
                    'address': {
                      'street': streetCtrl.text.trim(),
                      'city': cityCtrl.text.trim(),
                      'district': selectedDistrict,
                      'state': 'Tamil Nadu',
                      'pincode': pincodeCtrl.text.trim(),
                    },
                    if (isEditing) 'status': currentStatus,
                  };

                  final res = isEditing
                      ? await _apiClient.put('${ApiEndpoints.branches}/$branchId', data: payload)
                      : await _apiClient.post(ApiEndpoints.branches, data: payload);

                  setSheetState(() => isSaving = false);

                  if (res.success) {
                    if (context.mounted) Navigator.pop(sheetCtx);
                    _fetchBranches();
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

  void _confirmDeleteBranch(Map<String, dynamic> branch) async {
    final branchId = branch['_id']?.toString() ?? '';
    final name = branch['name']?.toString() ?? 'Branch';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete $name?', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 16)),
        content: const Text(
          'Are you sure you want to remove this branch? Associated customers and field staff will need to be reallocated.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Branch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await _apiClient.delete('${ApiEndpoints.branches}/$branchId');
      if (res.success) {
        _fetchBranches();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.message), backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Unique districts in current branch list
    final activeDistricts = _branches
        .map((b) => (b['address'] as Map<String, dynamic>?)?['district']?.toString())
        .where((d) => d != null && d.isNotEmpty)
        .toSet()
        .toList();

    final filtered = _branches.where((b) {
      final name = b['name']?.toString().toLowerCase() ?? '';
      final code = b['branchCode']?.toString().toLowerCase() ?? '';
      final addr = b['address'] as Map<String, dynamic>? ?? {};
      final district = addr['district']?.toString().toLowerCase() ?? '';
      final city = addr['city']?.toString().toLowerCase() ?? '';

      final matchesSearch = _searchQuery.isEmpty ||
          name.contains(_searchQuery.toLowerCase()) ||
          code.contains(_searchQuery.toLowerCase()) ||
          district.contains(_searchQuery.toLowerCase()) ||
          city.contains(_searchQuery.toLowerCase());

      final matchesDistrict = _selectedDistrictFilter == 'ALL' ||
          addr['district']?.toString().toLowerCase() == _selectedDistrictFilter.toLowerCase();

      return matchesSearch && matchesDistrict;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _fetchBranches,
        color: AppColors.primary,
        child: Column(
          children: [
            // Top Modern Action & Search Bar Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Row with Search Bar + Beautiful Add Branch Button
                  Row(
                    children: [
                      // Search Bar
                      Expanded(
                        child: TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Search branches, codes...',
                            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                            prefixIcon: const Icon(AppIcons.search, size: 17, color: AppColors.textMuted),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(AppIcons.x, size: 15, color: AppColors.textMuted),
                                    onPressed: () => setState(() => _searchQuery = ''),
                                  )
                                : null,
                            filled: true,
                            fillColor: AppColors.surfaceCard,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Premium "+ Add Branch" Button
                      ElevatedButton.icon(
                        onPressed: () => _openBranchModal(),
                        icon: const Icon(AppIcons.plusCircle, size: 15, color: Colors.white),
                        label: const Text('Add Branch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 1.5,
                          shadowColor: AppColors.primary.withValues(alpha: 0.25),
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // District Filter Chips Carousel
                  SizedBox(
                    height: 30,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildDistrictFilterChip('All Districts (${_branches.length})', 'ALL'),
                        ...activeDistricts.map((d) {
                          final count = _branches.where((b) => (b['address'] as Map<String, dynamic>?)?['district'] == d).length;
                          return _buildDistrictFilterChip('$d ($count)', d!);
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Branch List Section
            Expanded(
              child: _isLoading
                  ? ListView.separated(
                      padding: const EdgeInsets.all(14),
                      itemCount: 4,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, __) => const ShimmerListTile(),
                    )
                  : filtered.isEmpty
                      ? AppEmptyState(
                          title: _searchQuery.isNotEmpty ? 'No Branches Match Your Search' : 'No Branches Registered Yet',
                          subtitle: _searchQuery.isNotEmpty
                              ? 'Try searching with a different branch name, district or code.'
                              : 'Create multi-district branches to organize staff, customers and collection routes.',
                          icon: AppIcons.building2,
                          action: ElevatedButton.icon(
                            onPressed: () => _openBranchModal(),
                            icon: const Icon(AppIcons.plusCircle, size: 16, color: Colors.white),
                            label: const Text('Add First Branch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final branch = filtered[index] as Map<String, dynamic>;
                            return _buildBranchCard(context, branch);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchCard(BuildContext context, Map<String, dynamic> branch) {
    final branchId = branch['_id']?.toString() ?? '';
    final name = branch['name']?.toString() ?? 'Branch Office';
    final code = branch['branchCode']?.toString() ?? 'BR';
    final phone = branch['phone']?.toString() ?? '';
    final email = branch['email']?.toString() ?? '';
    final addr = branch['address'] as Map<String, dynamic>? ?? {};
    final district = addr['district']?.toString() ?? 'District';
    final city = addr['city']?.toString() ?? '';
    final street = addr['street']?.toString() ?? '';
    final pincode = addr['pincode']?.toString() ?? '';
    final status = branch['status']?.toString() ?? 'ACTIVE';
    final isActive = status == 'ACTIVE';

    final activeBranchId = context.watch<BranchCubit>().state.activeBranchId;
    final isCurrentlyActive = activeBranchId == branchId;

    final fullAddress = [
      if (street.isNotEmpty) street,
      if (city.isNotEmpty) city,
      district,
      if (pincode.isNotEmpty) pincode,
    ].join(', ');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentlyActive
              ? AppColors.primary
              : (isActive ? AppColors.border : AppColors.border.withValues(alpha: 0.5)),
          width: isCurrentlyActive ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrentlyActive
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header: Icon + Name + Badges + Compact Edit/Delete Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Branch Icon Container
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? AppColors.primaryGradient
                        : LinearGradient(colors: [
                            AppColors.textMuted.withValues(alpha: 0.3),
                            AppColors.textMuted.withValues(alpha: 0.2)
                          ]),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: const Center(
                    child: Icon(AppIcons.building2, size: 20, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),

                // Branch Name & Code Info
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
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          StatusBadge(status: status, isSmall: true),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 5,
                        runSpacing: 3,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              code,
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.accentCyan.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(AppIcons.mapPin, size: 9.5, color: AppColors.accentCyan),
                                const SizedBox(width: 2),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 100),
                                  child: Text(
                                    district,
                                    style: const TextStyle(
                                        fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.accentCyan),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Compact Action Buttons (Edit / Delete)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _openBranchModal(existingBranch: branch),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(AppIcons.edit, size: 14, color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _confirmDeleteBranch(branch),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(AppIcons.trash, size: 14, color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Location & Address Strip
          if (fullAddress.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(AppIcons.navigation, size: 11, color: AppColors.textMuted),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      fullAddress,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.25),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Email Strip (if present)
          if (email.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
              child: Row(
                children: [
                  const Icon(AppIcons.mail, size: 11, color: AppColors.textMuted),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      email,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Divider(color: AppColors.border, height: 14),

          // Bottom Strip: Phone on Left, Active Status / Switcher on Right
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Phone Contact with Call Link
                Expanded(
                  child: phone.isNotEmpty
                      ? InkWell(
                          onTap: () async {
                            final uri = Uri.parse('tel:$phone');
                            if (await canLaunchUrl(uri)) await launchUrl(uri);
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(AppIcons.phone, size: 12, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  phone,
                                  style: const TextStyle(
                                      color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const Text('No phone', style: TextStyle(color: AppColors.textMuted, fontSize: 10.5)),
                ),
                const SizedBox(width: 8),

                // Active Badge OR "Set as Active" Button
                if (isCurrentlyActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppIcons.badgeCheck, size: 11, color: AppColors.success),
                        SizedBox(width: 3),
                        Text('Current Active',
                            style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                else
                  InkWell(
                    onTap: () {
                      context.read<BranchCubit>().selectBranchById(branchId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Switched active branch to $name ($code)'),
                          backgroundColor: AppColors.primary,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(AppIcons.refresh, size: 10.5, color: AppColors.primaryDark),
                          SizedBox(width: 3),
                          Text('Set as Active',
                              style: TextStyle(
                                  color: AppColors.primaryDark, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistrictFilterChip(String label, String districtKey) {
    final isSelected = _selectedDistrictFilter == districtKey;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => setState(() => _selectedDistrictFilter = districtKey),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(14),
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
      ),
    );
  }
}
