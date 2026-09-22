import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../layout/branch_cubit.dart';

class AccountListScreen extends StatefulWidget {
  const AccountListScreen({super.key});

  @override
  State<AccountListScreen> createState() => _AccountListScreenState();
}

class _AccountListScreenState extends State<AccountListScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  String _search = '';
  String? _statusFilter;
  String? _lastLoadedBranchId = 'INIT';
  List<dynamic> _accounts = [];

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
  }

  Future<void> _fetchAccounts([String? branchIdOverride]) async {
    setState(() => _isLoading = true);
    final branchId = branchIdOverride ??
        (mounted ? context.read<BranchCubit>().state.activeBranchId : null);
    _lastLoadedBranchId = branchId;

    try {
      final res = await _apiClient.get(
        ApiEndpoints.financeAccounts,
        queryParameters: {
          if (_search.isNotEmpty) 'search': _search,
          if (_statusFilter != null) 'status': _statusFilter,
          if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
        },
      );
      if (res.success && res.data is List) {
        if (mounted) {
          setState(() {
            _accounts = res.data as List<dynamic>;
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

  void _openDisburseLoanBottomSheet() async {
    // Show a loading indicator while fetching prerequisites
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    final productsRes = await _apiClient.get(ApiEndpoints.financeProducts);
    final customersRes = await _apiClient.get(ApiEndpoints.customers, queryParameters: {'limit': 100});

    if (mounted) Navigator.pop(context); // dismiss loading dialog
    if (!mounted) return;

    final products = productsRes.data is List ? productsRes.data as List<dynamic> : [];
    final customers = customersRes.data is List ? customersRes.data as List<dynamic> : [];

    // 1. If no schemes found -> Offer 1-tap default scheme creator
    if (products.isEmpty) {
      _showMissingSchemeBottomSheet();
      return;
    }

    // 2. If no borrowers found -> Offer quick borrower registration
    if (customers.isEmpty) {
      _showMissingBorrowerBottomSheet();
      return;
    }

    // 3. Both exist -> Open Disburse Sheet
    String? selectedCustomerId = customers.first['_id']?.toString();
    String? selectedProductId = products.first['_id']?.toString();
    final principalCtrl = TextEditingController(text: '10000');
    bool isSaving = false;

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
          final dailyDue = (principal / installments).round();
          final freq = prod['frequency']?.toString() ?? 'DAILY';

          return AppBottomSheet(
            title: 'Disburse Finance Loan',
            subtitle: 'Issue micro-credit & generate schedule',
            icon: AppIcons.arrowUpRight,
            iconColor: AppColors.info,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Borrower Dropdown
                const Text('Select Borrower *', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButton<String>(
                    value: selectedCustomerId,
                    isExpanded: true,
                    dropdownColor: AppColors.surfaceElevated,
                    underline: const SizedBox(),
                    items: customers.map((c) {
                      return DropdownMenuItem<String>(
                        value: c['_id']?.toString(),
                        child: Text('${c['name']} (${c['customerCode']})', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) => setSheetState(() => selectedCustomerId = val),
                  ),
                ),
                const SizedBox(height: 14),

                // Scheme Dropdown
                const Text('Select Finance Scheme *', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
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
                const SizedBox(height: 16),

                // Live Financial Breakdown Preview Card
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
                          Text('Upfront Doc Fee ($docFeePercent%):', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          Text('- ${CurrencyFormatter.format(docFee)}', style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Net Cash Disbursed:', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                          Text(CurrencyFormatter.format(netPayout), style: const TextStyle(color: AppColors.primaryDark, fontSize: 15, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const Divider(color: AppColors.border, height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Installment ($installments $freq):', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          Text('₹$dailyDue / ${freq == 'DAILY' ? 'day' : 'week'}', style: const TextStyle(color: AppColors.warning, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Submit Button
                AppButton(
                  label: 'Disburse & Issue Loan',
                  icon: AppIcons.checkCheck,
                  isLoading: isSaving,
                  onPressed: () async {
                    if (selectedCustomerId == null || selectedProductId == null) return;

                    setSheetState(() => isSaving = true);
                    final res = await _apiClient.post(
                      ApiEndpoints.disburseLoan,
                      data: {
                        'customerId': selectedCustomerId,
                        'productId': selectedProductId,
                        'principalAmount': principal,
                      },
                    );
                    setSheetState(() => isSaving = false);

                    if (res.success) {
                      if (context.mounted) Navigator.pop(sheetCtx);
                      _fetchAccounts();
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

  void _showMissingSchemeBottomSheet() {
    bool isCreating = false;

    AppBottomSheet.show(
      context: context,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) => AppBottomSheet(
          title: 'No Finance Schemes Found',
          subtitle: 'Create a loan scheme before issuing disbursements',
          icon: AppIcons.packagePlus,
          iconColor: AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'A finance scheme defines how loans are structured (e.g. Daily 100-Day Micro Loan with 5% Upfront Documentation Fee).',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: '⚡ 1-Tap Create: Daily 100-Day Scheme (5% Fee)',
                icon: AppIcons.zap,
                isLoading: isCreating,
                onPressed: () async {
                  setSheetState(() => isCreating = true);
                  final res = await _apiClient.post(
                    ApiEndpoints.financeProducts,
                    data: {
                      'name': 'Daily 100-Day Micro Loan (5% Doc Fee)',
                      'productCode': 'DAILY100D',
                      'frequency': 'DAILY',
                      'calculationType': 'DOCUMENTATION_FEE_DEDUCTION',
                      'defaultInstallments': 100,
                      'docChargePercentage': 5.0,
                      'interestPercentage': 0.0,
                      'deductChargesUpfront': true,
                      'excludeSundays': true,
                    },
                  );
                  setSheetState(() => isCreating = false);

                  if (res.success) {
                    if (context.mounted) Navigator.pop(sheetCtx);
                    _openDisburseLoanBottomSheet();
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

  void _showMissingBorrowerBottomSheet() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final routeCtrl = TextEditingController(text: 'Line 1 - Central Market');
    bool isSaving = false;

    AppBottomSheet.show(
      context: context,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) => AppBottomSheet(
          title: 'Register Borrower First',
          subtitle: 'Add customer profile before disbursing loan',
          icon: AppIcons.userPlus,
          iconColor: AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Customer Full Name *', hintText: 'e.g. Ramesh Patel'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Mobile Phone Number *', hintText: 'e.g. 9876543210'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: routeCtrl,
                decoration: const InputDecoration(labelText: 'Route / Line Area', hintText: 'Line 1 - Central Market'),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Register & Continue to Disburse',
                icon: AppIcons.check,
                isLoading: isSaving,
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) return;

                  setSheetState(() => isSaving = true);
                  final res = await _apiClient.post(
                    ApiEndpoints.customers,
                    data: {
                      'name': nameCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'address': {'routeArea': routeCtrl.text.trim()},
                    },
                  );
                  setSheetState(() => isSaving = false);

                  if (res.success) {
                    if (context.mounted) Navigator.pop(sheetCtx);
                    _openDisburseLoanBottomSheet();
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
    final branchState = context.watch<BranchCubit>().state;
    final currentBranchId = branchState.activeBranchId;

    if (_lastLoadedBranchId != 'INIT' && _lastLoadedBranchId != currentBranchId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fetchAccounts(currentBranchId);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => _fetchAccounts(currentBranchId),
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
                              'Loan Accounts Branch: ${branchState.activeBranchName}',
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
                            hintText: 'Search account no (FIN-2026-0001)...',
                            prefixIcon: const Icon(AppIcons.search, size: 18, color: AppColors.textMuted),
                            suffixIcon: _search.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(AppIcons.x, size: 16, color: AppColors.textMuted),
                                    onPressed: () {
                                      setState(() => _search = '');
                                      _fetchAccounts(currentBranchId);
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          onChanged: (val) {
                            _search = val;
                            _fetchAccounts(currentBranchId);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _openDisburseLoanBottomSheet,
                        icon: const Icon(AppIcons.arrowUpRight, size: 16, color: Colors.white),
                        label: const Text('Disburse', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Filter Chips
                  SizedBox(
                    height: 30,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildFilterChip('All Statuses', null),
                        _buildFilterChip('Active Loans', 'ACTIVE'),
                        _buildFilterChip('Overdue', 'OVERDUE'),
                        _buildFilterChip('Completed', 'COMPLETED'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Accounts List
            Expanded(
              child: _isLoading
                  ? ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: 5,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, __) => const ShimmerListTile(),
                    )
                  : _accounts.isEmpty
                      ? const AppEmptyState(
                          title: 'No Loan Accounts Found',
                          subtitle: 'Tap "+ Disburse" above to issue a new microfinance loan.',
                          icon: AppIcons.wallet,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: _accounts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final acc = _accounts[index];
                            final accNo = acc['accountNumber']?.toString() ?? '';
                            final cust = acc['customerId'] as Map<String, dynamic>?;
                            final custId = cust?['_id']?.toString();
                            final custName = cust?['name']?.toString() ?? 'Borrower';
                            final custPhone = cust?['phone']?.toString() ?? '';
                            final principal = (acc['principalAmount'] as num?)?.toDouble() ?? 0.0;
                            final netDisbursed = (acc['netDisbursedAmount'] as num?)?.toDouble() ?? principal;
                            final totalPayable = (acc['totalPayableAmount'] as num?)?.toDouble() ?? 0.0;
                            final totalPaid = (acc['totalPaidAmount'] as num?)?.toDouble() ?? 0.0;
                            final remaining = (acc['remainingAmount'] as num?)?.toDouble() ?? 0.0;
                            final installmentAmt = (acc['installmentAmount'] as num?)?.toDouble() ?? 0.0;
                            final freq = acc['frequency']?.toString() ?? 'DAILY';
                            final status = acc['status']?.toString() ?? 'ACTIVE';

                            final progress = totalPayable > 0 ? (totalPaid / totalPayable).clamp(0.0, 1.0) : 0.0;

                            return InkWell(
                              onTap: custId != null ? () => BorrowerLedgerSheet.show(context, custId) : null,
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
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          accNo,
                                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 14),
                                        ),
                                        Row(
                                          children: [
                                            StatusBadge(status: freq, isSmall: true),
                                            const SizedBox(width: 6),
                                            StatusBadge(status: status, isSmall: true),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Borrower: $custName ($custPhone)',
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                    ),
                                    const SizedBox(height: 10),

                                    // Financial Details Grid
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
                                              const Text('Principal (Net Payout)', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                                              Text(
                                                '${CurrencyFormatter.format(principal)} (${CurrencyFormatter.format(netDisbursed)})',
                                                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              const Text('Remaining Balance', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                                              Text(
                                                CurrencyFormatter.format(remaining),
                                                style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w800, fontSize: 14),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // Progress Bar
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        backgroundColor: AppColors.surfaceCard,
                                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                        minHeight: 6,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Paid: ${CurrencyFormatter.format(totalPaid)} (${(progress * 100).toInt()}%)',
                                          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                                        ),
                                        Text(
                                          'Installment: ${CurrencyFormatter.format(installmentAmt)} / $freq',
                                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
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

  Widget _buildFilterChip(String label, String? status) {
    final isSelected = _statusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () {
          setState(() => _statusFilter = status);
          _fetchAccounts();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
