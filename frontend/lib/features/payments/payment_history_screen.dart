import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_widgets.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  String _search = '';
  List<dynamic> _payments = [];

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get(
        ApiEndpoints.payments,
        queryParameters: {if (_search.isNotEmpty) 'search': _search},
      );
      if (res.success && res.data is List) {
        setState(() {
          _payments = res.data as List<dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _shareReceiptWhatsApp(String receiptNumber, String phone) async {
    try {
      final res = await _apiClient.get('${ApiEndpoints.receipts}/$receiptNumber/whatsapp');
      if (res.success && res.data != null) {
        final urlStr = res.data['whatsappUrl']?.toString() ?? '';
        final url = Uri.parse(urlStr);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _fetchPayments,
        color: AppColors.primary,
        child: Column(
          children: [
            // Search Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by receipt number (REC-2026-0001)...',
                  prefixIcon: const Icon(AppIcons.search, size: 18, color: AppColors.textMuted),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(AppIcons.x, size: 16, color: AppColors.textMuted),
                          onPressed: () {
                            setState(() => _search = '');
                            _fetchPayments();
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onChanged: (val) {
                  _search = val;
                  _fetchPayments();
                },
              ),
            ),

            // Payments List
            Expanded(
              child: _isLoading
                  ? const AppLoading(message: 'Loading payment ledger...')
                  : _payments.isEmpty
                      ? const AppEmptyState(
                          title: 'No Payments Recorded',
                          subtitle: 'Recorded collections will appear here in chronological order.',
                          icon: AppIcons.receipt,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: _payments.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final p = _payments[index];
                            final receiptNo = p['receiptNumber']?.toString() ?? '';
                            final cust = p['customerId'] as Map<String, dynamic>?;
                            final custName = cust?['name']?.toString() ?? 'Borrower';
                            final custPhone = cust?['phone']?.toString() ?? '';
                            final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
                            final mode = p['paymentMethod']?.toString() ?? 'CASH';
                            final date = p['paymentDate'];
                            final agentUser = p['collectedById'] as Map<String, dynamic>?;
                            final collectedBy = agentUser?['name']?.toString() ?? 'Agent';

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(AppIcons.checkCircle2, color: AppColors.primary, size: 20),
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
                                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                            const SizedBox(width: 6),
                                            StatusBadge(status: mode, isSmall: true),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '$custName ($custPhone) • Collector: $collectedBy',
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          DateFormatter.format(date),
                                          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        CurrencyFormatter.format(amount),
                                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 15),
                                      ),
                                      const SizedBox(height: 4),
                                      InkWell(
                                        onTap: () => _shareReceiptWhatsApp(receiptNo, custPhone),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF25D366).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(AppIcons.messageCircle, size: 12, color: Color(0xFF25D366)),
                                              SizedBox(width: 4),
                                              Text('Share', style: TextStyle(color: Color(0xFF25D366), fontSize: 10, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
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
