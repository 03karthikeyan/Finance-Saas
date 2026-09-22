import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_widgets.dart';

class ExpenseManagementScreen extends StatefulWidget {
  const ExpenseManagementScreen({super.key});

  @override
  State<ExpenseManagementScreen> createState() => _ExpenseManagementScreenState();
}

class _ExpenseManagementScreenState extends State<ExpenseManagementScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  Map<String, dynamic>? _cashbookData;
  List<dynamic> _expenses = [];
  List<dynamic> _agents = [];
  String _selectedFilter = 'ALL'; // ALL, EXPENSE, INJECTION, AGENT

  @override
  void initState() {
    super.initState();
    _loadData();
    _fetchAgents();
  }

  Future<void> _fetchAgents() async {
    try {
      final res = await _apiClient.get(ApiEndpoints.agents);
      if (res.success && res.data is List && mounted) {
        setState(() {
          _agents = res.data as List<dynamic>;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final summaryRes = await _apiClient.get('/expenses/cashbook-summary');
      final listRes = await _apiClient.get('/expenses');

      if (mounted) {
        setState(() {
          if (summaryRes.success && summaryRes.data is Map) {
            _cashbookData = summaryRes.data['data'] is Map ? summaryRes.data['data'] : summaryRes.data;
          }
          if (listRes.success && listRes.data is Map) {
            final d = listRes.data['data'];
            _expenses = (d is Map && d['expenses'] is List) ? d['expenses'] as List<dynamic> : [];
          } else if (listRes.success && listRes.data is List) {
            _expenses = listRes.data as List<dynamic>;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load cashbook data: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _showAddExpenseModal(BuildContext context, {bool isInjection = false}) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String category = isInjection ? 'CAPITAL_INVESTMENT' : 'PETROL';
    String paymentMethod = 'CASH';
    String? selectedAgentId;
    bool isSubmitting = false;

    AppBottomSheet.show(
      context: context,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AppBottomSheet(
            title: isInjection ? 'Record Cash Injection' : 'Log Operational Expense',
            subtitle: isInjection ? 'Add capital deposit or owner injection to cashbook' : 'Record field allowance, fuel, salary or office expenses',
            icon: isInjection ? AppIcons.arrowDownLeft : AppIcons.arrowUpRight,
            iconColor: isInjection ? AppColors.accentEmerald : AppColors.danger,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: isInjection ? 'Injection Source / Title *' : 'Expense Title *',
                    hintText: isInjection ? 'e.g. Owner Cash Deposit' : 'e.g. Daily Line Petrol Allowance',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount (₹) *',
                    prefixText: '₹ ',
                  ),
                ),
                const SizedBox(height: 12),
                if (!isInjection) ...[
                  // Category Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButton<String>(
                      value: category,
                      isExpanded: true,
                      dropdownColor: AppColors.surfaceElevated,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'PETROL', child: Text('⛽ Petrol / Fuel Allowance', style: TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                        DropdownMenuItem(value: 'DAILY_ALLOWANCE', child: Text('⚡ Daily Field Allowance', style: TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                        DropdownMenuItem(value: 'TEA_SNACKS', child: Text('☕ Tea / Refreshments', style: TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                        DropdownMenuItem(value: 'SALARY_ADVANCE', child: Text('💵 Agent Salary Advance / Bonus', style: TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                        DropdownMenuItem(value: 'SALARY', child: Text('💼 Monthly Base Salary Payout', style: TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                        DropdownMenuItem(value: 'OFFICE_RENT', child: Text('🏢 Office Rent / Electricity', style: TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                        DropdownMenuItem(value: 'STATIONERY', child: Text('📝 Paper, Passbooks & Printing', style: TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                        DropdownMenuItem(value: 'MISC', child: Text('📦 Other / Miscellaneous', style: TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => category = val);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Optional Field Officer Allocation Dropdown
                  if (_agents.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButton<String?>(
                        value: selectedAgentId,
                        isExpanded: true,
                        dropdownColor: AppColors.surfaceElevated,
                        underline: const SizedBox(),
                        hint: const Text('Assign to Field Officer (Optional)', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('🏢 General Company Expense (No Agent)', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          ),
                          ..._agents.map((ag) {
                            final agId = ag['_id']?.toString() ?? '';
                            final u = ag['userId'] as Map<String, dynamic>? ?? {};
                            final name = u['name']?.toString() ?? 'Agent';
                            final code = ag['agentCode']?.toString() ?? '';
                            return DropdownMenuItem<String?>(
                              value: agId,
                              child: Text('👤 $name ($code)', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                            );
                          }),
                        ],
                        onChanged: (val) => setModalState(() => selectedAgentId = val),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],

                // Payment Method Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButton<String>(
                    value: paymentMethod,
                    isExpanded: true,
                    dropdownColor: AppColors.surfaceElevated,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'CASH', child: Text('💵 Cash in Hand', style: TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                      DropdownMenuItem(value: 'UPI', child: Text('📱 UPI / Google Pay / PhonePe', style: TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                      DropdownMenuItem(value: 'BANK_TRANSFER', child: Text('🏦 Bank Account / NEFT', style: TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => paymentMethod = val);
                    },
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Remarks (Optional)',
                    hintText: 'e.g. Approved by Branch Head',
                  ),
                ),
                const SizedBox(height: 20),

                AppButton(
                  label: isInjection ? 'Save Cash Deposit' : 'Record Expense Log',
                  icon: AppIcons.check,
                  isLoading: isSubmitting,
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final amount = double.tryParse(amountController.text.trim());
                    if (title.isEmpty || amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter valid title and amount'), backgroundColor: AppColors.danger),
                      );
                      return;
                    }

                    setModalState(() => isSubmitting = true);
                    try {
                      final payload = <String, dynamic>{
                        'title': title,
                        'amount': amount,
                        'type': isInjection ? 'CASH_INJECTION' : 'EXPENSE',
                        'category': category,
                        'paymentMethod': paymentMethod,
                        'notes': notesController.text.trim(),
                        if (selectedAgentId != null) 'agentId': selectedAgentId,
                      };

                      final res = await _apiClient.post(ApiEndpoints.expenses, data: payload);
                      setModalState(() => isSubmitting = false);

                      if (res.success) {
                        if (context.mounted) {
                          Navigator.pop(sheetCtx);
                          _loadData();
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res.message), backgroundColor: AppColors.danger),
                          );
                        }
                      }
                    } catch (e) {
                      setModalState(() => isSubmitting = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to save entry: $e'), backgroundColor: AppColors.danger),
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
    final filteredList = _expenses.where((item) {
      if (_selectedFilter == 'EXPENSE') return item['type'] == 'EXPENSE';
      if (_selectedFilter == 'INJECTION') return item['type'] == 'CASH_INJECTION';
      if (_selectedFilter == 'AGENT') return item['agentId'] != null;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cashbook & Expense Logs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(AppIcons.refresh, size: 18),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddExpenseModal(context, isInjection: false),
        icon: const Icon(AppIcons.plus, color: Colors.white, size: 18),
        label: const Text('Add Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const AppLoading(message: 'Loading live cashbook...')
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cashbook Header Summary Card
                    _buildCashbookHeaderCard(),
                    const SizedBox(height: 16),

                    // Quick Action: Cash Injection Button
                    InkWell(
                      onTap: () => _showAddExpenseModal(context, isInjection: true),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.accentEmerald.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.accentEmerald.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(AppIcons.arrowDownLeft, size: 18, color: AppColors.accentEmerald),
                            const SizedBox(width: 8),
                            const Text(
                              '+ Add Capital / Cash Injection',
                              style: TextStyle(color: AppColors.accentEmerald, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Filter Capsules
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('ALL', 'All Entries (${_expenses.length})'),
                          const SizedBox(width: 8),
                          _buildFilterChip('EXPENSE', 'Expenses Only'),
                          const SizedBox(width: 8),
                          _buildFilterChip('AGENT', 'Field Officer Linked'),
                          const SizedBox(width: 8),
                          _buildFilterChip('INJECTION', 'Capital Injections'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Transactions & Vouchers',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          '${filteredList.length} items',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (filteredList.isEmpty)
                      const AppEmptyState(
                        title: 'No Transactions Found',
                        subtitle: 'Tap "+ Add Expense" or "+ Add Capital" to log your first voucher.',
                        icon: AppIcons.fileText,
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = filteredList[index];
                          final isExpense = item['type'] == 'EXPENSE';
                          final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
                          final title = item['title']?.toString() ?? 'Voucher';
                          final category = item['category']?.toString() ?? 'MISC';
                          final paymentMethod = item['paymentMethod']?.toString() ?? 'CASH';
                          final createdAt = item['createdAt']?.toString();
                          final agent = item['agentId'] as Map<String, dynamic>?;
                          final agentUser = agent != null ? agent['userId'] as Map<String, dynamic>? : null;
                          final agentName = agentUser?['name']?.toString();

                          String dateStr = '';
                          if (createdAt != null) {
                            try {
                              dateStr = DateFormat('dd MMM, hh:mm a').format(DateTime.parse(createdAt).toLocal());
                            } catch (_) {
                              dateStr = createdAt;
                            }
                          }

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isExpense
                                        ? AppColors.danger.withValues(alpha: 0.1)
                                        : AppColors.accentEmerald.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isExpense ? AppIcons.arrowUpRight : AppIcons.arrowDownLeft,
                                    color: isExpense ? AppColors.danger : AppColors.accentEmerald,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textPrimary),
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceCard,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: AppColors.border),
                                            ),
                                            child: Text(
                                              category.replaceAll('_', ' '),
                                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceCard,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              paymentMethod,
                                              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                            ),
                                          ),
                                          if (agentName != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.accentIndigo.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: AppColors.accentIndigo.withValues(alpha: 0.3)),
                                              ),
                                              child: Text(
                                                '👤 $agentName',
                                                style: const TextStyle(fontSize: 10, color: AppColors.accentIndigo, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (dateStr.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(dateStr, style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5)),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${isExpense ? '-' : '+'} ${CurrencyFormatter.format(amount)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isExpense ? AppColors.danger : AppColors.accentEmerald,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = key),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCashbookHeaderCard() {
    final netCash = (_cashbookData?['netCashInHand'] as num?)?.toDouble() ?? 0.0;
    final collections = (_cashbookData?['collections'] is Map
            ? (_cashbookData!['collections']['total'] as num?)?.toDouble()
            : (_cashbookData?['totalCollections'] as num?)?.toDouble()) ??
        0.0;
    final injections = (_cashbookData?['cashInjections'] as num?)?.toDouble() ?? 0.0;
    final expenses = (_cashbookData?['expenses'] as num?)?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'NET CASH IN HAND',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.activity, size: 12, color: AppColors.success),
                    SizedBox(width: 4),
                    Text(
                      'LIVE CASHBOOK',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            CurrencyFormatter.format(netCash),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat('Collections', CurrencyFormatter.format(collections), AppColors.accentEmerald),
              _buildMiniStat('Injections', CurrencyFormatter.format(injections), AppColors.accentCyan),
              _buildMiniStat('Expenses', CurrencyFormatter.format(expenses), AppColors.warning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10.5)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(color: color, fontSize: 13.5, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
