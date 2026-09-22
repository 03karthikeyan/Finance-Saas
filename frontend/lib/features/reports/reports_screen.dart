import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();
  late TabController _tabController;
  bool _isLoading = true;

  Map<String, dynamic>? _dailyReport;
  List<dynamic>? _agentReport;
  List<dynamic>? _defaultersReport;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    try {
      final dailyRes = await _apiClient.get(ApiEndpoints.reportDaily);
      final agentRes = await _apiClient.get(ApiEndpoints.reportAgents);
      final defRes = await _apiClient.get(ApiEndpoints.reportDefaulters);

      setState(() {
        _dailyReport = dailyRes.data is Map ? dailyRes.data as Map<String, dynamic> : null;
        _agentReport = agentRes.data is List ? agentRes.data as List<dynamic> : [];
        _defaultersReport = defRes.data is List ? defRes.data as List<dynamic> : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _exportCsv() async {
    final url = Uri.parse('${_apiClient.dio.options.baseUrl}${ApiEndpoints.exportCsv}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _fetchReports,
        color: AppColors.primary,
        child: Column(
          children: [
            // Top Tab Navigation Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelColor: Colors.black,
                        unselectedLabelColor: AppColors.textSecondary,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
                        tabs: const [
                          Tab(text: 'Daily Summary'),
                          Tab(text: 'Agents'),
                          Tab(text: 'Defaulters'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(AppIcons.download, size: 18, color: AppColors.primary),
                    tooltip: 'Export CSV',
                    onPressed: _exportCsv,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceCard,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: _isLoading
                  ? const AppLoading(message: 'Generating live financial analytics...')
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildDailyReportTab(),
                        _buildAgentReportTab(),
                        _buildDefaultersTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyReportTab() {
    final d = _dailyReport ?? {};
    final expected = (d['totalExpected'] as num?)?.toDouble() ?? 0.0;
    final collected = (d['totalCollected'] as num?)?.toDouble() ?? 0.0;
    final pending = (d['pendingToday'] as num?)?.toDouble() ?? 0.0;
    final rate = d['recoveryRatePercentage'] ?? 0;
    final overdueAcc = (d['totalOverdueAccumulated'] as num?)?.toDouble() ?? 0.0;

    final isDesktop = MediaQuery.of(context).size.width >= 750;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 2-Column Responsive Metric Cards
        GridView.count(
          crossAxisCount: isDesktop ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isDesktop ? 1.5 : 1.15,
          children: [
            StatMetricCard(
              title: 'Expected Inflow',
              value: CurrencyFormatter.format(expected),
              subtitle: 'Today target',
              icon: AppIcons.calendar,
              iconColor: AppColors.info,
            ),
            StatMetricCard(
              title: 'Collected Today',
              value: CurrencyFormatter.format(collected),
              subtitle: '$rate% Recovery',
              icon: AppIcons.badgeCheck,
              iconColor: AppColors.primary,
              badgeText: '$rate%',
              badgeColor: AppColors.primary,
            ),
            StatMetricCard(
              title: 'Pending Inflow',
              value: CurrencyFormatter.format(pending),
              subtitle: 'Due today',
              icon: AppIcons.clock,
              iconColor: AppColors.warning,
            ),
            StatMetricCard(
              title: 'Overdue Balance',
              value: CurrencyFormatter.format(overdueAcc),
              subtitle: 'Accumulated risk',
              icon: AppIcons.alertCircle,
              iconColor: AppColors.danger,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAgentReportTab() {
    if (_agentReport == null || _agentReport!.isEmpty) {
      return const AppEmptyState(
        title: 'No Agent Collection Data',
        subtitle: 'Agent collection records will appear here as field receipts are recorded.',
        icon: AppIcons.userX,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _agentReport!.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final item = _agentReport![idx];
        final name = item['agentName'] ?? 'Agent';
        final code = item['agentCode'] ?? '';
        final collected = (item['totalCollected'] as num?)?.toDouble() ?? 0.0;
        final transactions = item['totalTransactions'] ?? 0;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: idx == 0
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.surfaceCard,
                child: Text(
                  '#${idx + 1}',
                  style: TextStyle(
                    color: idx == 0 ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$name ($code)',
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$transactions Collections Recorded',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                CurrencyFormatter.format(collected),
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDefaultersTab() {
    if (_defaultersReport == null || _defaultersReport!.isEmpty) {
      return const AppEmptyState(
        title: 'Zero Defaulters / NPA! 🎉',
        subtitle: 'All customer installments are currently running on schedule.',
        icon: AppIcons.smile,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _defaultersReport!.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final item = _defaultersReport![idx];
        final name = item['customerName']?.toString() ?? 'Borrower';
        final phone = item['customerPhone']?.toString() ?? '';
        final route = item['routeArea']?.toString() ?? 'General Line';
        final overdueDays = item['overdueDays'] ?? 0;
        final balance = (item['remainingAmount'] as num?)?.toDouble() ?? 0.0;
        final accNo = item['accountNumber']?.toString() ?? '';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
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
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$overdueDays DAYS OVERDUE',
                      style: const TextStyle(color: AppColors.danger, fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Acc: $accNo • Phone: $phone • Line: $route',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Outstanding Overdue:', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  Text(
                    CurrencyFormatter.format(balance),
                    style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
