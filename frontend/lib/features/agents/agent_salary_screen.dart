import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';

class AgentSalaryScreen extends StatefulWidget {
  final String? agentId; // null = self (agent viewing own), set = admin viewing specific agent
  final String? agentName;
  const AgentSalaryScreen({super.key, this.agentId, this.agentName});

  @override
  State<AgentSalaryScreen> createState() => _AgentSalaryScreenState();
}

class _AgentSalaryScreenState extends State<AgentSalaryScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final id = widget.agentId ?? 'me';
      final res = await ApiClient().get(ApiEndpoints.agentSalaryHistory(id));
      if (res.success && res.data is Map) {
        if (mounted) setState(() { _data = res.data as Map<String, dynamic>; _isLoading = false; });
        return;
      }

      // Fallback: Compute salary ledger directly from expenses if server route is still syncing
      final expenseRes = await ApiClient().get('/expenses?limit=100');
      final profileRes = await ApiClient().get('/agents/me');

      double monthlySalary = 0.0;
      if (profileRes.success && profileRes.data is Map) {
        final d = profileRes.data as Map<String, dynamic>;
        monthlySalary = (d['monthlySalary'] as num?)?.toDouble() ?? 0.0;
      }

      List<dynamic> expenseList = [];
      if (expenseRes.success && expenseRes.data is Map) {
        final d = expenseRes.data as Map<String, dynamic>;
        expenseList = (d['expenses'] is List) ? d['expenses'] as List<dynamic> : [];
      } else if (expenseRes.success && expenseRes.data is List) {
        expenseList = expenseRes.data as List<dynamic>;
      }

      // Group into monthly buckets
      final Map<String, Map<String, dynamic>> monthlyMap = {};
      for (final item in expenseList) {
        if (item is! Map<String, dynamic>) continue;
        final dateStr = item['date']?.toString() ?? '';
        final dt = DateTime.tryParse(dateStr) ?? DateTime.now();
        final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';

        if (!monthlyMap.containsKey(key)) {
          monthlyMap[key] = {
            'month': key,
            'salary': 0.0,
            'advance': 0.0,
            'allowance': 0.0,
            'fuel': 0.0,
            'cashHandover': 0.0,
            'entries': <Map<String, dynamic>>[],
          };
        }

        final m = monthlyMap[key]!;
        final type = item['type']?.toString() ?? 'EXPENSE';
        final category = item['category']?.toString() ?? 'MISC';
        final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;

        if (type == 'CASH_INJECTION') {
          m['cashHandover'] = (m['cashHandover'] as double) + amount;
        } else if (category == 'SALARY') {
          m['salary'] = (m['salary'] as double) + amount;
        } else if (category == 'SALARY_ADVANCE') {
          m['advance'] = (m['advance'] as double) + amount;
        } else if (category == 'PETROL' || category == 'FUEL') {
          m['fuel'] = (m['fuel'] as double) + amount;
        } else {
          m['allowance'] = (m['allowance'] as double) + amount;
        }

        (m['entries'] as List).add(item);
      }

      final historyList = monthlyMap.values.toList()
        ..sort((a, b) => (b['month']?.toString() ?? '').compareTo(a['month']?.toString() ?? ''));

      if (mounted) {
        setState(() {
          _data = {
            'monthlySalary': monthlySalary,
            'history': historyList,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthlySalary = (_data?['monthlySalary'] as num?)?.toDouble() ?? 0.0;
    final history = (_data?['history'] as List?) ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.agentName != null ? '${widget.agentName} - Salary' : 'My Salary Ledger',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const Text('Monthly salary & cash handover history', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.primary), onPressed: _load),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.textMuted)))
              : Column(
                  children: [
                    // Header Card
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppColors.heroGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: AppColors.primaryDark.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                            child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Fixed Monthly Salary', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              Text(CurrencyFormatter.format(monthlySalary),
                                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                              Text('${history.length} months of history', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // History list
                    Expanded(
                      child: history.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long_outlined, size: 52, color: AppColors.textMuted),
                                  SizedBox(height: 12),
                                  Text('No salary or allowance records yet.', style: TextStyle(color: AppColors.textMuted)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: history.length,
                              itemBuilder: (context, i) {
                                final month = history[i] as Map<String, dynamic>;
                                final monthKey = month['month']?.toString() ?? '';
                                final salary = (month['salary'] as num?)?.toDouble() ?? 0.0;
                                final advance = (month['advance'] as num?)?.toDouble() ?? 0.0;
                                final handover = (month['cashHandover'] as num?)?.toDouble() ?? 0.0;
                                final entries = (month['entries'] as List?) ?? [];

                                DateTime? dt;
                                try { dt = DateTime.parse('$monthKey-01'); } catch (_) {}
                                final displayMonth = dt != null ? DateFormat('MMMM yyyy').format(dt) : monthKey;
                                final totalPaid = salary + advance + handover;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.border),
                                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                                  ),
                                  child: Theme(
                                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                    child: ExpansionTile(
                                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                      childrenPadding: EdgeInsets.zero,
                                      leading: Container(
                                        width: 40, height: 40,
                                        decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(10)),
                                        child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 20),
                                      ),
                                      title: Text(displayMonth, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                                      subtitle: Text('Total Paid: ${CurrencyFormatter.format(totalPaid)}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                      trailing: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(CurrencyFormatter.format(totalPaid), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.success)),
                                          Text('${entries.length} entries', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                        ],
                                      ),
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            children: [
                                              if (salary > 0) _ledgerRow('Salary', salary, AppColors.success),
                                              if (advance > 0) _ledgerRow('Salary Advance', advance, AppColors.warning),
                                              if (handover > 0) _ledgerRow('Cash Handover', handover, AppColors.accentCyan),
                                              if (entries.isNotEmpty) ...[
                                                const Divider(height: 16),
                                                ...entries.map((e) {
                                                  final en = e as Map<String, dynamic>;
                                                  final eDate = en['date'] != null ? DateFormat('dd MMM').format(DateTime.tryParse(en['date'].toString()) ?? DateTime.now()) : '';
                                                  return Padding(
                                                    padding: const EdgeInsets.only(bottom: 4),
                                                    child: Row(children: [
                                                      const Icon(Icons.fiber_manual_record, size: 6, color: AppColors.textMuted),
                                                      const SizedBox(width: 8),
                                                      Expanded(child: Text(en['title']?.toString() ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
                                                      Text(eDate, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                                      const SizedBox(width: 8),
                                                      Text(CurrencyFormatter.format((en['amount'] as num?)?.toDouble() ?? 0.0),
                                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                                    ]),
                                                  );
                                                }),
                                              ],
                                            ],
                                          ),
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
    );
  }

  Widget _ledgerRow(String label, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          ]),
          Text(CurrencyFormatter.format(amount), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

