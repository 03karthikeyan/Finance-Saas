import 'package:flutter/material.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/app_widgets.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get(ApiEndpoints.financeProducts);
      if (res.success && res.data is List) {
        setState(() {
          _products = res.data as List<dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _openAddProductBottomSheet() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    String frequency = 'DAILY';
    const String calcType = 'DOCUMENTATION_FEE_DEDUCTION';
    final installmentsCtrl = TextEditingController(text: '100');
    final docFeeCtrl = TextEditingController(text: '5');
    bool isSaving = false;

    AppBottomSheet.show(
      context: context,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) => AppBottomSheet(
          title: 'Create Finance Scheme',
          subtitle: 'Define collection terms & loan parameters',
          icon: AppIcons.packagePlus,
          iconColor: AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Scheme Name *', hintText: 'e.g. Daily 100-Day Micro Loan'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: codeCtrl,
                      decoration: const InputDecoration(labelText: 'Scheme Code *', hintText: 'DAILY100D'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButton<String>(
                        value: frequency,
                        isExpanded: true,
                        dropdownColor: AppColors.surfaceElevated,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'DAILY', child: Text('DAILY')),
                          DropdownMenuItem(value: 'WEEKLY', child: Text('WEEKLY')),
                          DropdownMenuItem(value: 'MONTHLY', child: Text('MONTHLY')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() {
                              frequency = val;
                              if (val == 'DAILY') installmentsCtrl.text = '100';
                              if (val == 'WEEKLY') installmentsCtrl.text = '10';
                              if (val == 'MONTHLY') installmentsCtrl.text = '12';
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: installmentsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Installments Count *'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: docFeeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Doc Fee % (Upfront)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Save Finance Scheme',
                icon: AppIcons.check,
                isLoading: isSaving,
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty || codeCtrl.text.trim().isEmpty) return;

                  setSheetState(() => isSaving = true);
                  final res = await _apiClient.post(
                    ApiEndpoints.financeProducts,
                    data: {
                      'name': nameCtrl.text.trim(),
                      'productCode': codeCtrl.text.trim().toUpperCase(),
                      'frequency': frequency,
                      'calculationType': calcType,
                      'defaultInstallments': int.tryParse(installmentsCtrl.text.trim()) ?? 100,
                      'docChargePercentage': double.tryParse(docFeeCtrl.text.trim()) ?? 5.0,
                      'interestPercentage': 0.0,
                      'deductChargesUpfront': true,
                    },
                  );
                  setSheetState(() => isSaving = false);

                  if (res.success) {
                    if (context.mounted) Navigator.pop(sheetCtx);
                    _fetchProducts();
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

  void _openEditProductBottomSheet(Map<String, dynamic> prod) {
    final prodId = prod['_id']?.toString() ?? '';
    final nameCtrl = TextEditingController(text: prod['name']?.toString() ?? '');
    final installmentsCtrl = TextEditingController(text: (prod['defaultInstallments'] ?? 100).toString());
    final docFeeCtrl = TextEditingController(text: (prod['docChargePercentage'] ?? 5).toString());
    String status = prod['status']?.toString() ?? 'ACTIVE';
    bool isSaving = false;

    AppBottomSheet.show(
      context: context,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) => AppBottomSheet(
          title: 'Edit Finance Scheme',
          subtitle: 'Update parameters for ${nameCtrl.text}',
          icon: AppIcons.edit,
          iconColor: AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Scheme Name *'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: installmentsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Installments *'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: docFeeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Doc Fee %'),
                    ),
                  ),
                ],
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
                    DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE (Accepting New Loans)')),
                    DropdownMenuItem(value: 'INACTIVE', child: Text('INACTIVE (Disabled)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setSheetState(() => status = val);
                  },
                ),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Save Scheme Updates',
                icon: AppIcons.check,
                isLoading: isSaving,
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;

                  setSheetState(() => isSaving = true);
                  final res = await _apiClient.put(
                    '${ApiEndpoints.financeProducts}/$prodId',
                    data: {
                      'name': nameCtrl.text.trim(),
                      'defaultInstallments': int.tryParse(installmentsCtrl.text.trim()) ?? 100,
                      'docChargePercentage': double.tryParse(docFeeCtrl.text.trim()) ?? 5.0,
                      'status': status,
                    },
                  );
                  setSheetState(() => isSaving = false);

                  if (res.success) {
                    if (context.mounted) Navigator.pop(sheetCtx);
                    _fetchProducts();
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

  void _confirmDeleteProduct(Map<String, dynamic> prod) {
    final prodId = prod['_id']?.toString() ?? '';
    final name = prod['name']?.toString() ?? 'Scheme';

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(AppIcons.trash, color: AppColors.danger, size: 20),
            const SizedBox(width: 8),
            const Text('Delete Scheme?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ],
        ),
        content: Text('Are you sure you want to delete scheme "$name"?\nThis cannot be deleted if active loan accounts exist under this scheme.', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final res = await _apiClient.delete('${ApiEndpoints.financeProducts}/$prodId');
              if (res.success) {
                _fetchProducts();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _fetchProducts,
        color: AppColors.primary,
        child: Column(
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Finance Schemes',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  ElevatedButton.icon(
                    onPressed: _openAddProductBottomSheet,
                    icon: const Icon(AppIcons.packagePlus, size: 16, color: Colors.white),
                    label: const Text('Add Scheme', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),

            // Products List
            Expanded(
              child: _isLoading
                  ? const AppLoading(message: 'Loading schemes...')
                  : _products.isEmpty
                      ? const AppEmptyState(
                          title: 'No Finance Products',
                          subtitle: 'Tap "+ Add Scheme" to configure a loan product.',
                          icon: AppIcons.packagePlus,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          itemCount: _products.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final prod = _products[index];
                            final name = prod['name']?.toString() ?? '';
                            final code = prod['productCode']?.toString() ?? '';
                            final freq = prod['frequency']?.toString() ?? 'DAILY';
                            final installments = prod['defaultInstallments'] ?? 100;
                            final docFee = prod['docChargePercentage'] ?? 5;
                            final status = prod['status']?.toString() ?? 'ACTIVE';

                            return Container(
                              padding: const EdgeInsets.all(16),
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
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
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
                                  const SizedBox(height: 2),
                                  Text('Code: $code', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceCard,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Duration: $installments $freq installments', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                        Text('Doc Fee: $docFee% Upfront', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Divider(color: AppColors.border),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(AppIcons.edit, size: 16, color: AppColors.primary),
                                        tooltip: 'Edit Scheme',
                                        onPressed: () => _openEditProductBottomSheet(prod),
                                        style: IconButton.styleFrom(
                                          backgroundColor: AppColors.surfaceCard,
                                          padding: const EdgeInsets.all(6),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      IconButton(
                                        icon: const Icon(AppIcons.trash, size: 16, color: AppColors.danger),
                                        tooltip: 'Delete Scheme',
                                        onPressed: () => _confirmDeleteProduct(prod),
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
