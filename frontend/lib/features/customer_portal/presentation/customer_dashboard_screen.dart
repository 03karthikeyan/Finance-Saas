import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/customer_loan_schedule_sheet.dart';

class CustomerDashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToLoans;
  final VoidCallback? onNavigateToPayments;

  const CustomerDashboardScreen({
    super.key,
    this.onNavigateToLoans,
    this.onNavigateToPayments,
  });

  @override
  State<CustomerDashboardScreen> createState() => _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _dashboardData;

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        ApiClient().get(ApiEndpoints.customerPortal),
        ApiClient().get(ApiEndpoints.branches),
        ApiClient().get(ApiEndpoints.agents),
      ]);

      final portalRes = results[0];
      final branchesRes = results[1];
      final agentsRes = results[2];

      if (portalRes.success && portalRes.data is Map<String, dynamic>) {
        final data = Map<String, dynamic>.from(portalRes.data as Map<String, dynamic>);
        final customer = (data['customer'] is Map) ? Map<String, dynamic>.from(data['customer'] as Map) : <String, dynamic>{};

        final branchesList = (branchesRes.success && branchesRes.data is List)
            ? (branchesRes.data as List).whereType<Map<String, dynamic>>().toList()
            : <Map<String, dynamic>>[];

        final agentsList = (agentsRes.success && agentsRes.data is List)
            ? (agentsRes.data as List).whereType<Map<String, dynamic>>().toList()
            : <Map<String, dynamic>>[];

        // 1. Resolve Branch Details
        if (data['branch'] == null || (data['branch'] is Map && (data['branch'] as Map)['name'] == null)) {
          final bId = customer['branchId']?.toString() ?? '';
          if (bId.isNotEmpty && branchesList.isNotEmpty) {
            final match = branchesList.firstWhere(
              (b) => b['_id']?.toString() == bId || b['id']?.toString() == bId,
              orElse: () => branchesList.first,
            );
            data['branch'] = match;
          } else if (branchesList.isNotEmpty) {
            data['branch'] = branchesList.first;
          }
        }

        // 2. Resolve Primary Assigned Agent Details
        final branchObj = data['branch'] as Map<String, dynamic>?;
        final resolvedBranchId = branchObj?['_id']?.toString() ?? branchObj?['id']?.toString() ?? customer['branchId']?.toString() ?? '';

        if (data['assignedAgent'] == null || (data['assignedAgent'] is Map && (data['assignedAgent'] as Map)['name'] == null)) {
          final aId = customer['assignedAgentId']?.toString() ?? '';
          if (aId.isNotEmpty && agentsList.isNotEmpty) {
            final match = agentsList.firstWhere(
              (a) => a['_id']?.toString() == aId || a['id']?.toString() == aId,
              orElse: () => <String, dynamic>{},
            );
            if (match.isNotEmpty) {
              final userObj = match['userId'] is Map ? match['userId'] as Map<String, dynamic> : <String, dynamic>{};
              data['assignedAgent'] = {
                'id': match['_id'] ?? match['id'],
                'agentCode': match['agentCode'] ?? 'AGENT',
                'name': userObj['name'] ?? match['name'] ?? 'Field Officer',
                'phone': userObj['phone'] ?? match['phone'] ?? branchObj?['phone'] ?? '',
                'email': userObj['email'] ?? match['email'] ?? '',
                'profileImage': match['profileImage'] ?? userObj['profileImage'] ?? '',
                'assignedRoutes': match['assignedRoutes'] ?? [],
              };
            }
          }

          // If still null, find agent serving customer's route or branch
          if (data['assignedAgent'] == null && agentsList.isNotEmpty) {
            final route = customer['address'] is Map ? (customer['address']['routeArea']?.toString() ?? '') : '';
            Map<String, dynamic>? match;
            if (route.isNotEmpty) {
              match = agentsList.firstWhere(
                (a) {
                  final routes = (a['assignedRoutes'] as List<dynamic>?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
                  return routes.contains(route.toLowerCase());
                },
                orElse: () => <String, dynamic>{},
              );
            }
            if (match == null || match.isEmpty) {
              if (resolvedBranchId.isNotEmpty) {
                match = agentsList.firstWhere(
                  (a) => a['branchId']?.toString() == resolvedBranchId || (a['branchId'] is Map && (a['branchId'] as Map)['_id']?.toString() == resolvedBranchId),
                  orElse: () => agentsList.first,
                );
              } else {
                match = agentsList.first;
              }
            }

            if (match.isNotEmpty) {
              final userObj = match['userId'] is Map ? match['userId'] as Map<String, dynamic> : <String, dynamic>{};
              data['assignedAgent'] = {
                'id': match['_id'] ?? match['id'],
                'agentCode': match['agentCode'] ?? 'AGENT',
                'name': userObj['name'] ?? match['name'] ?? 'Field Officer',
                'phone': userObj['phone'] ?? match['phone'] ?? branchObj?['phone'] ?? '',
                'email': userObj['email'] ?? match['email'] ?? '',
                'profileImage': match['profileImage'] ?? userObj['profileImage'] ?? '',
                'assignedRoutes': match['assignedRoutes'] ?? [],
              };
            }
          }
        }

        // 3. Resolve Branch Agents list
        if ((data['branchAgents'] as List?)?.isEmpty ?? true) {
          final bAgents = agentsList.where((a) {
            if (resolvedBranchId.isEmpty) return true;
            final aBranchId = a['branchId'] is Map ? (a['branchId'] as Map)['_id']?.toString() : a['branchId']?.toString();
            return aBranchId == resolvedBranchId;
          }).map((a) {
            final userObj = a['userId'] is Map ? a['userId'] as Map<String, dynamic> : <String, dynamic>{};
            return {
              'id': a['_id'] ?? a['id'],
              'agentCode': a['agentCode'] ?? 'AGENT',
              'name': userObj['name'] ?? a['name'] ?? 'Field Officer',
              'phone': userObj['phone'] ?? a['phone'] ?? '',
              'email': userObj['email'] ?? a['email'] ?? '',
              'profileImage': a['profileImage'] ?? userObj['profileImage'] ?? '',
              'assignedRoutes': a['assignedRoutes'] ?? [],
            };
          }).toList();

          if (bAgents.isNotEmpty) {
            data['branchAgents'] = bAgents;
          }
        }

        if (mounted) {
          setState(() {
            _dashboardData = data;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = portalRes.message.isNotEmpty ? portalRes.message : 'Failed to load borrower portal';
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

  Future<void> _makePhoneCall(String phoneNumber) async {
    final clean = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (clean.isEmpty) return;
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot launch dialer for $phoneNumber')),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String phoneNumber, String message) async {
    final clean = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) return;
    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('https://wa.me/$clean?text=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    }
  }

  void _showLoanScheduleBottomSheet(Map<String, dynamic> account) {
    final accId = account['_id']?.toString() ?? '';
    if (accId.isEmpty) return;

    CustomerLoanScheduleSheet.show(
      context,
      accountId: accId,
      accountSummary: account,
    );
  }

  void _showReceiptDetailModal(Map<String, dynamic> payment) {
    final receiptNumber = payment['receiptNumber']?.toString() ?? 'REC-${payment['_id']?.toString().substring(0, 6) ?? ''}';
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
    final paymentDate = payment['paymentDate'] != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.tryParse(payment['paymentDate'].toString()) ?? DateTime.now())
        : 'Recent';
    final mode = payment['paymentMethod']?.toString() ?? 'CASH';
    final collectorName = payment['collectedBy'] is Map
        ? (payment['collectedBy']['name']?.toString() ?? 'Line Officer')
        : 'Line Officer';
    final accNum = payment['financeAccountId'] is Map
        ? (payment['financeAccountId']['accountNumber']?.toString() ?? '')
        : '';
    final companyName = _dashboardData?['company']?['name']?.toString() ?? 'Finance Company';
    final customerName = _dashboardData?['customer']?['name']?.toString() ?? 'Borrower';

    AppBottomSheet.show(
      context: context,
      builder: (sheetCtx) => AppBottomSheet(
        title: 'Collection Payment Receipt',
        subtitle: '$receiptNumber • $paymentDate',
        icon: AppIcons.receipt,
        iconColor: AppColors.success,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Receipt Header Badge
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('AMOUNT RECEIVED', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(amount),
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(AppIcons.checkCircle2, color: Colors.white, size: 13),
                        const SizedBox(width: 5),
                        Text('PAID VIA $mode', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Receipt Breakdown Details
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _receiptRow('Receipt Number', receiptNumber),
                  const Divider(color: AppColors.border, height: 16),
                  _receiptRow('Borrower Name', customerName),
                  if (accNum.isNotEmpty) ...[
                    const Divider(color: AppColors.border, height: 16),
                    _receiptRow('Loan Account No', accNum),
                  ],
                  const Divider(color: AppColors.border, height: 16),
                  _receiptRow('Payment Date', paymentDate),
                  const Divider(color: AppColors.border, height: 16),
                  _receiptRow('Collected By', collectorName),
                  const Divider(color: AppColors.border, height: 16),
                  _receiptRow('Finance Issuer', companyName),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final text = '🧾 *PAYMENT RECEIPT*\n'
                          'Issuer: $companyName\n'
                          'Borrower: $customerName\n'
                          'Receipt No: $receiptNumber\n'
                          'Amount Paid: ${CurrencyFormatter.format(amount)}\n'
                          'Date: $paymentDate\n'
                          'Collector: $collectorName\n'
                          'Status: SUCCESS ✅';
                      _openWhatsApp('', text);
                    },
                    icon: const Icon(Icons.share, size: 16, color: Colors.white),
                    label: const Text('Share Receipt', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () => Navigator.pop(sheetCtx),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12.5),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 14),
              Text('Loading your loan portfolio...', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(AppIcons.alertCircle, color: AppColors.danger, size: 48),
                const SizedBox(height: 14),
                Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _fetchDashboard,
                  icon: const Icon(AppIcons.refreshCw, size: 16),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final data = _dashboardData ?? {};
    final customer = data['customer'] as Map<String, dynamic>? ?? {};
    final summary = data['summary'] as Map<String, dynamic>? ?? {};
    final assignedAgent = data['assignedAgent'] as Map<String, dynamic>?;
    final branchAgents = data['branchAgents'] as List<dynamic>? ?? [];
    final branch = data['branch'] as Map<String, dynamic>?;
    final activeAccounts = data['activeAccounts'] as List<dynamic>? ?? [];
    final upcomingInstallment = data['upcomingInstallment'] as Map<String, dynamic>?;
    final recentPayments = data['recentPayments'] as List<dynamic>? ?? [];

    final customerName = customer['name']?.toString() ?? 'Borrower';
    final customerCode = customer['customerCode']?.toString() ?? 'BORROWER';
    final totalBorrowed = (summary['totalBorrowed'] as num?)?.toDouble() ?? 0.0;
    final totalPaid = (summary['totalPaid'] as num?)?.toDouble() ?? 0.0;
    final totalOutstanding = (summary['totalOutstanding'] as num?)?.toDouble() ?? 0.0;
    final activeLoansCount = summary['activeLoansCount'] as int? ?? activeAccounts.length;

    final paidRatio = (totalBorrowed > 0) ? (totalPaid / totalBorrowed).clamp(0.0, 1.0) : 0.0;
    final paidPercent = (paidRatio * 100).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _fetchDashboard,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // 1. Borrower Welcome & Code Capsule
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $customerName',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Borrower Account & Repayment Center',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(AppIcons.userCheck, size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        customerCode,
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. HERO FINANCIAL HEALTH OVERVIEW CARD (Borrowed vs Paid vs Pending)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
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
                          Icon(AppIcons.wallet, color: Colors.white70, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'TOTAL OUTSTANDING (PENDING)',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$activeLoansCount Active Loan${activeLoansCount == 1 ? '' : 's'}',
                          style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.format(totalOutstanding),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Progress Bar: Paid Percentage
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: paidRatio,
                      minHeight: 7,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2 Bottom Columns: Total Borrowed & Total Paid
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
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 28, color: Colors.white.withValues(alpha: 0.15)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Paid ($paidPercent%)', style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 11, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.format(totalPaid),
                              style: const TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. WHO WILL COLLECT CARD (Collector Agent & Servicing Branch)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.accentIndigo.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(AppIcons.userCheck, size: 16, color: AppColors.accentIndigo),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assigned Collection Officer',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Authorised field agent who collects your EMI',
                              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Builder(builder: (context) {
                    final agentName = assignedAgent?['name']?.toString() ??
                        (branch != null ? '${branch['name']} Collection Officer' : 'Branch Field Officer');
                    final agentCode = assignedAgent?['agentCode']?.toString() ??
                        (branch?['branchCode']?.toString() ?? 'FIELD-AGENT');
                    final agentPhone = (assignedAgent?['phone']?.toString().isNotEmpty ?? false)
                        ? assignedAgent!['phone'].toString()
                        : (branch?['phone']?.toString() ?? '');
                    final agentPhoto = assignedAgent?['profileImage']?.toString();

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          AppAvatar(
                            imageSource: agentPhoto,
                            radius: 22,
                            fallbackText: agentName,
                            fallbackIcon: AppIcons.user,
                            backgroundColor: AppColors.primarySoft,
                            foregroundColor: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        agentName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.5,
                                          color: AppColors.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: AppColors.primarySoft,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        agentCode,
                                        style: const TextStyle(
                                          color: AppColors.primaryDark,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  agentPhone.isNotEmpty ? agentPhone : (branch?['name']?.toString() ?? 'Branch Collection'),
                                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          // 1-Tap Phone Call Button
                          if (agentPhone.isNotEmpty) ...[
                            IconButton(
                              onPressed: () => _makePhoneCall(agentPhone),
                              icon: const Icon(AppIcons.phoneCall, color: AppColors.primary, size: 20),
                              tooltip: 'Call Collector Officer',
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.primarySoft,
                                padding: const EdgeInsets.all(8),
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              onPressed: () {
                                final msg = 'Hello $agentName, I am $customerName ($customerCode). Inquiring about my loan installment.';
                                _openWhatsApp(agentPhone, msg);
                              },
                              icon: const Icon(Icons.chat_bubble_outline, color: AppColors.success, size: 20),
                              tooltip: 'WhatsApp Collector',
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.success.withValues(alpha: 0.1),
                                padding: const EdgeInsets.all(8),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                  // If multiple branch agents exist, show Branch Agents Team
                  if (branchAgents.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Branch Field Agents',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${branchAgents.length} Officer${branchAgents.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...branchAgents.map((ag) {
                      final aName = ag['name']?.toString() ?? 'Field Agent';
                      final aCode = ag['agentCode']?.toString() ?? 'AGENT';
                      final aPhone = ag['phone']?.toString() ?? '';
                      final aRoutes = (ag['assignedRoutes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            AppAvatar(
                              imageSource: ag['profileImage']?.toString(),
                              radius: 16,
                              fallbackText: aName,
                              fallbackIcon: AppIcons.user,
                              backgroundColor: AppColors.primarySoft,
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
                                          aName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.textPrimary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '($aCode)',
                                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  if (aRoutes.isNotEmpty)
                                    Text(
                                      'Routes: ${aRoutes.take(3).join(", ")}${aRoutes.length > 3 ? "..." : ""}',
                                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            if (aPhone.isNotEmpty) ...[
                              IconButton(
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                padding: EdgeInsets.zero,
                                onPressed: () => _makePhoneCall(aPhone),
                                icon: const Icon(AppIcons.phoneCall, color: AppColors.primary, size: 16),
                                tooltip: 'Call $aName',
                              ),
                              IconButton(
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  final msg = 'Hello $aName, I am $customerName ($customerCode).';
                                  _openWhatsApp(aPhone, msg);
                                },
                                icon: const Icon(Icons.chat_bubble_outline, color: AppColors.success, size: 16),
                                tooltip: 'WhatsApp $aName',
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 10),

                  // Servicing Branch Office Capsule
                  if (branch != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(AppIcons.building, size: 15, color: AppColors.accentCyan),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Servicing Branch: ${branch['name'] ?? 'Main Office'} (${branch['branchCode'] ?? 'BR-01'})',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary),
                                ),
                                if (branch['address'] is Map && branch['address']['city'] != null)
                                  Text(
                                    '${branch['address']['street'] ?? ''} ${branch['address']['city'] ?? ''}'.trim(),
                                    style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          if (branch['phone'] != null && branch['phone'].toString().isNotEmpty)
                            InkWell(
                              onTap: () => _makePhoneCall(branch['phone'].toString()),
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Text(
                                  'Call Branch',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. NEXT EMI DUE REMINDER CARD (If Upcoming Installment exists)
            if (upcomingInstallment != null) ...[
              Builder(builder: (context) {
                final dueDateStr = upcomingInstallment['dueDate']?.toString();
                final dueDate = dueDateStr != null ? DateTime.tryParse(dueDateStr) : null;
                final expectedAmount = (upcomingInstallment['expectedAmount'] as num?)?.toDouble() ?? 0.0;
                final instNumber = upcomingInstallment['installmentNumber'] ?? 1;

                String dueTag = 'Upcoming';
                Color tagColor = AppColors.accentIndigo;
                if (dueDate != null) {
                  final now = DateTime.now();
                  final diff = dueDate.difference(DateTime(now.year, now.month, now.day)).inDays;
                  if (diff < 0) {
                    dueTag = 'OVERDUE by ${diff.abs()} day${diff.abs() == 1 ? '' : 's'}';
                    tagColor = AppColors.danger;
                  } else if (diff == 0) {
                    dueTag = 'DUE TODAY';
                    tagColor = AppColors.warning;
                  } else if (diff == 1) {
                    dueTag = 'Due Tomorrow';
                    tagColor = AppColors.primary;
                  } else {
                    dueTag = 'Due in $diff days';
                    tagColor = AppColors.accentIndigo;
                  }
                }

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: tagColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: tagColor.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(AppIcons.calendar, size: 16, color: tagColor),
                              const SizedBox(width: 6),
                              const Text(
                                'NEXT INSTALLMENT DUE',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.5,
                                  letterSpacing: 0.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: tagColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              dueTag,
                              style: TextStyle(color: tagColor, fontSize: 10.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                CurrencyFormatter.format(expectedAmount),
                                style: TextStyle(
                                  color: tagColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Installment #$instNumber • ${dueDate != null ? DateFormat('EEEE, dd MMM yyyy').format(dueDate) : 'Scheduled'}',
                                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            // 5. ACTIVE LOAN ACCOUNTS LIST
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Active Loans',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                if (widget.onNavigateToLoans != null)
                  TextButton(
                    onPressed: widget.onNavigateToLoans,
                    child: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (activeAccounts.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    Icon(AppIcons.checkCircle2, size: 32, color: AppColors.success),
                    SizedBox(height: 8),
                    Text('No active loans right now', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    SizedBox(height: 2),
                    Text('All your borrowing accounts are fully settled.', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                  ],
                ),
              )
            else
              ...activeAccounts.map((acc) {
                final accMap = acc as Map<String, dynamic>;
                final accNumber = accMap['accountNumber']?.toString() ?? 'FIN-LOAN';
                final principal = (accMap['principalAmount'] as num?)?.toDouble() ?? 0.0;
                final totalPayable = (accMap['totalPayableAmount'] as num?)?.toDouble() ?? principal;
                final paid = (accMap['totalPaidAmount'] as num?)?.toDouble() ?? 0.0;
                final remaining = (accMap['remainingAmount'] as num?)?.toDouble() ?? (totalPayable - paid);
                final emi = (accMap['installmentAmount'] as num?)?.toDouble() ?? 0.0;
                final totalInst = accMap['totalInstallments'] ?? 0;
                final paidInst = accMap['paidInstallments'] ?? 0;
                final freq = accMap['frequency']?.toString() ?? 'DAILY';
                final productName = accMap['productId'] is Map
                    ? (accMap['productId']['name']?.toString() ?? 'Commercial Loan')
                    : 'Commercial Loan';
                final ratio = totalPayable > 0 ? (paid / totalPayable).clamp(0.0, 1.0) : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => _showLoanScheduleBottomSheet(accMap),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    accNumber,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    productName,
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  freq,
                                  style: const TextStyle(color: AppColors.primaryDark, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 5,
                              backgroundColor: AppColors.border,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Stats Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Paid Amount', style: TextStyle(color: AppColors.textMuted, fontSize: 10.5)),
                                  Text(
                                    CurrencyFormatter.format(paid),
                                    style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12.5),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text('EMI / Due', style: TextStyle(color: AppColors.textMuted, fontSize: 10.5)),
                                  Text(
                                    CurrencyFormatter.format(emi),
                                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12.5),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Remaining', style: TextStyle(color: AppColors.textMuted, fontSize: 10.5)),
                                  Text(
                                    CurrencyFormatter.format(remaining),
                                    style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 12.5),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(color: AppColors.border, height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$paidInst / $totalInst installments completed',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              const Row(
                                children: [
                                  Text('View Full Schedule', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                                  Icon(AppIcons.chevronRight, size: 14, color: AppColors.primary),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 16),

            // 6. RECENT PAYMENT RECEIPTS LEDGER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Payment Receipts',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                if (widget.onNavigateToPayments != null)
                  TextButton(
                    onPressed: widget.onNavigateToPayments,
                    child: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (recentPayments.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text('No recent collection payments found.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              )
            else
              ...recentPayments.take(5).map((pay) {
                final payMap = pay as Map<String, dynamic>;
                final amount = (payMap['amount'] as num?)?.toDouble() ?? 0.0;
                final dateStr = payMap['paymentDate']?.toString();
                final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
                final mode = payMap['paymentMethod']?.toString() ?? 'CASH';
                final receiptNo = payMap['receiptNumber']?.toString() ?? 'REC-${payMap['_id']?.toString().substring(0, 6) ?? ''}';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => _showReceiptDetailModal(payMap),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(AppIcons.receipt, color: AppColors.success, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  receiptNo,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  date != null ? DateFormat('dd MMM yyyy, hh:mm a').format(date) : 'Recent Payment',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '+${CurrencyFormatter.format(amount)}',
                                style: const TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                mode,
                                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}


