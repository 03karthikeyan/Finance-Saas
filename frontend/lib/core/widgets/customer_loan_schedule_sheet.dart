import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/api_endpoints.dart';
import '../constants/app_colors.dart';
import '../constants/app_icons.dart';
import '../network/api_client.dart';
import '../utils/formatters.dart';

class CustomerLoanScheduleSheet extends StatefulWidget {
  final String accountId;
  final Map<String, dynamic> accountSummary;
  final bool isAgent;
  final Function(Map<String, dynamic> item)? onCollectPressed;

  const CustomerLoanScheduleSheet({
    super.key,
    required this.accountId,
    required this.accountSummary,
    this.isAgent = false,
    this.onCollectPressed,
  });

  static void show(
    BuildContext context, {
    required String accountId,
    required Map<String, dynamic> accountSummary,
    bool isAgent = false,
    Function(Map<String, dynamic> item)? onCollectPressed,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: Colors.black.withValues(alpha: 0.70),
      backgroundColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      builder: (ctx) => CustomerLoanScheduleSheet(
        accountId: accountId,
        accountSummary: accountSummary,
        isAgent: isAgent,
        onCollectPressed: onCollectPressed,
      ),
    );
  }

  @override
  State<CustomerLoanScheduleSheet> createState() => _CustomerLoanScheduleSheetState();
}

