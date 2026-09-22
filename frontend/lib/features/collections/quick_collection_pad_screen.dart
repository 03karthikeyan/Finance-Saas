import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/pdf_collection_report.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../authentication/presentation/auth_cubit.dart';
import '../layout/branch_cubit.dart';
import '../../core/widgets/customer_loan_schedule_sheet.dart';

class QuickCollectionPadScreen extends StatefulWidget {
  const QuickCollectionPadScreen({super.key});

  @override
  State<QuickCollectionPadScreen> createState() => _QuickCollectionPadScreenState();
}

class _QuickCollectionPadScreenState extends State<QuickCollectionPadScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  bool _isGeneratingPdf = false;
  String _searchQuery = '';
  String? _selectedRoute;
  String? _selectedAgentId;
  String _selectedStatusFilter = 'ALL'; // 'ALL', 'PENDING', 'PAID', 'OVERDUE'
  DateTime _selectedDate = DateTime.now();
  String? _lastLoadedBranchId = 'INIT';

  List<dynamic> _allCollectionItems = [];
  List<String> _availableRoutes = [];
  List<dynamic> _availableAgents = [];

  // Summary Metrics
  double _totalExpectedToday = 0;
  double _totalCollectedToday = 0;
  int _paidCount = 0;
  int _pendingCount = 0;
  int _overdueCount = 0;

  // Cashbook Metrics
  double _todayCashInjections = 0;
  double _todayExpenses = 0;
  double _netCashInHand = 0;

  @override
  void initState() {
    super.initState();
    _fetchAgents();
    _fetchCollectionData();
  }

  Future<void> _fetchCashbookData() async {
    try {
      final dateFormatted = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final res = await _apiClient.get(
        '${ApiEndpoints.expenses}/cashbook-summary',
        queryParameters: {'date': dateFormatted},
      );
      if (res.success && res.data != null) {
        final data = res.data is Map ? (res.data['data'] ?? res.data) : null;
        if (data is Map && mounted) {
          setState(() {
            _todayCashInjections = (data['cashInjections'] as num?)?.toDouble() ?? 0.0;
            _todayExpenses = (data['expenses'] as num?)?.toDouble() ?? 0.0;
            _netCashInHand = (data['netCashInHand'] as num?)?.toDouble() ?? 0.0;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchAgents([String? branchIdOverride]) async {
    final branchId = branchIdOverride ??
        (mounted ? context.read<BranchCubit>().state.activeBranchId : null);

    try {
      final res = await _apiClient.get(
        ApiEndpoints.agents,
        queryParameters: {
          if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
        },
      );
      if (res.success && res.data is List) {
        if (mounted) {
          setState(() {
            _availableAgents = res.data as List<dynamic>;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchCollectionData([String? branchIdOverride]) async {
    setState(() => _isLoading = true);
    final branchId = branchIdOverride ??
        (mounted ? context.read<BranchCubit>().state.activeBranchId : null);
    _lastLoadedBranchId = branchId;

    try {
      final dateFormatted = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final sheetRes = await _apiClient.get(
        ApiEndpoints.todayCollectionSheet,
        queryParameters: {
          'date': dateFormatted,
          if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
          if (_selectedRoute != null) 'routeArea': _selectedRoute,
          if (_selectedAgentId != null) 'agentId': _selectedAgentId,
          if (_searchQuery.isNotEmpty) 'search': _searchQuery,
        },
      );

      if (sheetRes.success && sheetRes.data is List) {
        final list = sheetRes.data as List<dynamic>;
        final routesSet = <String>{};

        double expected = 0;
        double collected = 0;
        int paid = 0;
        int pending = 0;
        int overdue = 0;

        for (final item in list) {
          final cust = item['customer'] as Map<String, dynamic>?;
          final route = cust?['address']?['routeArea']?.toString();
          if (route != null && route.isNotEmpty) {
            routesSet.add(route);
          }

          final installment = (item['installmentAmount'] as num?)?.toDouble() ?? 0.0;
          final todayPaid = (item['todayPaidAmount'] as num?)?.toDouble() ?? 0.0;
          final isPaid = item['isPaidToday'] == true;
          final isOverdue = item['isOverdue'] == true;

          expected += installment;
          collected += todayPaid;
          if (isPaid) {
            paid++;
          } else {
            pending++;
            if (isOverdue) overdue++;
          }
        }

        if (mounted) {
          setState(() {
            _allCollectionItems = list;
            _availableRoutes = routesSet.toList();
            _totalExpectedToday = expected;
            _totalCollectedToday = collected;
            _paidCount = paid;
            _pendingCount = pending;
            _overdueCount = overdue;
            _isLoading = false;
          });
          _fetchCashbookData();
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredList {
    List<dynamic> list = _allCollectionItems;

    if (_selectedStatusFilter == 'PAID') {
      return list.where((item) => item['isPaidToday'] == true).toList();
    } else if (_selectedStatusFilter == 'PENDING') {
      return list.where((item) => item['isPaidToday'] != true).toList();
    } else if (_selectedStatusFilter == 'OVERDUE') {
      return list.where((item) => item['isOverdue'] == true && item['isPaidToday'] != true).toList();
    }
    return list;
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: AppColors.surface,
              headerBackgroundColor: AppColors.primary,
              headerForegroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return Colors.white;
                if (states.contains(WidgetState.disabled)) return AppColors.textMuted;
                return AppColors.textPrimary;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return AppColors.primary;
                return Colors.transparent;
              }),
              todayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return Colors.white;
                return AppColors.primary;
              }),
              todayBorder: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _fetchCollectionData();
    }
  }

  void _shiftDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _fetchCollectionData();
  }

  Future<void> _downloadPdfReport(String companyName) async {
    final filtered = _filteredList;
    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No collection records to export for this selection.')),
      );
      return;
    }

    setState(() => _isGeneratingPdf = true);
    try {
      String staffName = 'All Staff';
      if (_selectedAgentId != null) {
        final ag = _availableAgents.firstWhere(
          (a) => a['_id']?.toString() == _selectedAgentId || (a['userId'] is Map && a['userId']['_id']?.toString() == _selectedAgentId),
          orElse: () => null,
        );
        if (ag != null) {
          final u = ag['userId'] as Map<String, dynamic>?;
          staffName = u?['name']?.toString() ?? ag['agentCode']?.toString() ?? 'Staff';
        }
      }

      final routeName = _selectedRoute ?? 'All Lines';

      await PdfCollectionReport.generateAndDownload(
        companyName: companyName,
        selectedDate: _selectedDate,
        staffName: staffName,
        routeName: routeName,
        totalExpected: _totalExpectedToday,
        totalCollected: _totalCollectedToday,
        paidCount: _paidCount,
        pendingCount: _pendingCount,
        items: filtered,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  void _openCollectionBottomSheet(Map<String, dynamic> item) {
    final cust = item['customer'] as Map<String, dynamic>? ?? {};
    final custName = cust['name']?.toString() ?? 'Customer';
    final custCode = cust['customerCode']?.toString() ?? '';
    final custPhone = cust['phone']?.toString() ?? '';
    final accountId = item['accountId']?.toString() ?? '';
    final accNumber = item['accountNumber']?.toString() ?? '';
    final installmentAmount = (item['installmentAmount'] as num?)?.toDouble() ?? 100.0;
    final remainingAmount = (item['remainingAmount'] as num?)?.toDouble() ?? 0.0;
    final freq = item['frequency']?.toString() ?? 'DAILY';

    final amountController = TextEditingController(text: installmentAmount.toStringAsFixed(0));
    final noteController = TextEditingController();
    String paymentMethod = 'CASH';
    bool isSubmitting = false;

    AppBottomSheet.show(
      context: context,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return AppBottomSheet(
              title: 'Record Collection',
              subtitle: '$custName • $accNumber',
              icon: AppIcons.coins,
              iconColor: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Borrower & Balance Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              custName,
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text('$custCode • $custPhone', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Remaining Balance', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                            Text(
                              CurrencyFormatter.format(remainingAmount),
                              style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Amount Input
                  const Text('Collection Amount (₹)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary),
                    decoration: const InputDecoration(
                      prefixText: '₹ ',
                      prefixStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 10),

                  // Fast Amount Quick Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFastAmountChip('1x ($freq)', installmentAmount, amountController, setSheetState),
                      _buildFastAmountChip('2x Due', installmentAmount * 2, amountController, setSheetState),
                      _buildFastAmountChip('+₹100', (double.tryParse(amountController.text) ?? installmentAmount) + 100, amountController, setSheetState),
                      _buildFastAmountChip('Full Balance', remainingAmount, amountController, setSheetState),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Payment Method Selector
                  const Text('Payment Mode', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMethodButton('CASH', AppIcons.banknote, paymentMethod == 'CASH', () {
                          setSheetState(() => paymentMethod = 'CASH');
                        }),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMethodButton('UPI / QR', AppIcons.qrCode, paymentMethod == 'UPI', () {
                          setSheetState(() => paymentMethod = 'UPI');
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Note Field
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      hintText: 'Optional remark (e.g. Received at shop)...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Confirm Collect Button
                  AppButton(
                    label: 'Confirm & Collect ₹${amountController.text}',
                    icon: AppIcons.checkCircle2,
                    isLoading: isSubmitting,
                    onPressed: () async {
                      final val = double.tryParse(amountController.text.trim());
                      if (val == null || val <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid collection amount')),
                        );
                        return;
                      }

                      setSheetState(() => isSubmitting = true);

                      final res = await _apiClient.post(
                        ApiEndpoints.recordCollection,
                        data: {
                          'financeAccountId': accountId,
                          'amount': val,
                          'paymentMethod': paymentMethod == 'UPI' ? 'UPI' : 'CASH',
                          'notes': noteController.text.trim(),
                        },
                      );

                      setSheetState(() => isSubmitting = false);

                      if (res.success && res.data != null) {
                        if (context.mounted) Navigator.pop(sheetCtx);
                        _fetchCollectionData();
                        if (context.mounted) {
                          _showSuccessReceiptBottomSheet(res.data as Map<String, dynamic>, custPhone, custName);
                        }
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
            );
          },
        );
      },
    );
  }

  Widget _buildFastAmountChip(String label, double amount, TextEditingController controller, StateSetter setModalState) {
    return InkWell(
      onTap: () {
        setModalState(() {
          controller.text = amount.toStringAsFixed(0);
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          '$label (₹${amount.toInt()})',
          style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildMethodButton(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessReceiptBottomSheet(Map<String, dynamic> data, String phone, String name) {
    final receipt = data['receipt'] as Map<String, dynamic>? ?? {};
    final receiptNumber = receipt['receiptNumber']?.toString() ?? 'REC-2026';
    final amountPaid = receipt['amountPaid'] ?? 0;
    final remainingBalance = receipt['remainingBalance'] ?? 0;
    final whatsappMessage = receipt['formattedWhatsAppMessage']?.toString() ??
        'Payment of ₹$amountPaid received successfully for $name. Remaining Balance: ₹$remainingBalance. Receipt: $receiptNumber.';

    AppBottomSheet.show(
      context: context,
      builder: (ctx) => AppBottomSheet(
        title: 'Payment Recorded! 🎉',
        subtitle: 'Digital Receipt Generated',
        icon: AppIcons.checkCheck,
        iconColor: AppColors.primary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Text('AMOUNT RECEIVED', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(amountPaid),
                    style: const TextStyle(color: AppColors.primary, fontSize: 30, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Receipt Number:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      Text(receiptNumber, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Remaining Balance:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      Text(CurrencyFormatter.format(remainingBalance), style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // WhatsApp Share Action
            ElevatedButton.icon(
              onPressed: () => _sendWhatsAppReceipt(phone, whatsappMessage),
              icon: const Icon(AppIcons.messageCircle, size: 18, color: Colors.white),
              label: const Text('Share WhatsApp Receipt', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),

            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done', style: TextStyle(color: AppColors.textPrimary)),
            ),
          ],
        ),
      ),
    );
  }

  void _callCustomer(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final url = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _sendWhatsAppReceipt(String phone, String msg) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final targetPhone = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
    final url = Uri.parse('https://wa.me/$targetPhone?text=${Uri.encodeComponent(msg)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _whatsappCustomer(String phone, String name, double due) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final targetPhone = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
    final msg = 'Hello $name, this is a reminder regarding your daily collection installment of ₹${due.toInt()}. Please keep it ready for collection. Thank you!';
    final url = Uri.parse('https://wa.me/$targetPhone?text=${Uri.encodeComponent(msg)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final branchState = context.watch<BranchCubit>().state;
    final currentBranchId = branchState.activeBranchId;

    if (_lastLoadedBranchId != 'INIT' && _lastLoadedBranchId != currentBranchId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fetchAgents(currentBranchId);
          _fetchCollectionData(currentBranchId);
        }
      });
    }

    final isAdminOrManager = authState is Authenticated && (authState.role == 'COMPANY_ADMIN' || authState.role == 'SUPER_ADMIN' || authState.role == 'MANAGER');
    final companyName = authState is Authenticated ? authState.companyName ?? 'Finance SaaS' : 'Finance SaaS';

    final filteredList = _filteredList;
    final progress = _totalExpectedToday > 0 ? (_totalCollectedToday / _totalExpectedToday).clamp(0.0, 1.0) : 0.0;
    final isToday = DateFormat('yyyy-MM-dd').format(_selectedDate) == DateFormat('yyyy-MM-dd').format(DateTime.now());

    return RefreshIndicator(
      onRefresh: () => _fetchCollectionData(currentBranchId),
      color: AppColors.primary,
      child: Column(
        children: [
          // 1. Live Operations Hero Card (Progress, Date, Cashbook & Branch)
          Container(
            margin: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top Header Row inside Hero Card
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(AppIcons.zap, size: 15, color: Color(0xFF60A5FA)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                !branchState.isAllBranches
                                    ? branchState.activeBranchName
                                    : (isToday ? "TODAY'S PROGRESS" : "DATE PROGRESS"),
                                style: const TextStyle(color: Color(0xFFBFDBFE), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          InkWell(
                            onTap: _isGeneratingPdf ? null : () => _downloadPdfReport(companyName),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  _isGeneratingPdf
                                      ? const SizedBox(
                                          width: 10,
                                          height: 10,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDark),
                                        )
                                      : const Icon(AppIcons.download, size: 12, color: AppColors.primaryDark),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'PDF Report',
                                    style: TextStyle(color: AppColors.primaryDark, fontSize: 10.5, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${(progress * 100).toInt()}% Done',
                              style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Metrics Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Collected', style: TextStyle(color: Color(0xFFDBEAFE), fontSize: 11)),
                          Text(
                            CurrencyFormatter.format(_totalCollectedToday),
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text('Pending Due', style: TextStyle(color: Color(0xFFDBEAFE), fontSize: 11)),
                          Text(
                            CurrencyFormatter.format((_totalExpectedToday - _totalCollectedToday).clamp(0, double.infinity)),
                            style: const TextStyle(color: Color(0xFFFDE047), fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Expected Target', style: TextStyle(color: Color(0xFFDBEAFE), fontSize: 11)),
                          Text(
                            CurrencyFormatter.format(_totalExpectedToday),
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF60A5FA)),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Integrated Date Picker & Cashbook Strip Container
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(AppIcons.chevronLeft, size: 16, color: Colors.white),
                            tooltip: 'Previous Day',
                            onPressed: () => _shiftDate(-1),
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            padding: EdgeInsets.zero,
                          ),
                          InkWell(
                            onTap: () => _selectDate(context),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(AppIcons.calendar, size: 13, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Text(
                                    isToday
                                        ? 'Today (${DateFormat('dd MMM yyyy').format(_selectedDate)})'
                                        : DateFormat('dd MMM yyyy (EEEE)').format(_selectedDate),
                                    style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_drop_down, size: 14, color: Colors.white70),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(AppIcons.chevronRight, size: 16, color: Colors.white),
                            tooltip: 'Next Day',
                            onPressed: () => _shiftDate(1),
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildQuickDateJumpPill(
                            'Yesterday',
                            DateTime.now().subtract(const Duration(days: 1)),
                          ),
                          const SizedBox(width: 6),
                          _buildQuickDateJumpPill(
                            'Today',
                            DateTime.now(),
                          ),
                          const SizedBox(width: 6),
                          _buildQuickDateJumpPill(
                            'Tomorrow',
                            DateTime.now().add(const Duration(days: 1)),
                          ),
                        ],
                      ),
                      if (_todayExpenses > 0 || _todayCashInjections > 0 || _totalCollectedToday > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text('Injections: +₹${_todayCashInjections.toInt()}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF93C5FD), fontWeight: FontWeight.bold)),
                            Text('Expenses: -₹${_todayExpenses.toInt()}', style: const TextStyle(fontSize: 10.5, color: Color(0xFFFCA5A5), fontWeight: FontWeight.bold)),
                            Text('Net Cash: ₹${_netCashInHand > 0 ? _netCashInHand.toInt() : (_totalCollectedToday + _todayCashInjections - _todayExpenses).toInt()}', style: const TextStyle(fontSize: 11, color: Color(0xFF86EFAC), fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Agent Field Quick Actions Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildActionButton('+ Borrower', AppIcons.userPlus, AppColors.primary, () => _openRegisterBorrowerModal()),
                  const SizedBox(width: 6),
                  _buildActionButton('+ Give Loan', AppIcons.coins, const Color(0xFF15803D), () => _openDisburseLoanModal()),
                  const SizedBox(width: 6),
                  _buildActionButton('+ Expense', AppIcons.receipt, const Color(0xFFEA580C), () => _openAddExpenseModal(isInjection: false)),
                  const SizedBox(width: 6),
                  _buildActionButton('+ Cash Handover', AppIcons.wallet, const Color(0xFF0284C7), () => _openAddExpenseModal(isInjection: true)),
                ],
              ),
            ),
          ),

          // 3. Interactive Status Filter Tab Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusTab('All (${_allCollectionItems.length})', 'ALL', null),
                  const SizedBox(width: 6),
                  _buildStatusTab('Pending ($_pendingCount)', 'PENDING', AppColors.warning),
                  const SizedBox(width: 6),
                  _buildStatusTab('Paid ($_paidCount)', 'PAID', AppColors.success),
                  if (_overdueCount > 0) ...[
                    const SizedBox(width: 6),
                    _buildStatusTab('Overdue ($_overdueCount)', 'OVERDUE', AppColors.danger),
                  ],
                ],
              ),
            ),
          ),

          // 4. Search & Line / Staff Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search borrower, phone, code or account...',
                          prefixIcon: const Icon(AppIcons.search, size: 16, color: AppColors.textMuted),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(AppIcons.x, size: 14, color: AppColors.textMuted),
                                  onPressed: () {
                                    setState(() => _searchQuery = '');
                                    _fetchCollectionData();
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                        onChanged: (val) {
                          _searchQuery = val;
                          _fetchCollectionData();
                        },
                      ),
                    ),
                    if (isAdminOrManager && _availableAgents.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _selectedAgentId,
                            isDense: true,
                            hint: const Text('All Staff', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            icon: const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.textMuted),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('All Staff', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              ..._availableAgents.map((ag) {
                                final u = ag['userId'] as Map<String, dynamic>?;
                                final agName = u?['name']?.toString() ?? ag['name']?.toString() ?? ag['agentCode']?.toString() ?? 'Staff';
                                final agentValue = ag['_id']?.toString();
                                return DropdownMenuItem<String?>(
                                  value: agentValue,
                                  child: Text(agName, style: const TextStyle(fontSize: 12)),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedAgentId = val);
                              _fetchCollectionData();
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (_availableRoutes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 28,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildRouteFilterChip('All Lines', null),
                        ..._availableRoutes.map((r) => _buildRouteFilterChip(r, r)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 4),
              ],
            ),
          ),

          // 5. Collection Accounts List
          Expanded(
            child: _isLoading
                ? ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    itemCount: 5,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, __) => const ShimmerListTile(),
                  )
                : filteredList.isEmpty
                    ? AppEmptyState(
                        title: _selectedStatusFilter == 'PENDING'
                            ? 'All Collections Cleared! 🎉'
                            : 'No Collection Records Found',
                        subtitle: _selectedStatusFilter == 'PENDING'
                            ? 'Great job! All borrowers on this sheet have completed their payment for this date.'
                            : 'No borrowers match your active date, staff or route filters.',
                        icon: _selectedStatusFilter == 'PENDING' ? AppIcons.checkCheck : AppIcons.userX,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        itemCount: filteredList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = filteredList[index] as Map<String, dynamic>;
                          final cust = item['customer'] as Map<String, dynamic>? ?? {};
                          final name = cust['name']?.toString() ?? 'Borrower';
                          final code = cust['customerCode']?.toString() ?? '';
                          final phone = cust['phone']?.toString() ?? '';
                          final route = cust['address']?['routeArea']?.toString() ?? 'General Line';

                          final accNo = item['accountNumber']?.toString() ?? '';
                          final accId = item['accountId']?.toString() ?? item['_id']?.toString() ?? '';
                          final dueAmount = (item['installmentAmount'] as num?)?.toDouble() ?? 0.0;
                          final remaining = (item['remainingAmount'] as num?)?.toDouble() ?? 0.0;
                          final freq = item['frequency']?.toString() ?? 'DAILY';

                          final todayPaidAmount = (item['todayPaidAmount'] as num?)?.toDouble() ?? 0.0;
                          final overdueCount = (item['overdueCount'] as num?)?.toInt() ?? 0;
                          final remainingPendingDue = (item['remainingPendingDue'] as num?)?.toDouble() ?? 
                              (item['isPaidToday'] == true ? 0.0 : dueAmount);
                          final isFullyPaidUpToDate = remainingPendingDue <= 0 && (todayPaidAmount > 0 || item['isFullyPaidUpToDate'] == true);
                          final isOverdue = overdueCount > 0 || (item['isOverdue'] == true && remainingPendingDue > 0);

                          final collector = item['todayCollector'] as Map<String, dynamic>?;
                          final collectorName = collector?['name']?.toString() ?? 'Staff';
                          final receiptNo = item['todayReceiptNumber']?.toString() ?? '';
                          final paymentTime = item['todayPaymentTime'] != null ? DateFormatter.format(item['todayPaymentTime'], pattern: 'hh:mm a') : '';
                          final payMethod = item['todayPaymentMethod']?.toString() ?? 'CASH';

                          return InkWell(
                            onTap: () => CustomerLoanScheduleSheet.show(
                              context,
                              accountId: accId,
                              accountSummary: item,
                              isAgent: true,
                              onCollectPressed: (accItem) => _openCollectionBottomSheet(accItem),
                            ),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isFullyPaidUpToDate ? const Color(0xFFF0FDF4) : AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isFullyPaidUpToDate
                                      ? const Color(0xFF86EFAC)
                                      : isOverdue
                                          ? AppColors.danger.withValues(alpha: 0.4)
                                          : AppColors.border,
                                  width: isFullyPaidUpToDate ? 1.5 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top Row: Avatar + Name & Code + Status Badge
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: isFullyPaidUpToDate
                                            ? const Color(0xFF22C55E).withValues(alpha: 0.15)
                                            : AppColors.primary.withValues(alpha: 0.15),
                                        child: Text(
                                          name.isNotEmpty ? name[0].toUpperCase() : 'B',
                                          style: TextStyle(
                                            color: isFullyPaidUpToDate ? const Color(0xFF15803D) : AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
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
                                                    name,
                                                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.surfaceCard,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(code, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text('$phone • $route', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (todayPaidAmount > 0) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFDCFCE7),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: const Color(0xFF86EFAC)),
                                              ),
                                              child: Text(
                                                'PAID ₹${todayPaidAmount.toInt()}',
                                                style: const TextStyle(color: Color(0xFF15803D), fontSize: 9.5, fontWeight: FontWeight.w800),
                                              ),
                                            ),
                                            if (remainingPendingDue > 0) const SizedBox(height: 3),
                                          ],
                                          if (remainingPendingDue > 0)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                              decoration: BoxDecoration(
                                                color: overdueCount > 0 ? const Color(0xFFFEE2E2) : AppColors.warning.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                overdueCount > 0 ? '⚠️ OVERDUE ₹${remainingPendingDue.toInt()}' : 'PENDING ₹${remainingPendingDue.toInt()}',
                                                style: TextStyle(
                                                  color: overdueCount > 0 ? AppColors.danger : AppColors.warning,
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Collector Info Box (If Paid Today)
                                  if (todayPaidAmount > 0) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFBBF7D0)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(AppIcons.userCheck, size: 13, color: Color(0xFF15803D)),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              'Collected by: $collectorName',
                                              style: const TextStyle(color: Color(0xFF166534), fontSize: 11, fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '$receiptNo • $payMethod • $paymentTime',
                                            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],

                                  // Middle Row: Due & Balance Box
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: isFullyPaidUpToDate ? Colors.white : AppColors.surfaceCard,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Account: $accNo ($freq)',
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          'Balance: ${CurrencyFormatter.format(remaining)}',
                                          style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w800, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Action Buttons Row
                                  Row(
                                    children: [
                                      if (phone.isNotEmpty) ...[
                                        InkWell(
                                          onTap: () => _callCustomer(phone),
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.all(7),
                                            decoration: BoxDecoration(
                                              color: AppColors.info.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(AppIcons.phone, size: 15, color: AppColors.info),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        InkWell(
                                          onTap: todayPaidAmount > 0
                                              ? () => _sendWhatsAppReceipt(
                                                    phone,
                                                    'Dear $name, Payment of ₹${todayPaidAmount.toInt()} was received successfully. Remaining Balance: ₹${remaining.toInt()}. Receipt: $receiptNo. Thank you!',
                                                  )
                                              : () => _whatsappCustomer(phone, name, remainingPendingDue > 0 ? remainingPendingDue : dueAmount),
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.all(7),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF25D366).withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(AppIcons.messageCircle, size: 15, color: Color(0xFF25D366)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      InkWell(
                                        onTap: () => CustomerLoanScheduleSheet.show(
                                          context,
                                          accountId: accId,
                                          accountSummary: item,
                                          isAgent: true,
                                          onCollectPressed: (accItem) => _openCollectionBottomSheet(accItem),
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceCard,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: AppColors.border),
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(AppIcons.receipt, size: 13, color: AppColors.textSecondary),
                                              SizedBox(width: 4),
                                              Text('Schedule', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _openCollectionBottomSheet(item),
                                          icon: Icon(
                                            isFullyPaidUpToDate ? AppIcons.checkCheck : AppIcons.coins,
                                            size: 15,
                                            color: Colors.white,
                                          ),
                                          label: Text(
                                            remainingPendingDue > 0 ? 'Collect ₹${remainingPendingDue.toInt()}' : 'Collect Advance',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isFullyPaidUpToDate ? const Color(0xFF15803D) : (overdueCount > 0 ? const Color(0xFFDC2626) : AppColors.primary),
                                            padding: const EdgeInsets.symmetric(vertical: 9),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        ),
                                      ),
                                    ],
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

  Widget _buildStatusTab(String label, String filterKey, Color? color) {
    final isSelected = _selectedStatusFilter == filterKey;
    final tabColor = color ?? AppColors.primary;

    return InkWell(
      onTap: () => setState(() => _selectedStatusFilter = filterKey),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? tabColor.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? tabColor : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? tabColor : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 11,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildRouteFilterChip(String label, String? routeValue) {
    final isSelected = _selectedRoute == routeValue;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () {
          setState(() => _selectedRoute = routeValue);
          _fetchCollectionData();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickDateJumpPill(String label, DateTime targetDate) {
    final isSelected = DateFormat('yyyy-MM-dd').format(_selectedDate) == DateFormat('yyyy-MM-dd').format(targetDate);
    return InkWell(
      onTap: () {
        setState(() => _selectedDate = targetDate);
        _fetchCollectionData();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _openRegisterBorrowerModal() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final routeCtrl = TextEditingController(text: _selectedRoute ?? '');
    final streetCtrl = TextEditingController();
    final guarantorNameCtrl = TextEditingController();
    final guarantorPhoneCtrl = TextEditingController();
    final loanAmountCtrl = TextEditingController(text: '10000');

    bool autoDisburse = true;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: Colors.black.withValues(alpha: 0.70),
      backgroundColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 12,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Register New Borrower', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          Text('Onboard customer & disburse loan', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                        ],
                      ),
                      IconButton(onPressed: () => Navigator.pop(sheetCtx), icon: const Icon(AppIcons.x, color: AppColors.textMuted)),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),

                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Borrower Name *', hintText: 'e.g. Sakthi M', prefixIcon: Icon(AppIcons.user, size: 16)),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone Number *', hintText: '10 digit mobile number', prefixIcon: Icon(AppIcons.phone, size: 16)),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: routeCtrl,
                    decoration: const InputDecoration(labelText: 'Route / Line Area *', hintText: 'e.g. Kulithalai', prefixIcon: Icon(AppIcons.mapPin, size: 16)),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: streetCtrl,
                    decoration: const InputDecoration(labelText: 'Street Address (Optional)', hintText: 'Door No, Street Name', prefixIcon: Icon(Icons.home_outlined, size: 16)),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: guarantorNameCtrl,
                          decoration: const InputDecoration(labelText: 'Guarantor Name', hintText: 'Guarantor Name'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: guarantorPhoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Guarantor Phone', hintText: 'Phone'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: autoDisburse,
                          onChanged: (v) => setSheetState(() => autoDisburse = v ?? true),
                          activeColor: AppColors.primary,
                        ),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Give Loan Immediately', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                              Text('Auto-disburse standard 100-day loan scheme', style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (autoDisburse) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: loanAmountCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        labelText: 'Loan Principal Amount (₹) *',
                        prefixText: '₹ ',
                        hintText: '10000',
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final name = nameCtrl.text.trim();
                              final phone = phoneCtrl.text.trim();
                              final route = routeCtrl.text.trim();

                              if (name.isEmpty || phone.isEmpty || route.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter Borrower Name, Phone & Route Area.')),
                                );
                                return;
                              }

                              setSheetState(() => isSubmitting = true);

                              String? schemeId;
                              if (autoDisburse) {
                                final prodsRes = await _apiClient.get(ApiEndpoints.financeProducts);
                                if (prodsRes.success && prodsRes.data is List && (prodsRes.data as List).isNotEmpty) {
                                  schemeId = (prodsRes.data as List).first['_id']?.toString();
                                } else {
                                  final createSchemeRes = await _apiClient.post(
                                    ApiEndpoints.financeProducts,
                                    data: {
                                      'name': 'Standard 100-Day Micro Finance',
                                      'productCode': 'DAILY-100',
                                      'calculationType': 'DOCUMENTATION_FEE_DEDUCTION',
                                      'frequency': 'DAILY',
                                      'minAmount': 1000,
                                      'maxAmount': 500000,
                                      'docChargePercentage': 5,
                                      'defaultInstallments': 100,
                                      'status': 'ACTIVE',
                                    },
                                  );
                                  if (createSchemeRes.success && createSchemeRes.data != null) {
                                    schemeId = createSchemeRes.data['_id']?.toString();
                                  }
                                }
                              }

                              final principal = double.tryParse(loanAmountCtrl.text.trim()) ?? 10000.0;

                              final createRes = await _apiClient.post(
                                ApiEndpoints.customers,
                                data: {
                                  'name': name,
                                  'phone': phone,
                                  'address': {
                                    'street': streetCtrl.text.trim(),
                                    'routeArea': route,
                                  },
                                  'guarantor': {
                                    'name': guarantorNameCtrl.text.trim(),
                                    'phone': guarantorPhoneCtrl.text.trim(),
                                  },
                                  if (autoDisburse && schemeId != null) ...{
                                    'loanProductId': schemeId,
                                    'loanPrincipalAmount': principal,
                                    'loanStartDate': DateTime.now().toIso8601String(),
                                  },
                                },
                              );

                              setSheetState(() => isSubmitting = false);

                              if (createRes.success) {
                                if (sheetCtx.mounted) {
                                  Navigator.pop(sheetCtx);
                                  ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                    SnackBar(
                                      content: Text(autoDisburse
                                          ? 'Borrower Registered & ₹${principal.toInt()} Loan Disbursed! 🎉'
                                          : 'Borrower Registered Successfully! 🎉'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                  _fetchCollectionData();
                                }
                              } else {
                                if (sheetCtx.mounted) {
                                  ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                    SnackBar(content: Text(createRes.message.isNotEmpty ? createRes.message : 'Registration failed')),
                                  );
                                }
                              }
                            },
                      icon: isSubmitting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(AppIcons.userPlus, size: 18, color: Colors.white),
                      label: Text(
                        isSubmitting ? 'Processing...' : (autoDisburse ? 'Register & Disburse Loan' : 'Register Borrower'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openDisburseLoanModal() async {
    if (_allCollectionItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No borrowers found in active line sheet. Please register a borrower first.')));
      return;
    }

    Map<String, dynamic>? selectedCustItem = _allCollectionItems.first as Map<String, dynamic>;
    final principalCtrl = TextEditingController(text: '10000');
    bool isSaving = false;

    final prodsRes = await _apiClient.get(ApiEndpoints.financeProducts);
    var products = prodsRes.data is List ? prodsRes.data as List<dynamic> : [];

    if (products.isEmpty) {
      final createRes = await _apiClient.post(
        ApiEndpoints.financeProducts,
        data: {
          'name': 'Standard 100-Day Micro Finance',
          'productCode': 'DAILY-100',
          'calculationType': 'DOCUMENTATION_FEE_DEDUCTION',
          'frequency': 'DAILY',
          'minAmount': 1000,
          'maxAmount': 500000,
          'docChargePercentage': 5,
          'defaultInstallments': 100,
          'status': 'ACTIVE',
        },
      );
      if (createRes.success && createRes.data != null) {
        products = [createRes.data];
      }
    }

    if (products.isEmpty) return;
    String? selectedProductId = products.first['_id']?.toString();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: Colors.black.withValues(alpha: 0.70),
      backgroundColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final prod = products.firstWhere((p) => p['_id']?.toString() == selectedProductId, orElse: () => products.first) as Map<String, dynamic>;
          final principal = double.tryParse(principalCtrl.text.trim()) ?? 10000.0;
          final docFeePercent = (prod['docChargePercentage'] as num?)?.toDouble() ?? 5.0;
          final docFee = (principal * docFeePercent) / 100.0;
          final netPayout = principal - docFee;
          final installments = prod['defaultInstallments'] ?? 100;
          final dailyDue = installments > 0 ? (principal / installments).round() : 100;

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 12,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Give New Loan / Disburse', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          Text('Issue loan schedule to borrower', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                        ],
                      ),
                      IconButton(onPressed: () => Navigator.pop(sheetCtx), icon: const Icon(AppIcons.x, color: AppColors.textMuted)),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),

                  const Text('Select Borrower *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                    child: DropdownButton<Map<String, dynamic>>(
                      value: selectedCustItem,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: _allCollectionItems.map((item) {
                        final c = item['customer'] as Map<String, dynamic>? ?? {};
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: item as Map<String, dynamic>,
                          child: Text('${c['name']} (${c['customerCode'] ?? 'CUST'}) • ${c['phone'] ?? ''}', style: const TextStyle(fontSize: 12.5)),
                        );
                      }).toList(),
                      onChanged: (val) => setSheetState(() => selectedCustItem = val),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text('Select Scheme *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                    child: DropdownButton<String>(
                      value: selectedProductId,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: products.map((p) {
                        return DropdownMenuItem<String>(
                          value: p['_id']?.toString(),
                          child: Text('${p['name']} (${p['frequency']})', style: const TextStyle(fontSize: 12.5)),
                        );
                      }).toList(),
                      onChanged: (val) => setSheetState(() => selectedProductId = val),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: principalCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(labelText: 'Principal Amount (₹) *', prefixText: '₹ '),
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Doc Fee ($docFeePercent%):', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
                            Text('- ${CurrencyFormatter.format(docFee)}', style: const TextStyle(color: AppColors.danger, fontSize: 11.5, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Net Disbursed Cash:', style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                            Text(CurrencyFormatter.format(netPayout), style: const TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        const Divider(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Daily Installment ($installments days):', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
                            Text('₹$dailyDue / day', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final targetCust = selectedCustItem!['customer'] as Map<String, dynamic>? ?? {};
                              final targetCustId = targetCust['_id']?.toString() ?? '';
                              if (targetCustId.isEmpty || selectedProductId == null) return;

                              setSheetState(() => isSaving = true);
                              final disburseRes = await _apiClient.post(
                                '${ApiEndpoints.financeAccounts}/disburse',
                                data: {
                                  'customerId': targetCustId,
                                  'productId': selectedProductId,
                                  'principalAmount': principal,
                                  'startDate': DateTime.now().toIso8601String(),
                                },
                              );
                              setSheetState(() => isSaving = false);

                              if (disburseRes.success) {
                                if (sheetCtx.mounted) {
                                  Navigator.pop(sheetCtx);
                                  ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                    SnackBar(content: Text('Loan ₹${principal.toInt()} Disbursed to ${targetCust['name']}! 🎉'), backgroundColor: AppColors.success),
                                  );
                                  _fetchCollectionData();
                                }
                              } else {
                                if (sheetCtx.mounted) {
                                  ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                    SnackBar(content: Text(disburseRes.message.isNotEmpty ? disburseRes.message : 'Disbursal failed')),
                                  );
                                }
                              }
                            },
                      icon: isSaving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(AppIcons.coins, size: 18, color: Colors.white),
                      label: Text(isSaving ? 'Disbursing...' : 'Confirm Disbursal (₹${principal.toInt()})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openAddExpenseModal({bool isInjection = false}) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String category = isInjection ? 'CAPITAL_INVESTMENT' : 'PETROL';
    String paymentMethod = 'CASH';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: Colors.black.withValues(alpha: 0.70),
      backgroundColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 12,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isInjection ? 'Log Cash Handover / Injection' : 'Record Field Expense', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          Text(isInjection ? 'Cash received from Main Office / Admin' : 'Record petrol, tea, repair or line expenses', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                        ],
                      ),
                      IconButton(onPressed: () => Navigator.pop(sheetCtx), icon: const Icon(AppIcons.x, color: AppColors.textMuted)),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),

                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: isInjection ? 'Injection Source / Title *' : 'Expense Title *',
                      hintText: isInjection ? 'e.g. Cash Handover from Admin' : 'e.g. Bike Petrol Allowance',
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(labelText: 'Amount (₹) *', prefixText: '₹ '),
                  ),
                  const SizedBox(height: 12),

                  if (!isInjection) ...[
                    const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                      child: DropdownButton<String>(
                        value: category,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'PETROL', child: Text('Petrol / Vehicle')),
                          DropdownMenuItem(value: 'TEA_SNACKS', child: Text('Tea / Lunch / Food')),
                          DropdownMenuItem(value: 'MAINTENANCE', child: Text('Maintenance / Repair')),
                          DropdownMenuItem(value: 'STATIONERY', child: Text('Office / Printing')),
                          DropdownMenuItem(value: 'MISC', child: Text('Other Line Expense')),
                        ],
                        onChanged: (val) => setSheetState(() => category = val ?? 'PETROL'),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(labelText: 'Notes (Optional)', hintText: 'Remarks'),
                  ),
                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final title = titleCtrl.text.trim();
                              final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;

                              if (title.isEmpty || amount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter valid Title & Amount.')),
                                );
                                return;
                              }

                              setSheetState(() => isSaving = true);
                              final res = await _apiClient.post(
                                ApiEndpoints.expenses,
                                data: {
                                  'title': title,
                                  'amount': amount,
                                  'type': isInjection ? 'CASH_INJECTION' : 'EXPENSE',
                                  'category': category,
                                  'paymentMethod': paymentMethod,
                                  'notes': notesCtrl.text.trim(),
                                  'date': _selectedDate.toIso8601String(),
                                },
                              );
                              setSheetState(() => isSaving = false);

                              if (res.success) {
                                if (sheetCtx.mounted) {
                                  Navigator.pop(sheetCtx);
                                  ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                    SnackBar(
                                      content: Text(isInjection ? 'Cash Injection ₹${amount.toInt()} Recorded! 💰' : 'Expense ₹${amount.toInt()} Saved! 📝'),
                                      backgroundColor: isInjection ? AppColors.success : AppColors.warning,
                                    ),
                                  );
                                  _fetchCashbookData();
                                }
                              } else {
                                if (sheetCtx.mounted) {
                                  ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                    SnackBar(content: Text(res.message.isNotEmpty ? res.message : 'Operation failed')),
                                  );
                                }
                              }
                            },
                      icon: isSaving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Icon(isInjection ? AppIcons.wallet : AppIcons.receipt, size: 18, color: Colors.white),
                      label: Text(isSaving ? 'Saving...' : (isInjection ? 'Log Cash Injection' : 'Save Expense'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isInjection ? const Color(0xFF15803D) : const Color(0xFFEA580C),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
