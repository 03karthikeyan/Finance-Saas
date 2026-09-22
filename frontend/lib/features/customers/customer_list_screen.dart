import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../authentication/presentation/auth_cubit.dart';
import '../layout/branch_cubit.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  String _search = '';
  String? _lastLoadedBranchId = 'INIT';
  List<dynamic> _customers = [];

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers([String? branchIdOverride]) async {
    setState(() => _isLoading = true);
    final branchId = branchIdOverride ??
        (mounted ? context.read<BranchCubit>().state.activeBranchId : null);
    _lastLoadedBranchId = branchId;

    try {
      final res = await _apiClient.get(
        ApiEndpoints.customers,
        queryParameters: {
          'limit': 100,
          if (_search.isNotEmpty) 'search': _search,
          if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
        },
      );
      if (res.success && res.data is List) {
        if (mounted) {
          setState(() {
            _customers = res.data as List<dynamic>;
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

  void _openDisburseForCustomer(Map<String, dynamic> cust) async {
    final custId = cust['_id']?.toString() ?? '';
    final custName = cust['name']?.toString() ?? 'Borrower';
    final custCode = cust['customerCode']?.toString() ?? '';

    // Show loading dialog while fetching schemes
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    final productsRes = await _apiClient.get(ApiEndpoints.financeProducts);
    if (mounted) Navigator.pop(context);
    if (!mounted) return;

    var products = productsRes.data is List ? productsRes.data as List<dynamic> : [];

    // If no schemes exist, create default 100-day daily scheme
    if (products.isEmpty) {
      final createRes = await _apiClient.post(
        ApiEndpoints.financeProducts,
        data: {
          'name': 'Standard 100-Day Micro Finance',
          'code': 'DAILY-100',
          'calculationType': 'FIXED_PERCENTAGE',
          'frequency': 'DAILY',
          'defaultPrincipal': 10000,
          'interestPercentage': 0,
          'docChargePercentage': 5,
          'defaultInstallments': 100,
          'status': 'ACTIVE',
        },
      );
      if (createRes.success && createRes.data != null) {
        products = [createRes.data];
      }
    }

    if (products.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active finance schemes found. Please create a scheme in Admin.')),
        );
      }
      return;
    }

    String? selectedProductId = products.first['_id']?.toString();
    final principalCtrl = TextEditingController(text: '10000');
    bool isSaving = false;

    if (!mounted) return;

    AppBottomSheet.show(
      context: context,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final prod = products.firstWhere(
            (p) => p['_id']?.toString() == selectedProductId,
            orElse: () => products.first,
          ) as Map<String, dynamic>;

          final principal = double.tryParse(principalCtrl.text.trim()) ?? 10000.0;
          final docFeePercent = (prod['docChargePercentage'] as num?)?.toDouble() ?? 5.0;
          final docFee = (principal * docFeePercent) / 100.0;
          final netPayout = principal - docFee;
          final installments = prod['defaultInstallments'] ?? 100;
          final dailyDue = installments > 0 ? (principal / installments).round() : 100;
          final freq = prod['frequency']?.toString() ?? 'DAILY';

          return AppBottomSheet(
            title: 'Disburse Loan to $custName',
            subtitle: '$custCode • Create loan schedule & collect daily',
            icon: AppIcons.arrowUpRight,
            iconColor: AppColors.info,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Scheme Dropdown
                const Text('Select Scheme *', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButton<String>(
                    value: selectedProductId,
                    isExpanded: true,
                    dropdownColor: AppColors.surfaceElevated,
                    underline: const SizedBox(),
                    items: products.map((p) {
                      return DropdownMenuItem<String>(
                        value: p['_id']?.toString(),
                        child: Text('${p['name']} ($freq)', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) => setSheetState(() => selectedProductId = val),
                  ),
                ),
                const SizedBox(height: 14),

                // Principal Amount Input
                const Text('Principal Amount (₹) *', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: principalCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  onChanged: (_) => setSheetState(() {}),
                ),
                const SizedBox(height: 14),

                // Live Breakdown Preview Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Doc Fee ($docFeePercent%):', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          Text('- ${CurrencyFormatter.format(docFee)}', style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Net Cash Payout:', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                          Text(CurrencyFormatter.format(netPayout), style: const TextStyle(color: AppColors.success, fontSize: 15, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const Divider(color: AppColors.border, height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Installment ($freq):', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          Text('₹$dailyDue / day ($installments days)', style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Disburse Button
                AppButton(
                  label: 'Disburse ₹${principal.toInt()} Loan',
                  icon: AppIcons.checkCircle2,
                  isLoading: isSaving,
                  onPressed: () async {
                    if (principal <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid principal amount')),
                      );
                      return;
                    }

                    setSheetState(() => isSaving = true);
                    final res = await _apiClient.post(
                      ApiEndpoints.disburseLoan,
                      data: {
                        'customerId': custId,
                        'productId': selectedProductId,
                        'principalAmount': principal,
                        'startDate': DateTime.now().toIso8601String(),
                      },
                    );
                    setSheetState(() => isSaving = false);

                    if (res.success) {
                      if (context.mounted) Navigator.pop(sheetCtx);
                      _fetchCustomers();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Loan Disbursed! It is now active on your Collect screen.'),
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

  void _openAddCustomerBottomSheet() async {
    final branchState = context.read<BranchCubit>().state;
    final branches = branchState.branches;
    String? selectedBranchId = branchState.activeBranchId ?? (branches.isNotEmpty ? branches.first['_id']?.toString() : null);

    // ── Pre-fetch loan schemes ──────────────────────────────────────────────
    List<dynamic> products = [];
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    try {
      final productsRes = await _apiClient.get(ApiEndpoints.financeProducts);
      if (mounted) Navigator.pop(context);
      if (productsRes.success && productsRes.data is List) {
        products = productsRes.data as List<dynamic>;
      }
    } catch (_) {
      if (mounted) Navigator.pop(context);
    }
    // ───────────────────────────────────────────────────────────────────────

    if (!mounted) return;

    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final altPhoneCtrl = TextEditingController();
    final routeCtrl = TextEditingController();
    final streetCtrl = TextEditingController();
    final cityCtrl = TextEditingController(text: branchState.activeBranchDistrict ?? 'Trichy');
    final proofNumberCtrl = TextEditingController();
    final creditLimitCtrl = TextEditingController(text: '100000');
    final guarantorNameCtrl = TextEditingController();
    final guarantorPhoneCtrl = TextEditingController();
    final principalCtrl = TextEditingController(text: '10000');

    String selectedProofType = 'Aadhaar Card';
    String selectedRelation = 'Spouse';
    String? profilePhotoBase64;
    bool isSaving = false;

    // Loan section state
    bool addLoanNow = products.isNotEmpty;
    String? selectedProductId = products.isNotEmpty ? products.first['_id']?.toString() : null;

    final proofTypes = [
      'Aadhaar Card',
      'Ration Card',
      'Voter ID',
      'PAN Card',
      'Driving License',
      'Passport',
      'National ID',
    ];

    final relations = [
      'Spouse',
      'Father',
      'Mother',
      'Brother',
      'Sister',
      'Son',
      'Daughter',
      'Friend',
      'Business Partner',
      'Other',
    ];

    AppBottomSheet.show(
      context: context,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) {
          // Live loan preview values
          final prod = (addLoanNow && products.isNotEmpty)
              ? (products.firstWhere(
                  (p) => p['_id']?.toString() == selectedProductId,
                  orElse: () => products.first,
                ) as Map<String, dynamic>)
              : null;
          final principal = double.tryParse(principalCtrl.text.trim()) ?? 10000.0;
          final docFeePercent = prod != null ? (prod['docChargePercentage'] as num?)?.toDouble() ?? 5.0 : 5.0;
          final docFee = (principal * docFeePercent) / 100.0;
          final netPayout = principal - docFee;
          final installments = prod != null ? (prod['defaultInstallments'] ?? 100) : 100;
          final freq = prod != null ? prod['frequency']?.toString() ?? 'DAILY' : 'DAILY';
          final dailyDue = installments > 0 ? (principal / installments).round() : 100;

          return AppBottomSheet(
            title: 'Register New Borrower',
            subtitle: 'Create borrower profile with branch allocation & KYC',
            icon: AppIcons.userPlus,
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
                        fallbackText: nameCtrl.text.isNotEmpty ? nameCtrl.text : 'Borrower',
                        fallbackIcon: AppIcons.userPlus,
                        isEditable: true,
                        onTap: () async {
                          final picked = await AppImagePicker.showImageSourceDialog(
                            context,
                            title: 'Upload Borrower Photo',
                            allowRemove: profilePhotoBase64 != null && profilePhotoBase64!.isNotEmpty,
                          );
                          if (picked != null) {
                            setSheetState(() => profilePhotoBase64 = picked);
                          }
                        },
                      ),
                      const SizedBox(height: 6),
                      Text(
                        profilePhotoBase64 != null && profilePhotoBase64!.isNotEmpty ? 'Tap photo to change or remove' : 'Tap to upload borrower photo',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Branch Allocation Dropdown
                if (branches.isNotEmpty) ...[
                  const Text('Allocated Branch Office *', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
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

                // Borrower Name
                TextField(
                  controller: nameCtrl,
                  onChanged: (_) => setSheetState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Customer Full Name *',
                    hintText: 'e.g. Ramesh Patel',
                    prefixIcon: Icon(AppIcons.users, size: 18, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 12),

                // Phone numbers
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Mobile Phone *',
                          hintText: '9876543210',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: altPhoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Alt Phone',
                          hintText: 'Optional',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Route Line & Street
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: routeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Route / Line Area *',
                          hintText: 'Line 1 - Market',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: streetCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Shop / Street Address',
                          hintText: 'Shop 12, Bazaar',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // KYC Identification Proof Section
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
                          Icon(AppIcons.badgeCheck, size: 16, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text('KYC & ID Verification', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
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
                                labelText: 'ID Proof Number',
                                hintText: 'e.g. 5432 1098 7654',
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Guarantor & Nominee Section
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
                          Icon(AppIcons.userCheck, size: 16, color: AppColors.accentIndigo),
                          SizedBox(width: 6),
                          Text('Guarantor / Nominee Details', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: guarantorNameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Guarantor Name',
                                hintText: 'Nominee Name',
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: guarantorPhoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Guarantor Phone',
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
                          value: selectedRelation,
                          isExpanded: true,
                          dropdownColor: AppColors.surfaceElevated,
                          underline: const SizedBox(),
                          items: relations.map((r) => DropdownMenuItem(value: r, child: Text('Relation: $r', style: const TextStyle(fontSize: 12)))).toList(),
                          onChanged: (val) {
                            if (val != null) setSheetState(() => selectedRelation = val);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Loan Scheme Section ────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: addLoanNow
                        ? AppColors.primary.withValues(alpha: 0.06)
                        : AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: addLoanNow
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : AppColors.border,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Toggle header
                      Row(
                        children: [
                          const Icon(AppIcons.arrowUpRight, size: 16, color: AppColors.success),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'Disburse Loan at Registration',
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Switch(
                            value: addLoanNow,
                            onChanged: products.isNotEmpty
                                ? (val) => setSheetState(() => addLoanNow = val)
                                : null,
                            activeColor: AppColors.primary,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),

                      if (!addLoanNow) ...[
                        const SizedBox(height: 4),
                        Text(
                          products.isEmpty
                              ? 'No active loan schemes found. Create one in Finance Products.'
                              : 'Toggle ON to immediately disburse a loan when saving.',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],

                      if (addLoanNow && products.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        // Scheme dropdown
                        const Text('Select Loan Scheme *', style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButton<String>(
                            value: selectedProductId,
                            isExpanded: true,
                            dropdownColor: AppColors.surfaceElevated,
                            underline: const SizedBox(),
                            items: products.map((p) {
                              final pFreq = p['frequency']?.toString() ?? 'DAILY';
                              final pInst = p['defaultInstallments'] ?? 100;
                              return DropdownMenuItem<String>(
                                value: p['_id']?.toString(),
                                child: Text(
                                  '${p['name']} • $pFreq / $pInst installments',
                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) => setSheetState(() => selectedProductId = val),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Principal amount
                        const Text('Loan Principal Amount (₹) *', style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: principalCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            prefixText: '₹ ',
                            prefixStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          onChanged: (_) => setSheetState(() {}),
                        ),
                        const SizedBox(height: 10),

                        // Live breakdown preview
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Doc Fee ($docFeePercent%):', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                  Text('- ₹${docFee.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Net Cash Payout:', style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                                  Text('₹${netPayout.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.success, fontSize: 14, fontWeight: FontWeight.w800)),
                                ],
                              ),
                              const Divider(color: AppColors.border, height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('$freq Installment:', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                  Text('₹$dailyDue × $installments', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // ──────────────────────────────────────────────────────────────

                const SizedBox(height: 20),

                // Submit Button
                AppButton(
                  label: addLoanNow ? 'Register & Disburse ₹${principal.toInt()} Loan' : 'Register Borrower Profile',
                  icon: AppIcons.check,
                  isLoading: isSaving,
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Name and phone are required')),
                      );
                      return;
                    }

                    if (addLoanNow && (principal <= 0)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid loan amount')),
                      );
                      return;
                    }

                    setSheetState(() => isSaving = true);

                    // ── Step 1: Create the borrower profile ─────────────────────
                    final res = await _apiClient.post(
                      ApiEndpoints.customers,
                      data: {
                        'name': nameCtrl.text.trim(),
                        'phone': phoneCtrl.text.trim(),
                        'alternatePhone': altPhoneCtrl.text.trim(),
                        'branchId': selectedBranchId,
                        'address': {
                          'routeArea': routeCtrl.text.trim(),
                          'street': streetCtrl.text.trim(),
                          'city': cityCtrl.text.trim(),
                        },
                        'identityProof': {
                          'idType': selectedProofType,
                          'idNumber': proofNumberCtrl.text.trim(),
                        },
                        'guarantor': {
                          'name': guarantorNameCtrl.text.trim(),
                          'phone': guarantorPhoneCtrl.text.trim(),
                          'relation': selectedRelation,
                        },
                        'creditLimit': double.tryParse(creditLimitCtrl.text.trim()) ?? 100000,
                        if (profilePhotoBase64 != null && profilePhotoBase64!.isNotEmpty) 'profileImage': profilePhotoBase64,
                      },
                    );

                    if (!res.success) {
                      setSheetState(() => isSaving = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(res.message), backgroundColor: AppColors.danger),
                        );
                      }
                      return;
                    }

                    // Extract the new customer ID from response
                    // Backend returns { customer: {...}, loanAccount: null }
                    String? newCustomerId;
                    final resData = res.data;
                    if (resData is Map) {
                      final dataMap = resData as Map<String, dynamic>;
                      if (dataMap['customer'] is Map) {
                        newCustomerId = (dataMap['customer'] as Map<String, dynamic>)['_id']?.toString();
                      } else {
                        newCustomerId = dataMap['_id']?.toString();
                      }
                    }

                    // ── Step 2: Disburse loan via the proven disburse endpoint ───
                    if (addLoanNow && selectedProductId != null && principal > 0 && newCustomerId != null) {
                      final loanRes = await _apiClient.post(
                        ApiEndpoints.disburseLoan,
                        data: {
                          'customerId': newCustomerId,
                          'productId': selectedProductId,
                          'principalAmount': principal,
                          'startDate': DateTime.now().toIso8601String(),
                        },
                      );

                      setSheetState(() => isSaving = false);
                      if (context.mounted) Navigator.pop(sheetCtx);
                      _fetchCustomers();

                      if (context.mounted) {
                        if (loanRes.success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ Borrower registered & Loan ₹${principal.toInt()} disbursed! Active on Collect screen.'),
                              backgroundColor: AppColors.success,
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Borrower registered, but loan failed: ${loanRes.message}'),
                              backgroundColor: AppColors.warning,
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        }
                      }
                    } else {
                      // No loan — just register borrower
                      setSheetState(() => isSaving = false);
                      if (context.mounted) Navigator.pop(sheetCtx);
                      _fetchCustomers();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Borrower registered successfully!'),
                            backgroundColor: AppColors.success,
                          ),
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

  void _openEditCustomerBottomSheet(Map<String, dynamic> cust) {
    final branchState = context.read<BranchCubit>().state;
    final branches = branchState.branches;
    String? selectedBranchId = cust['branchId'] is Map
        ? cust['branchId']['_id']?.toString()
        : cust['branchId']?.toString();

    final custId = cust['_id']?.toString() ?? '';
    final nameCtrl = TextEditingController(text: cust['name']?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: cust['phone']?.toString() ?? '');
    final altPhoneCtrl = TextEditingController(text: cust['alternatePhone']?.toString() ?? '');
    final addr = cust['address'] as Map<String, dynamic>? ?? {};
    final routeCtrl = TextEditingController(text: addr['routeArea']?.toString() ?? 'Line 1');
    final streetCtrl = TextEditingController(text: addr['street']?.toString() ?? '');
    final kyc = cust['identityProof'] as Map<String, dynamic>? ?? {};
    final proofNumberCtrl = TextEditingController(text: kyc['idNumber']?.toString() ?? '');
    final guarantor = cust['guarantor'] as Map<String, dynamic>? ?? {};
    final guarantorNameCtrl = TextEditingController(text: guarantor['name']?.toString() ?? '');
    final guarantorPhoneCtrl = TextEditingController(text: guarantor['phone']?.toString() ?? '');

    String selectedProofType = kyc['idType']?.toString() ?? 'Aadhaar Card';
    String selectedRelation = guarantor['relation']?.toString() ?? 'Spouse';
    String? profilePhotoBase64 = cust['profileImage']?.toString();
    bool isSaving = false;

    final proofTypes = [
      'Aadhaar Card',
      'Ration Card',
      'Voter ID',
      'PAN Card',
      'Driving License',
      'Passport',
      'National ID',
    ];

    final relations = [
      'Spouse',
      'Father',
      'Mother',
      'Brother',
      'Sister',
      'Son',
      'Daughter',
      'Friend',
      'Business Partner',
      'Other',
    ];

    if (!proofTypes.contains(selectedProofType)) {
      proofTypes.insert(0, selectedProofType);
    }
    if (!relations.contains(selectedRelation)) {
      relations.insert(0, selectedRelation);
    }

    AppBottomSheet.show(
      context: context,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) => AppBottomSheet(
          title: 'Edit Borrower Info',
          subtitle: 'Update details & branch for ${nameCtrl.text}',
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
                      fallbackText: nameCtrl.text.isNotEmpty ? nameCtrl.text : 'Borrower',
                      fallbackIcon: AppIcons.users,
                      isEditable: true,
                      onTap: () async {
                        final picked = await AppImagePicker.showImageSourceDialog(
                          context,
                          title: 'Update Borrower Photo',
                          allowRemove: profilePhotoBase64 != null && profilePhotoBase64!.isNotEmpty,
                        );
                        if (picked != null) {
                          setSheetState(() => profilePhotoBase64 = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      profilePhotoBase64 != null && profilePhotoBase64!.isNotEmpty ? 'Tap photo to change or remove' : 'Tap to upload borrower photo',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Branch Allocation Dropdown
              if (branches.isNotEmpty) ...[
                const Text('Allocated Branch Office *', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
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
                decoration: const InputDecoration(labelText: 'Customer Full Name *'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Mobile Phone *'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: altPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Alt Phone'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: routeCtrl,
                      decoration: const InputDecoration(labelText: 'Route / Line Area *'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: streetCtrl,
                      decoration: const InputDecoration(labelText: 'Shop / Street Address'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // KYC Identification Proof Section
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
                        Icon(AppIcons.badgeCheck, size: 16, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text('KYC ID Verification', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
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
                              labelText: 'ID Proof Number',
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Guarantor Details Section
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
                        Icon(AppIcons.userCheck, size: 16, color: AppColors.accentIndigo),
                        SizedBox(width: 6),
                        Text('Guarantor Details', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: guarantorNameCtrl,
                            decoration: const InputDecoration(labelText: 'Guarantor Name'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: guarantorPhoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(labelText: 'Guarantor Phone'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              AppButton(
                label: 'Save Changes',
                icon: AppIcons.check,
                isLoading: isSaving,
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) return;

                  setSheetState(() => isSaving = true);
                  final res = await _apiClient.put(
                    '${ApiEndpoints.customers}/$custId',
                    data: {
                      'name': nameCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'alternatePhone': altPhoneCtrl.text.trim(),
                      if (selectedBranchId != null) 'branchId': selectedBranchId,
                      'address': {
                        'routeArea': routeCtrl.text.trim(),
                        'street': streetCtrl.text.trim(),
                      },
                      'identityProof': {
                        'idType': selectedProofType,
                        'idNumber': proofNumberCtrl.text.trim(),
                      },
                      'guarantor': {
                        'name': guarantorNameCtrl.text.trim(),
                        'phone': guarantorPhoneCtrl.text.trim(),
                        'relation': selectedRelation,
                      },
                      if (profilePhotoBase64 != null) 'profileImage': profilePhotoBase64,
                    },
                  );
                  setSheetState(() => isSaving = false);

                  if (res.success) {
                    if (context.mounted) Navigator.pop(sheetCtx);
                    _fetchCustomers();
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

  void _openCustomerLoginAccessModal(Map<String, dynamic> cust) {
    final custId = cust['_id']?.toString() ?? '';
    final name = cust['name']?.toString() ?? 'Borrower';
    final phone = cust['phone']?.toString() ?? '';
    final passwordCtrl = TextEditingController(text: phone.replaceAll(RegExp(r'\D'), '').isNotEmpty ? phone.replaceAll(RegExp(r'\D'), '').substring(phone.replaceAll(RegExp(r'\D'), '').length > 6 ? phone.replaceAll(RegExp(r'\D'), '').length - 6 : 0) : '123456');
    bool isSaving = false;
    bool obscure = false;

    AppBottomSheet.show(
      context: context,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) => AppBottomSheet(
          title: 'Borrower App Login Access',
          subtitle: 'Enable or reset mobile login credentials for $name',
          icon: AppIcons.key,
          iconColor: AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Login Identifier (Mobile Number):', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      phone,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryDark),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: passwordCtrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'Set App Password *',
                  hintText: 'e.g. 123456 or Customer@2026',
                  prefixIcon: const Icon(AppIcons.lock, size: 18, color: AppColors.textMuted),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? AppIcons.eyeOff : AppIcons.eye, size: 18, color: AppColors.textMuted),
                    onPressed: () => setSheetState(() => obscure = !obscure),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The customer can use their registered mobile number and this password to log in to the Customer Portal.',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Save & Enable Customer Login',
                icon: AppIcons.check,
                isLoading: isSaving,
                onPressed: () async {
                  final newPass = passwordCtrl.text.trim();
                  if (newPass.length < 4) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password must be at least 4 characters long')),
                    );
                    return;
                  }

                  setSheetState(() => isSaving = true);
                  final res = await _apiClient.post(
                    '${ApiEndpoints.customers}/$custId/login-access',
                    data: {'password': newPass},
                  );
                  setSheetState(() => isSaving = false);

                  if (res.success) {
                    if (context.mounted) {
                      Navigator.pop(sheetCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('App login access active for $name ($phone)'),
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
        ),
      ),
    );
  }

  void _confirmDeleteCustomer(Map<String, dynamic> cust) {
    final custId = cust['_id']?.toString() ?? '';
    final name = cust['name']?.toString() ?? 'Borrower';

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete $name?', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text(
          'Are you sure you want to permanently delete this borrower? All past records and active loan summaries will be removed.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final res = await _apiClient.delete('${ApiEndpoints.customers}/$custId');
              if (res.success) {
                _fetchCustomers();
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res.message), backgroundColor: AppColors.danger),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete Borrower', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _callCustomer(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final url = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _whatsappCustomer(String phone, String name) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final targetPhone = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
    final msg = 'Hello $name, Greetings from Finance Support.';
    final url = Uri.parse('https://wa.me/$targetPhone?text=${Uri.encodeComponent(msg)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final branchState = context.watch<BranchCubit>().state;
    final currentBranchId = branchState.activeBranchId;

    if (_lastLoadedBranchId != 'INIT' && _lastLoadedBranchId != currentBranchId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fetchCustomers(currentBranchId);
      });
    }

    final isAdmin = authState is Authenticated &&
        (authState.role == 'COMPANY_ADMIN' || authState.role == 'SUPER_ADMIN' || authState.role == 'MANAGER');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => _fetchCustomers(currentBranchId),
        color: AppColors.primary,
        child: Column(
          children: [
            // Top Controls Bar
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
                              'Borrowers Branch: ${branchState.activeBranchName}',
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
                            hintText: 'Search borrower name, code, phone, line...',
                            prefixIcon: const Icon(AppIcons.search, size: 18, color: AppColors.textMuted),
                            suffixIcon: _search.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(AppIcons.x, size: 16, color: AppColors.textMuted),
                                    onPressed: () {
                                      setState(() => _search = '');
                                      _fetchCustomers(currentBranchId);
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          onChanged: (val) {
                            _search = val;
                            _fetchCustomers(currentBranchId);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _openAddCustomerBottomSheet,
                        icon: const Icon(AppIcons.userPlus, size: 16, color: Colors.white),
                        label: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
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

            // Customers List
            Expanded(
              child: _isLoading
                  ? ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      itemCount: 5,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, __) => const ShimmerListTile(),
                    )
                  : _customers.isEmpty
                      ? const AppEmptyState(
                          title: 'No Borrowers Found',
                          subtitle: 'Tap "+ Add" above to register your first borrower.',
                          icon: AppIcons.users,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          itemCount: _customers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final cust = _customers[index];
                            final custId = cust['_id']?.toString() ?? '';
                            final name = cust['name']?.toString() ?? 'Borrower';
                            final code = cust['customerCode']?.toString() ?? '';
                            final phone = cust['phone']?.toString() ?? '';
                            final photo = cust['profileImage']?.toString();
                            final route = cust['address']?['routeArea']?.toString() ?? 'General';
                            final branchObj = cust['branchId'] as Map<String, dynamic>?;
                            final branchName = branchObj?['name']?.toString();
                            final kycObj = cust['identityProof'] as Map<String, dynamic>?;
                            final idType = kycObj?['idType']?.toString();
                            final idNumber = kycObj?['idNumber']?.toString();
                            final totalPaid = cust['totalPaidAmount'] ?? 0;
                            final outstanding = cust['totalOutstandingAmount'] ?? 0;
                            final activeLoans = cust['totalActiveLoans'] ?? 0;

                            return InkWell(
                              onTap: () => BorrowerLedgerSheet.show(context, custId),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Top Row: Avatar + Name + Quick Contact (Call & WhatsApp)
                                    Row(
                                      children: [
                                        AppAvatar(
                                          imageSource: photo,
                                          radius: 20,
                                          fallbackText: name,
                                          fallbackIcon: AppIcons.users,
                                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                          foregroundColor: AppColors.primary,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      name,
                                                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.surfaceCard,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(code, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text('$phone • $route', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                            ],
                                          ),
                                        ),
                                        if (phone.isNotEmpty) ...[
                                          InkWell(
                                            onTap: () => _callCustomer(phone),
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: AppColors.info.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(AppIcons.phone, size: 15, color: AppColors.info),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          InkWell(
                                            onTap: () => _whatsappCustomer(phone, name),
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF25D366).withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(AppIcons.messageCircle, size: 15, color: Color(0xFF25D366)),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),

                                    // Branch & KYC Badges Row
                                    if (branchName != null || (idNumber != null && idNumber.isNotEmpty)) ...[
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
                                          if (idNumber != null && idNumber.isNotEmpty)
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
                                                  Text('${idType ?? "ID"}: $idNumber', style: const TextStyle(color: AppColors.textSecondary, fontSize: 9.5)),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 10),

                                    // Financial Metrics Box
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
                                              const Text('Outstanding Balance', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                                              Text(
                                                CurrencyFormatter.format(outstanding),
                                                style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              const Text('Total Repaid', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                                              Text(
                                                CurrencyFormatter.format(totalPaid),
                                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Divider(color: AppColors.border, height: 10),

                                    // Footer Row: Active Loans Chip & Edit/Delete Actions
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (activeLoans == 0) ...[
                                          InkWell(
                                            onTap: () => _openDisburseForCustomer(cust),
                                            borderRadius: BorderRadius.circular(6),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.success.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                                              ),
                                              child: const Row(
                                                children: [
                                                  Icon(AppIcons.arrowUpRight, size: 12, color: AppColors.success),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    '+ Give Loan',
                                                    style: TextStyle(
                                                      color: AppColors.success,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ] else ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '$activeLoans Active Loan(s)',
                                              style: const TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                        Row(
                                          children: [
                                            InkWell(
                                              onTap: () => _openCustomerLoginAccessModal(cust),
                                              borderRadius: BorderRadius.circular(6),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.accentIndigo.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Row(
                                                  children: [
                                                    Icon(AppIcons.key, size: 12, color: AppColors.accentIndigo),
                                                    SizedBox(width: 4),
                                                    Text('Login', style: TextStyle(color: AppColors.accentIndigo, fontSize: 11, fontWeight: FontWeight.bold)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            InkWell(
                                              onTap: () => _openEditCustomerBottomSheet(cust),
                                              borderRadius: BorderRadius.circular(6),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary.withValues(alpha: 0.08),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Row(
                                                  children: [
                                                    Icon(AppIcons.edit, size: 13, color: AppColors.primary),
                                                    SizedBox(width: 4),
                                                    Text('Edit', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            if (isAdmin) ...[
                                              const SizedBox(width: 6),
                                              InkWell(
                                                onTap: () => _confirmDeleteCustomer(cust),
                                                borderRadius: BorderRadius.circular(6),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.danger.withValues(alpha: 0.08),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: const Row(
                                                    children: [
                                                      Icon(AppIcons.trash, size: 13, color: AppColors.danger),
                                                      SizedBox(width: 4),
                                                      Text('Delete', style: TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.w600)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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