class _CustomerLoanScheduleSheetState extends State<CustomerLoanScheduleSheet> {
  bool _isLoading = true;
  List<dynamic> _schedule = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    try {
      // 1. Primary: Try Customer Portal Schedule endpoint
      final endpoint = '${ApiEndpoints.customerPortalSchedule}/${widget.accountId}/schedule';
      var res = await ApiClient().get(endpoint);

      if (res.success && res.data is Map<String, dynamic>) {
        final data = res.data as Map<String, dynamic>;
        final list = (data['schedule'] ?? data['installments']) as List<dynamic>? ?? [];
        if (mounted && list.isNotEmpty) {
          setState(() {
            _schedule = list;
            _isLoading = false;
          });
          return;
        }
      }

      // 2. Secondary: Try standard finance account endpoint (for agent/admin)
      try {
        res = await ApiClient().get('${ApiEndpoints.financeAccounts}/${widget.accountId}');
        if (res.success && res.data is Map<String, dynamic>) {
          final data = res.data as Map<String, dynamic>;
          final list = (data['installments'] ?? data['schedule']) as List<dynamic>? ?? [];
          if (mounted && list.isNotEmpty) {
            setState(() {
              _schedule = list;
              _isLoading = false;
            });
            return;
          }
        }
      } catch (_) {}

      // 3. Fallback: Generate dynamic schedule if empty
      _generateFallbackSchedule();
    } catch (e) {
      _generateFallbackSchedule();
    }
  }

  void _generateFallbackSchedule() {
    final acc = widget.accountSummary;
    final totalInst = (acc['totalInstallments'] as num?)?.toInt() ?? 100;
    final instAmount = (acc['installmentAmount'] as num?)?.toDouble() ?? 
        (((acc['totalPayableAmount'] as num?)?.toDouble() ?? 0) / (totalInst > 0 ? totalInst : 1));
    final paidInstCount = (acc['paidInstallments'] as num?)?.toInt() ?? 0;
    final freq = acc['frequency']?.toString() ?? 'DAILY';
    final startDateStr = acc['startDate']?.toString();
    DateTime currDate = startDateStr != null ? (DateTime.tryParse(startDateStr) ?? DateTime.now()) : DateTime.now();

    final List<Map<String, dynamic>> fallbackList = [];
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    for (int i = 1; i <= totalInst; i++) {
      if (freq == 'WEEKLY') {
        currDate = currDate.add(const Duration(days: 7));
      } else if (freq == 'MONTHLY') {
        currDate = DateTime(currDate.year, currDate.month + 1, currDate.day);
      } else {
        currDate = currDate.add(const Duration(days: 1));
      }

      final isPaid = i <= paidInstCount;
      final instDateStart = DateTime(currDate.year, currDate.month, currDate.day);
      final isOverdue = !isPaid && instDateStart.isBefore(todayStart);

      fallbackList.add({
        'installmentNumber': i,
        'dueDate': currDate.toIso8601String(),
        'expectedAmount': instAmount,
        'paidAmount': isPaid ? instAmount : 0.0,
        'remainingAmount': isPaid ? 0.0 : instAmount,
        'status': isPaid ? 'PAID' : (isOverdue ? 'OVERDUE' : 'UPCOMING'),
      });
    }

    if (mounted) {
      setState(() {
        _schedule = fallbackList;
        _isLoading = false;
        _error = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accNumber = widget.accountSummary['accountNumber']?.toString() ?? 'Loan Account';
    final totalPayable = (widget.accountSummary['totalPayableAmount'] as num?)?.toDouble() ?? 
        ((widget.accountSummary['principalAmount'] as num?)?.toDouble() ?? 10000.0);
    final totalInstallments = widget.accountSummary['totalInstallments'] ?? 100;

    int paidCount = 0;
    double paidTotal = 0.0;
    int overdueCount = 0;
    double overdueTotal = 0.0;
    int dueTodayCount = 0;
    double dueTodayTotal = 0.0;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    for (final raw in _schedule) {
      if (raw is! Map) continue;
      final st = raw['status']?.toString().toUpperCase() ?? '';
      final expected = (raw['expectedAmount'] as num?)?.toDouble() ?? 
          (raw['amount'] as num?)?.toDouble() ?? 0.0;
      final paid = (raw['paidAmount'] as num?)?.toDouble() ?? 0.0;
      final dueStr = raw['dueDate']?.toString();
      final dueDate = dueStr != null ? DateTime.tryParse(dueStr) : null;

      if (st == 'PAID') {
        paidCount++;
        paidTotal += (paid > 0 ? paid : expected);
      } else {
        if (dueDate != null) {
          if (dueDate.isBefore(todayStart)) {
            overdueCount++;
            overdueTotal += (expected - paid);
          } else if (!dueDate.isAfter(todayEnd)) {
            dueTodayCount++;
            dueTodayTotal += (expected - paid);
          }
        }
      }
    }

    final totalPendingAmount = math.max(0.0, totalPayable - paidTotal);
    final pendingOverdueAndToday = overdueTotal + dueTodayTotal;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      accNumber,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    Text(
                      'Total Payable: ${CurrencyFormatter.format(totalPayable)} • $totalInstallments Installments',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(AppIcons.x, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Summary Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  _buildStatCell('Paid ($paidCount)', CurrencyFormatter.format(paidTotal), AppColors.success),
                  _buildStatCell('Overdue ($overdueCount)', CurrencyFormatter.format(overdueTotal), AppColors.danger),
                  _buildStatCell('Due Today ($dueTodayCount)', CurrencyFormatter.format(dueTodayTotal), AppColors.warning),
                  _buildStatCell('Pending', CurrencyFormatter.format(totalPendingAmount), AppColors.textPrimary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Installments List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _schedule.isEmpty
                    ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.danger)))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _schedule.length,
                        separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
                        itemBuilder: (ctx, idx) {
                          final item = _schedule[idx] as Map<String, dynamic>;
                          final instNum = item['installmentNumber'] ?? (idx + 1);
                          final expected = (item['expectedAmount'] as num?)?.toDouble() ?? 
                              (item['amount'] as num?)?.toDouble() ?? 0.0;
                          final status = item['status']?.toString().toUpperCase() ?? 'UPCOMING';
                          final dueStr = item['dueDate']?.toString();
                          final dueDate = dueStr != null ? DateTime.tryParse(dueStr) : null;

                          final isPaid = status == 'PAID';
                          final isOverdue = status == 'OVERDUE' || (!isPaid && dueDate != null && dueDate.isBefore(todayStart));
                          final isDueToday = !isPaid && !isOverdue && dueDate != null && !dueDate.isAfter(todayEnd);

                          String statusLabel = 'UPCOMING';
                          Color statusColor = AppColors.textMuted;
                          IconData statusIcon = Icons.circle_outlined;

                          if (isPaid) {
                            statusLabel = 'PAID';
                            statusColor = AppColors.success;
                            statusIcon = Icons.check_circle;
                          } else if (isOverdue) {
                            int daysOverdue = dueDate != null ? todayStart.difference(DateTime(dueDate.year, dueDate.month, dueDate.day)).inDays : 1;
                            if (daysOverdue <= 0) daysOverdue = 1;
                            statusLabel = 'OVERDUE (${daysOverdue}d)';
                            statusColor = AppColors.danger;
                            statusIcon = Icons.error_outline;
                          } else if (isDueToday) {
                            statusLabel = 'DUE TODAY';
                            statusColor = AppColors.warning;
                            statusIcon = Icons.access_time;
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: statusColor.withValues(alpha: 0.12),
                                  child: Icon(statusIcon, size: 16, color: statusColor),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Installment #$instNum',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textPrimary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dueDate != null ? 'Due ${DateFormat('dd MMM yyyy').format(dueDate)}' : 'Scheduled',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      CurrencyFormatter.format(expected),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: TextStyle(color: statusColor, fontSize: 9.5, fontWeight: FontWeight.w800),
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

          // Bottom Action Bar for Agent (Collect Pending Button)
          if (widget.isAgent && pendingOverdueAndToday > 0)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(AppIcons.coins, color: Colors.white, size: 18),
                  label: Text(
                    'Collect Pending (₹${pendingOverdueAndToday.toInt()})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    if (widget.onCollectPressed != null) {
                      widget.onCollectPressed!(widget.accountSummary);
                    }
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCell(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
