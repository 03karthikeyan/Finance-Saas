import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';

class CustomerPaymentsScreen extends StatefulWidget {
  const CustomerPaymentsScreen({super.key});

  @override
  State<CustomerPaymentsScreen> createState() => _CustomerPaymentsScreenState();
}

class _CustomerPaymentsScreenState extends State<CustomerPaymentsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _payments = [];
  List<Map<String, dynamic>> _agentsList = [];
  Map<String, dynamic>? _dashboardData;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        ApiClient().get(ApiEndpoints.customerPortalPayments),
        ApiClient().get(ApiEndpoints.customerPortal),
        ApiClient().get(ApiEndpoints.agents),
      ]);

      final paymentsRes = results[0];
      final dashRes = results[1];
      final agentsRes = results[2];

      if (dashRes.success && dashRes.data is Map<String, dynamic>) {
        _dashboardData = dashRes.data as Map<String, dynamic>;
      }

      if (agentsRes.success && agentsRes.data is List) {
        _agentsList = (agentsRes.data as List).whereType<Map<String, dynamic>>().toList();
      }

      if (paymentsRes.success && paymentsRes.data is List<dynamic>) {
        if (mounted) {
          setState(() {
            _payments = paymentsRes.data as List<dynamic>;
            _isLoading = false;
          });
        }
      } else {
        // Fallback to recent payments from portal dashboard if endpoint returns differently
        final recent = _dashboardData?['recentPayments'] as List<dynamic>? ?? [];
        if (mounted) {
          setState(() {
            _payments = recent;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading payment history: $e';
          _isLoading = false;
        });
      }
    }
  }

  String _getAgentName(Map<String, dynamic> payment) {
    // 1. From agentId object
    final agentObj = payment['agentId'];
    if (agentObj is Map) {
      final code = agentObj['agentCode']?.toString() ?? '';
      final userObj = agentObj['userId'];
      if (userObj is Map && userObj['name'] != null) {
        final name = userObj['name'].toString();
        return code.isNotEmpty ? '$name ($code)' : name;
      }
      if (agentObj['name'] != null) {
        final name = agentObj['name'].toString();
        return code.isNotEmpty ? '$name ($code)' : name;
      }
      if (code.isNotEmpty) return 'Field Officer ($code)';
    }

    // 2. From collectedById object
    final collectedObj = payment['collectedById'];
    if (collectedObj is Map && collectedObj['name'] != null) {
      return collectedObj['name'].toString();
    }

    // 3. Match raw ID against _agentsList
    final agentIdStr = (agentObj is String)
        ? agentObj
        : (payment['collectedById'] is String ? payment['collectedById'].toString() : '');
    if (agentIdStr.isNotEmpty && _agentsList.isNotEmpty) {
      final matched = _agentsList.firstWhere(
        (a) => a['_id']?.toString() == agentIdStr || a['id']?.toString() == agentIdStr,
        orElse: () => <String, dynamic>{},
      );
      if (matched.isNotEmpty) {
        final code = matched['agentCode']?.toString() ?? '';
        final userObj = matched['userId'] is Map ? matched['userId'] as Map<String, dynamic> : <String, dynamic>{};
        final name = userObj['name'] ?? matched['name'] ?? 'Field Officer';
        return code.isNotEmpty ? '$name ($code)' : name.toString();
      }
    }

    // 4. Fallback to assignedAgent from dashboardData or default
    final assigned = _dashboardData?['assignedAgent'];
    if (assigned is Map && assigned['name'] != null) {
      final code = assigned['agentCode']?.toString() ?? '';
      final name = assigned['name'].toString();
      return code.isNotEmpty ? '$name ($code)' : name;
    }

    return 'Branch Field Officer';
  }

  Future<void> _openWhatsApp(String message) async {
    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('https://wa.me/?text=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showReceiptModal(Map<String, dynamic> payment) {
    final receiptNumber = payment['receiptNumber']?.toString() ?? 'REC-${payment['_id']?.toString().substring(0, 6) ?? ''}';
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
    final paymentDate = payment['paymentDate'] != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.tryParse(payment['paymentDate'].toString()) ?? DateTime.now())
        : 'Recent';
    final mode = payment['paymentMethod']?.toString() ?? 'CASH';
    final collectorName = _getAgentName(payment);
    final accNum = payment['financeAccountId'] is Map
        ? (payment['financeAccountId']['accountNumber']?.toString() ?? '')
        : '';
    final companyName = _dashboardData?['company']?['name']?.toString() ?? 'Finance SaaS';
    final customerName = _dashboardData?['customer']?['name']?.toString() ?? 'Borrower';
    final branchName = _dashboardData?['branch']?['name']?.toString() ?? '';

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
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF065F46), Color(0xFF047857), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF047857).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'AMOUNT RECEIVED',
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(amount),
                    style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(AppIcons.checkCircle2, color: Colors.white, size: 14),
                        const SizedBox(width: 5),
                        Text('PAID VIA $mode', style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _row('Receipt Number', receiptNumber),
                  const Divider(color: AppColors.border, height: 16),
                  _row('Borrower Name', customerName),
                  if (accNum.isNotEmpty) ...[
                    const Divider(color: AppColors.border, height: 16),
                    _row('Loan Account No', accNum),
                  ],
                  const Divider(color: AppColors.border, height: 16),
                  _row('Payment Date', paymentDate),
                  const Divider(color: AppColors.border, height: 16),
                  _row('Collected By', collectorName, highlight: true),
                  if (branchName.isNotEmpty) ...[
                    const Divider(color: AppColors.border, height: 16),
                    _row('Servicing Branch', branchName),
                  ],
                  const Divider(color: AppColors.border, height: 16),
                  _row('Finance Issuer', companyName),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final text = '🧾 *OFFICIAL PAYMENT RECEIPT*\n'
                          'Issuer: $companyName\n'
                          'Branch: $branchName\n'
                          'Borrower: $customerName\n'
                          'Receipt No: $receiptNumber\n'
                          'Loan Account: $accNum\n'
                          'Amount Paid: ${CurrencyFormatter.format(amount)}\n'
                          'Payment Mode: $mode\n'
                          'Collected By: $collectorName\n'
                          'Date: $paymentDate\n'
                          'Status: SUCCESSFUL ✅';
                      _openWhatsApp(text);
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

  Widget _row(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: highlight ? AppColors.primaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 12.5,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalPaidAcrossAll = 0.0;
    for (var p in _payments) {
      final amt = (p['amount'] as num?)?.toDouble() ?? 0.0;
      totalPaidAcrossAll += amt;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Row(
          children: [
            Icon(AppIcons.receipt, size: 20, color: AppColors.success),
            SizedBox(width: 8),
            Text(
              'Payment History & Receipts',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17.5,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadPayments,
            icon: const Icon(AppIcons.refreshCw, size: 18, color: AppColors.textSecondary),
            tooltip: 'Refresh Payments',
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
                  Text('Loading payment receipts...', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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
                        const Icon(AppIcons.alertCircle, color: AppColors.danger, size: 40),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadPayments,
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
              : RefreshIndicator(
                  onRefresh: _loadPayments,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Total Receipts Metric Banner
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.25),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(AppIcons.checkCircle2, color: Color(0xFF4ADE80), size: 14),
                                    SizedBox(width: 5),
                                    Text(
                                      'TOTAL PAYMENTS RECORDED',
                                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  CurrencyFormatter.format(totalPaidAcrossAll),
                                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4ADE80).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF4ADE80).withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(AppIcons.receipt, color: Color(0xFF4ADE80), size: 14),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${_payments.length} Receipts',
                                    style: const TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      const Text(
                        'All Collection Receipts',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 10),

                      if (_payments.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              Icon(AppIcons.receipt, size: 40, color: AppColors.textMuted.withValues(alpha: 0.4)),
                              const SizedBox(height: 10),
                              const Text('No payment receipts recorded yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textPrimary)),
                              const SizedBox(height: 4),
                              const Text('When your collection officer collects installments, official digital receipts will appear here.', style: TextStyle(fontSize: 12, color: AppColors.textMuted), textAlign: TextAlign.center),
                            ],
                          ),
                        )
                      else
                        ..._payments.map((p) {
                          final payMap = p as Map<String, dynamic>;
                          final amount = (payMap['amount'] as num?)?.toDouble() ?? 0.0;
                          final dateStr = payMap['paymentDate']?.toString();
                          final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
                          final mode = payMap['paymentMethod']?.toString() ?? 'CASH';
                          final receiptNo = payMap['receiptNumber']?.toString() ?? 'REC-${payMap['_id']?.toString().substring(0, 6) ?? ''}';
                          final collector = _getAgentName(payMap);
                          final accNum = payMap['financeAccountId'] is Map
                              ? (payMap['financeAccountId']['accountNumber']?.toString() ?? '')
                              : '';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => _showReceiptModal(payMap),
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: AppColors.border),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppColors.success.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(AppIcons.receipt, color: AppColors.success, size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    receiptNo,
                                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.textPrimary),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.surfaceCard,
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: AppColors.border),
                                                    ),
                                                    child: Text(mode, style: const TextStyle(color: AppColors.textSecondary, fontSize: 9.5, fontWeight: FontWeight.bold)),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                date != null ? DateFormat('dd MMM yyyy, hh:mm a').format(date) : 'Recent',
                                                style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                                              ),
                                              if (accNum.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Loan Account: $accNum',
                                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                                ),
                                              ],
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
                                                fontWeight: FontWeight.w900,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            const Row(
                                              children: [
                                                Text('Receipt', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                                                Icon(AppIcons.chevronRight, size: 12, color: AppColors.primary),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    const Divider(color: AppColors.border, height: 1),
                                    const SizedBox(height: 8),

                                    // COLLECTED BY ROW (PROMINENT)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppColors.primarySoft,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(AppIcons.userCheck, size: 13, color: AppColors.primary),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              'Collected by: $collector',
                                              style: const TextStyle(
                                                color: AppColors.primaryDark,
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
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}
