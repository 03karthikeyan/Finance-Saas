import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/customer_loan_schedule_sheet.dart';

class CustomerLoansScreen extends StatefulWidget {
  const CustomerLoansScreen({super.key});

  @override
  State<CustomerLoansScreen> createState() => _CustomerLoansScreenState();
}

class _CustomerLoansScreenState extends State<CustomerLoansScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _activeAccounts = [];
  List<dynamic> _completedAccounts = [];
  List<dynamic> _allAccounts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadLoans();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLoans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiClient().get(ApiEndpoints.customerPortal);

      if (res.success && res.data is Map<String, dynamic>) {
        final data = Map<String, dynamic>.from(res.data as Map<String, dynamic>);
        final active = data['activeAccounts'] as List<dynamic>? ?? [];
        final completed = data['completedAccounts'] as List<dynamic>? ?? [];

        if (mounted) {
          setState(() {
            _activeAccounts = active;
            _completedAccounts = completed;
            _allAccounts = [...active, ...completed];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = res.message.isNotEmpty ? res.message : 'Failed to load loans';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Network error: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _showScheduleModal(Map<String, dynamic> account) {
    final accId = account['_id']?.toString() ?? account['id']?.toString() ?? '';
    if (accId.isEmpty) return;

    CustomerLoanScheduleSheet.show(
      context,
      accountId: accId,
      accountSummary: account,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: const Row(
          children: [
            Icon(AppIcons.wallet, size: 20, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'My Loan Accounts',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadLoans,
            icon: const Icon(AppIcons.refreshCw, size: 18, color: AppColors.textSecondary),
            tooltip: 'Refresh Loans',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 14),
                  Text('Loading your loan accounts...', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(AppIcons.alertCircle, color: AppColors.danger, size: 44),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadLoans,
                          icon: const Icon(AppIcons.refreshCw, size: 15),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: _buildPortfolioHeroBanner(),
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SliverTabBarDelegate(
                          child: Container(
                            color: AppColors.background,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: _buildModernTabBar(),
                          ),
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLoanList(_allAccounts),
                      _buildLoanList(_activeAccounts),
                      _buildLoanList(_completedAccounts),
                    ],
                  ),
                ),
    );
  }

  // -------------------------------------------------------------
  // 1. HERO PORTFOLIO OVERVIEW CARD
  // -------------------------------------------------------------
  Widget _buildPortfolioHeroBanner() {
    double totalBorrowed = 0;
    double totalPayable = 0;
    double totalPaid = 0;
    double totalOutstanding = 0;

    for (final raw in _allAccounts) {
      if (raw is! Map) continue;
      final acc = raw as Map<String, dynamic>;
      totalBorrowed += (acc['principalAmount'] as num?)?.toDouble() ?? 0.0;
      totalPayable += (acc['totalPayableAmount'] as num?)?.toDouble() ?? 0.0;
      totalPaid += (acc['totalPaidAmount'] as num?)?.toDouble() ?? 0.0;
      totalOutstanding += (acc['remainingAmount'] as num?)?.toDouble() ?? 0.0;
    }

    final paidRatio = (totalPayable > 0) ? (totalPaid / totalPayable).clamp(0.0, 1.0) : 0.0;
    final paidPercent = (paidRatio * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(AppIcons.trendingUp, color: Color(0xFF38BDF8), size: 16),
                  SizedBox(width: 6),
                  Text(
                    'PORTFOLIO SUMMARY',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_activeAccounts.length} Active • ${_completedAccounts.length} Closed',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                CurrencyFormatter.format(totalOutstanding),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Pending Balance',
                style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: paidRatio,
              minHeight: 6.5,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4ADE80)),
            ),
          ),
          const SizedBox(height: 12),

          // 2 Column Stats
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Borrowed', style: TextStyle(color: Colors.white60, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(totalBorrowed),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 26, color: Colors.white.withValues(alpha: 0.15)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Repaid ($paidPercent%)', style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(totalPaid),
                      style: const TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. MODERN PROFESSIONAL PILL TAB BAR
  // -------------------------------------------------------------
  Widget _buildModernTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
        tabs: [
          Tab(
            height: 38,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(AppIcons.layers, size: 14),
                const SizedBox(width: 5),
                Text('All (${_allAccounts.length})'),
              ],
            ),
          ),
          Tab(
            height: 38,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(AppIcons.zap, size: 14),
                const SizedBox(width: 5),
                Text('Active (${_activeAccounts.length})'),
              ],
            ),
          ),
          Tab(
            height: 38,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(AppIcons.checkCircle2, size: 14),
                const SizedBox(width: 5),
                Text('Closed (${_completedAccounts.length})'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 3. LOAN CARDS LIST VIEW
  // -------------------------------------------------------------
  Widget _buildLoanList(List<dynamic> accounts) {
    if (accounts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(AppIcons.wallet, size: 36, color: AppColors.primary),
              ),
              const SizedBox(height: 14),
              const Text(
                'No loan accounts in this category',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your disbursed loan accounts and historical ledgers will appear here.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLoans,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: accounts.length,
        itemBuilder: (context, index) {
          final acc = accounts[index] as Map<String, dynamic>;
          final accNumber = acc['accountNumber']?.toString() ?? 'FIN-LOAN';
          final principal = (acc['principalAmount'] as num?)?.toDouble() ?? 0.0;
          final totalPayable = (acc['totalPayableAmount'] as num?)?.toDouble() ?? principal;
          final paid = (acc['totalPaidAmount'] as num?)?.toDouble() ?? 0.0;
          final remaining = (acc['remainingAmount'] as num?)?.toDouble() ?? (totalPayable - paid);
          final emi = (acc['installmentAmount'] as num?)?.toDouble() ?? 0.0;
          final totalInst = acc['totalInstallments'] ?? 0;
          final paidInst = acc['paidInstallments'] ?? 0;
          final freq = acc['frequency']?.toString() ?? 'DAILY';
          final status = acc['status']?.toString() ?? 'ACTIVE';
          final productName = acc['productId'] is Map
              ? (acc['productId']['name']?.toString() ?? 'Standard Finance Loan')
              : 'Standard Finance Loan';
          final startDateStr = acc['startDate']?.toString();
          final startDate = startDateStr != null ? DateTime.tryParse(startDateStr) : null;
          final endDateStr = acc['endDate']?.toString();
          final endDate = endDateStr != null ? DateTime.tryParse(endDateStr) : null;

          final ratio = totalPayable > 0 ? (paid / totalPayable).clamp(0.0, 1.0) : 0.0;
          final isCompleted = status == 'COMPLETED';

          Color freqColor = AppColors.accentCyan;
          if (freq == 'WEEKLY') freqColor = AppColors.accentIndigo;
          if (freq == 'MONTHLY') freqColor = AppColors.warning;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isCompleted ? AppColors.success.withValues(alpha: 0.3) : AppColors.border,
                width: isCompleted ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Card Strip
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.success.withValues(alpha: 0.04)
                        : AppColors.surfaceCard,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  accNumber,
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: freqColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    freq,
                                    style: TextStyle(color: freqColor, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              productName,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(status: status, isSmall: true),
                    ],
                  ),
                ),
                const Divider(color: AppColors.border, height: 1),

                // Financial Tiles Grid (Principal, Total Paid, Remaining)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              label: 'Principal',
                              value: CurrencyFormatter.format(principal),
                              subValue: 'EMI: ${CurrencyFormatter.format(emi)}',
                              icon: AppIcons.wallet,
                              color: AppColors.textPrimary,
                              bgColor: AppColors.surfaceCard,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricTile(
                              label: 'Total Paid',
                              value: CurrencyFormatter.format(paid),
                              subValue: '$paidInst / $totalInst Paid',
                              icon: AppIcons.checkCircle2,
                              color: AppColors.success,
                              bgColor: AppColors.success.withValues(alpha: 0.08),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricTile(
                              label: isCompleted ? 'Status' : 'Remaining',
                              value: isCompleted ? 'CLEARED' : CurrencyFormatter.format(remaining),
                              subValue: isCompleted ? 'All Paid' : '${totalInst - paidInst} Dues Left',
                              icon: isCompleted ? AppIcons.shieldCheck : AppIcons.alertCircle,
                              color: isCompleted ? AppColors.success : AppColors.danger,
                              bgColor: isCompleted ? AppColors.success.withValues(alpha: 0.08) : AppColors.danger.withValues(alpha: 0.08),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Progress Bar & Percentage
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Repayment Progress',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                          Text(
                            '${(ratio * 100).toStringAsFixed(1)}% Completed',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isCompleted ? AppColors.success : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 7,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isCompleted ? AppColors.success : AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Start Date & End Date Row
                      if (startDate != null || endDate != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(AppIcons.calendar, size: 13, color: AppColors.textMuted),
                                  const SizedBox(width: 5),
                                  Text(
                                    startDate != null ? 'Start: ${DateFormat('dd MMM yyyy').format(startDate)}' : 'Started',
                                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(AppIcons.clock, size: 13, color: AppColors.textMuted),
                                  const SizedBox(width: 5),
                                  Text(
                                    endDate != null ? 'End: ${DateFormat('dd MMM yyyy').format(endDate)}' : 'Maturity',
                                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Full Schedule Action Button
                      ElevatedButton(
                        onPressed: () => _showScheduleModal(acc),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 1,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(AppIcons.calendar, size: 16, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'View Full Repayment Schedule',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                            ),
                            SizedBox(width: 4),
                            Icon(AppIcons.chevronRight, size: 16, color: Colors.white70),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String subValue,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12.5),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subValue,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 9.5),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// SLIVER TAB BAR DELEGATE
// -------------------------------------------------------------
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SliverTabBarDelegate({required this.child});

  @override
  double get minExtent => 54;
  @override
  double get maxExtent => 54;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}


