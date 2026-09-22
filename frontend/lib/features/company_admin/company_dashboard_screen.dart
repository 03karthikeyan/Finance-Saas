import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_widgets.dart';
import '../layout/branch_cubit.dart';
import '../reports/reports_screen.dart';
import '../agents/agent_route_map_screen.dart';
import '../agents/agent_salary_screen.dart';
import '../agents/agent_list_screen.dart';

class CompanyDashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToCollections;
  final VoidCallback? onNavigateToDisburse;
  final VoidCallback? onNavigateToCustomers;

  const CompanyDashboardScreen({
    super.key,
    this.onNavigateToCollections,
    this.onNavigateToDisburse,
    this.onNavigateToCustomers,
  });

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  String? _errorMessage;
  String? _lastLoadedBranchId = 'INIT';

  Map<String, dynamic>? _metrics;
  List<dynamic>? _weeklyTrends;
  List<dynamic>? _todaySheet;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData([String? branchIdOverride]) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final branchId = branchIdOverride ??
        (mounted ? context.read<BranchCubit>().state.activeBranchId : null);
    _lastLoadedBranchId = branchId;

    try {
      final query = <String, dynamic>{
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
      };

      final metricsRes = await _apiClient.get(ApiEndpoints.companyDashboard, queryParameters: query);
      final weeklyRes = await _apiClient.get(ApiEndpoints.reportWeekly, queryParameters: query);
      final sheetRes = await _apiClient.get(ApiEndpoints.todayCollectionSheet, queryParameters: query);

      if (metricsRes.success && metricsRes.data != null) {
        if (mounted) {
          setState(() {
            _metrics = metricsRes.data as Map<String, dynamic>;
            _weeklyTrends = (weeklyRes.data is Map && (weeklyRes.data as Map)['trends'] is List)
                ? (weeklyRes.data as Map)['trends'] as List<dynamic>
                : [];
            _todaySheet = sheetRes.data is List ? sheetRes.data as List<dynamic> : [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = metricsRes.message;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load dashboard: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchState = context.watch<BranchCubit>().state;
    final currentBranchId = branchState.activeBranchId;

    // Trigger reload when active branch changes
    if (_lastLoadedBranchId != 'INIT' && _lastLoadedBranchId != currentBranchId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fetchDashboardData(currentBranchId);
      });
    }

    if (_isLoading) {
      return const AppLoading(message: 'Loading live financial dashboard...');
    }

    if (_errorMessage != null) {
      return AppEmptyState(
        title: 'Unable to Load Dashboard',
        subtitle: _errorMessage,
        icon: AppIcons.alertCircle,
        action: AppButton(label: 'Retry', onPressed: () => _fetchDashboardData(currentBranchId)),
      );
    }

    final m = _metrics ?? {};
    final totalCustomers = m['totalCustomers'] ?? 0;
    final activeAccounts = m['activeFinanceAccounts'] ?? 0;
    final todayCollected = (m['todayCollectedAmount'] as num?)?.toDouble() ?? 0.0;
    final todayTxCount = m['todayTransactionsCount'] ?? 0;
    final totalDisbursed = (m['totalPrincipalDisbursed'] as num?)?.toDouble() ?? 0.0;
    final totalOutstanding = (m['totalOutstandingAmount'] as num?)?.toDouble() ?? 0.0;
    final activeAgents = m['activeAgents'] ?? 0;

    final isDesktop = MediaQuery.of(context).size.width >= 750;

    return RefreshIndicator(
      onRefresh: () => _fetchDashboardData(currentBranchId),
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceElevated,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Branch Indicator Capsule if specific branch is selected
            if (!branchState.isAllBranches) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(AppIcons.building, size: 14, color: AppColors.accentCyan),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Filtered View: ${branchState.activeBranchName} ${branchState.activeBranchDistrict != null ? "(${branchState.activeBranchDistrict})" : ""}',
                        style: const TextStyle(
                          color: AppColors.accentCyan,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Hero Collection Target Banner
            HeroTargetCard(
              title: "TODAY'S OPERATIONS",
              collectedAmount: todayCollected,
              targetAmount: todayCollected > 0 ? todayCollected * 1.3 : 25000,
              completedTransactions: todayTxCount,
              onQuickCollect: widget.onNavigateToCollections,
              onViewDetails: () => TodayCollectionActivitySheet.show(context),
            ),
            const SizedBox(height: 20),

            // Android Quick Action Grid (4 Actions)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  QuickActionButton(
                    label: 'Collect',
                    icon: AppIcons.zap,
                    color: AppColors.primary,
                    onTap: widget.onNavigateToCollections,
                  ),
                  QuickActionButton(
                    label: 'Disburse',
                    icon: AppIcons.arrowUpRight,
                    color: AppColors.info,
                    onTap: widget.onNavigateToDisburse,
                  ),
                  QuickActionButton(
                    label: 'Borrower',
                    icon: AppIcons.userPlus,
                    color: AppColors.accentIndigo,
                    onTap: widget.onNavigateToCustomers,
                  ),
                  QuickActionButton(
                    label: 'Day Report',
                    icon: AppIcons.barChart3,
                    color: AppColors.warning,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => Scaffold(
                            backgroundColor: AppColors.background,
                            appBar: AppBar(
                              backgroundColor: AppColors.surface,
                              elevation: 0,
                              title: const Text('Financial Reports', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              leading: IconButton(
                                icon: const Icon(AppIcons.chevronLeft),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ),
                            body: const ReportsScreen(),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2-Column Responsive Metric Grid
            GridView.count(
              crossAxisCount: isDesktop ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isDesktop ? 1.5 : 1.15,
              children: [
                StatMetricCard(
                  title: 'Active Accounts',
                  value: activeAccounts.toString(),
                  subtitle: '$totalCustomers borrowers',
                  icon: AppIcons.wallet,
                  iconColor: AppColors.primary,
                  onTap: widget.onNavigateToDisburse,
                ),
                StatMetricCard(
                  title: 'Total Outstanding',
                  value: CurrencyFormatter.format(totalOutstanding),
                  subtitle: 'Across active lines',
                  icon: AppIcons.clock,
                  iconColor: AppColors.warning,
                ),
                StatMetricCard(
                  title: 'Total Disbursed',
                  value: CurrencyFormatter.format(totalDisbursed),
                  subtitle: 'Principal volume',
                  icon: AppIcons.trendingUp,
                  iconColor: AppColors.info,
                ),
                StatMetricCard(
                  title: 'Field Agents',
                  value: activeAgents.toString(),
                  subtitle: 'Active staff',
                  icon: AppIcons.userCheck,
                  iconColor: AppColors.accentPurple,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 7-Day Inflow Trends Chart
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        '7-Day Collection Inflow',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Daily (₹)',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 180,
                    child: _buildWeeklyChart(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Today's Due Installments Queue
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Today's Due Installments",
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_todaySheet?.length ?? 0} Due',
                          style: const TextStyle(
                            color: AppColors.warning,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_todaySheet == null || _todaySheet!.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No pending installments for today! 🎉',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _todaySheet!.length > 5 ? 5 : _todaySheet!.length,
                      separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 12),
                      itemBuilder: (context, idx) {
                        final item = _todaySheet![idx];
                        final cust = item['customer'] as Map<String, dynamic>?;
                        final custName = cust?['name'] ?? 'Borrower';
                        final amount = item['installmentAmount'] ?? 0;
                        final accNo = item['accountNumber'] ?? '';
                        final freq = item['frequency'] ?? 'DAILY';

                        return InkWell(
                          onTap: widget.onNavigateToCollections,
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                  child: Text(
                                    custName.isNotEmpty ? custName[0].toUpperCase() : 'B',
                                    style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        custName,
                                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        accNo,
                                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      CurrencyFormatter.format(amount),
                                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    StatusBadge(status: freq, isSmall: true),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Field Agent Live Operations & Quick Hub
            _buildAgentOperationsCard(activeAgents),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentOperationsCard(int activeAgentsCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentIndigo.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(AppIcons.navigation, color: AppColors.accentIndigo, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FIELD OPERATIONS & ROUTES',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '$activeAgentsCount Active Field Officers',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(AppIcons.users, size: 18, color: AppColors.primary),
                tooltip: 'All Officers',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AgentListScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AgentRouteMapScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(AppIcons.mapPin, size: 16, color: AppColors.accentIndigo),
                        SizedBox(width: 8),
                        Text(
                          'Live Route Map',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AgentSalaryScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(AppIcons.wallet, size: 16, color: AppColors.accentEmerald),
                        SizedBox(width: 8),
                        Text(
                          'Salary & Allowances',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    if (_weeklyTrends == null || _weeklyTrends!.isEmpty) {
      return const Center(
        child: Text('No transaction history yet', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < _weeklyTrends!.length; i++) {
      final item = _weeklyTrends![i];
      final val = (item['amount'] as num?)?.toDouble() ?? 0.0;
      spots.add(FlSpot(i.toDouble(), val));
    }

    if (spots.length == 1) {
      spots.insert(0, const FlSpot(0, 0));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => const FlLine(color: AppColors.border, strokeWidth: 0.8),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx >= 0 && idx < _weeklyTrends!.length) {
                  final raw = _weeklyTrends![idx]['date']?.toString() ?? '';
                  final parts = raw.split('-');
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      parts.length >= 3 ? '${parts[2]}/${parts[1]}' : raw,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (val, meta) {
                return Text(
                  val >= 1000 ? '₹${(val / 1000).toStringAsFixed(0)}k' : '₹${val.toInt()}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 2.8,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.25),
                  AppColors.primary.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
