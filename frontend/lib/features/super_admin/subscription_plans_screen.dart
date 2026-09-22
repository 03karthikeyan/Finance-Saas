import 'package:flutter/material.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_widgets.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _plans = [];

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get(ApiEndpoints.subscriptionPlans);
      if (res.success && res.data is List) {
        setState(() {
          _plans = res.data as List<dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _openCreatePlanBottomSheet() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '1');
    final maxBranchesCtrl = TextEditingController(text: '3');
    final maxAgentsCtrl = TextEditingController(text: '10');
    final maxCustCtrl = TextEditingController(text: '1000');
    bool isSaving = false;

    AppBottomSheet.show(
      context: context,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) => AppBottomSheet(
          title: 'Create SaaS Plan',
          subtitle: 'Define pricing & feature limits for finance clients',
          icon: AppIcons.badgeCheck,
          iconColor: AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Plan Name *', hintText: 'e.g. Growth Pro Tier'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price (₹) *', hintText: '4999'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: durationCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Duration (Months) *', hintText: '1'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: maxBranchesCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Max Branches *', hintText: '5'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: maxAgentsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Max Agents *', hintText: '15'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: maxCustCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Max Borrowers *', hintText: '2000'),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Save Subscription Plan',
                icon: AppIcons.check,
                isLoading: isSaving,
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty || priceCtrl.text.trim().isEmpty) return;

                  setSheetState(() => isSaving = true);
                  final res = await _apiClient.post(
                    ApiEndpoints.subscriptionPlans,
                    data: {
                      'name': nameCtrl.text.trim(),
                      'price': double.tryParse(priceCtrl.text.trim()) ?? 0,
                      'durationMonths': int.tryParse(durationCtrl.text.trim()) ?? 1,
                      'maxBranches': int.tryParse(maxBranchesCtrl.text.trim()) ?? 3,
                      'maxAgents': int.tryParse(maxAgentsCtrl.text.trim()) ?? 10,
                      'maxCustomers': int.tryParse(maxCustCtrl.text.trim()) ?? 1000,
                    },
                  );
                  setSheetState(() => isSaving = false);

                  if (res.success) {
                    if (context.mounted) Navigator.pop(sheetCtx);
                    _fetchPlans();
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _fetchPlans,
        color: AppColors.primary,
        child: Column(
          children: [
            // Top Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SaaS Pricing Plans', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Media Wave Tech subscription packages', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _openCreatePlanBottomSheet,
                    icon: const Icon(AppIcons.packagePlus, size: 15, color: Colors.white),
                    label: const Text('Add Plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),

            // Plans List
            Expanded(
              child: _isLoading
                  ? const AppLoading(message: 'Loading subscription packages...')
                  : _plans.isEmpty
                      ? const AppEmptyState(
                          title: 'No Subscription Plans Defined',
                          subtitle: 'Create tiers like Starter, Growth & Enterprise.',
                          icon: AppIcons.creditCard,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _plans.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final plan = _plans[index];
                            final name = plan['name']?.toString() ?? 'Plan';
                            final price = (plan['price'] as num?)?.toDouble() ?? 0.0;
                            final duration = plan['durationMonths'] ?? 1;
                            final branches = plan['maxBranches'] ?? 1;
                            final agents = plan['maxAgents'] ?? 5;
                            final customers = plan['maxCustomers'] ?? 500;
                            final isPopular = index == 0;

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isPopular ? AppColors.primary : AppColors.border,
                                  width: isPopular ? 1.5 : 1,
                                ),
                                boxShadow: [
                                  if (isPopular)
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.08),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                                      Text(
                                        '${CurrencyFormatter.format(price)} / ${duration == 1 ? "mo" : "$duration mos"}',
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(color: AppColors.border, height: 1),
                                  const SizedBox(height: 12),

                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: [
                                      _buildFeatureItem(AppIcons.building, 'Up to $branches Branches'),
                                      _buildFeatureItem(AppIcons.userCheck, 'Up to $agents Field Agents'),
                                      _buildFeatureItem(AppIcons.users, 'Up to $customers Borrowers'),
                                      _buildFeatureItem(AppIcons.zap, 'Daily Sheet & Quick Collection'),
                                      _buildFeatureItem(AppIcons.messageCircle, 'WhatsApp Digital Receipts'),
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

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.success),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
