import 'package:flutter/material.dart';
import '../constants/app_icons.dart';
import '../constants/app_colors.dart';
import '../constants/api_endpoints.dart';
import '../network/api_client.dart';
import '../utils/formatters.dart';
export 'app_image_picker.dart';
export 'app_avatar.dart';

/// Compact Modern Metric Card for 2-Column Mobile Grid
class StatMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final String? badgeText;
  final Color? badgeColor;
  final VoidCallback? onTap;

  const StatMetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor = AppColors.primary,
    this.badgeText,
    this.badgeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: iconColor),
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (badgeColor ?? AppColors.primary).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      badgeText!,
                      style: TextStyle(
                        color: badgeColor ?? AppColors.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Hero Target & Collection Progress Banner Card
class HeroTargetCard extends StatelessWidget {
  final String title;
  final double collectedAmount;
  final double targetAmount;
  final int completedTransactions;
  final VoidCallback? onQuickCollect;
  final VoidCallback? onViewDetails;

  const HeroTargetCard({
    super.key,
    required this.title,
    required this.collectedAmount,
    required this.targetAmount,
    required this.completedTransactions,
    this.onQuickCollect,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTarget = targetAmount > 0 ? targetAmount : 1.0;
    final progress = (collectedAmount / effectiveTarget).clamp(0.0, 1.0);
    final percentage = (progress * 100).toInt();

    return InkWell(
      onTap: onViewDetails,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: AppColors.heroGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.25),
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
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF60A5FA), // Light Blue
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF93C5FD),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$percentage% Reached',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Collected Today', style: TextStyle(color: Color(0xFFBFDBFE), fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      '₹${collectedAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                if (onQuickCollect != null)
                  ElevatedButton.icon(
                    onPressed: onQuickCollect,
                    icon: const Icon(AppIcons.zap, size: 15, color: AppColors.primaryDark),
                    label: const Text('Collect', style: TextStyle(color: AppColors.primaryDark, fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF60A5FA)),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '$completedTransactions collections recorded',
                      style: const TextStyle(color: Color(0xFFDBEAFE), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFF93C5FD)),
                  ],
                ),
                Text(
                  'Target: ₹${targetAmount.toStringAsFixed(0)}',
                  style: const TextStyle(color: Color(0xFFBFDBFE), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular Quick Action Item for Android Dashboard Grid
class QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const QuickActionButton({
    super.key,
    required this.label,
    required this.icon,
    this.color = AppColors.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Status Chip / Pill Badge
class StatusBadge extends StatelessWidget {
  final String status;
  final bool isSmall;

  const StatusBadge({super.key, required this.status, this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;

    switch (status.toUpperCase()) {
      case 'ACTIVE':
      case 'PAID':
      case 'SUCCESS':
      case 'COMPLETED':
      case 'VERIFIED_SETTLED':
        bg = AppColors.success.withValues(alpha: 0.1);
        text = AppColors.success;
        break;
      case 'PENDING':
      case 'UPCOMING':
      case 'DUE':
      case 'PARTIALLY_PAID':
      case 'PENDING_HANDOVER':
      case 'WEEKLY':
        bg = AppColors.warning.withValues(alpha: 0.1);
        text = AppColors.warning;
        break;
      case 'OVERDUE':
      case 'CANCELLED':
      case 'FAILED':
      case 'SUSPENDED':
      case 'BLOCKED':
        bg = AppColors.danger.withValues(alpha: 0.1);
        text = AppColors.danger;
        break;
      case 'DAILY':
        bg = AppColors.primary.withValues(alpha: 0.1);
        text = AppColors.primary;
        break;
      case 'MONTHLY':
        bg = AppColors.accentIndigo.withValues(alpha: 0.1);
        text = AppColors.accentIndigo;
        break;
      default:
        bg = AppColors.surfaceCard;
        text = AppColors.textSecondary;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 7 : 10,
        vertical: isSmall ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: text.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          color: text,
          fontSize: isSmall ? 10 : 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Styled Action Button
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isOutlined;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.isOutlined = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isOutlined ? Colors.transparent : (backgroundColor ?? AppColors.primary);
    final fg = isOutlined ? (textColor ?? AppColors.primary) : (textColor ?? Colors.white);

    final btnStyle = ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      side: isOutlined ? BorderSide(color: backgroundColor ?? AppColors.primary) : null,
      elevation: isOutlined ? 0 : 1,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    Widget child = isLoading
        ? SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: isOutlined ? AppColors.primary : Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: fg),
              ),
            ],
          );

    return SizedBox(
      width: width,
      child: ElevatedButton(
        style: btnStyle,
        onPressed: isLoading ? null : onPressed,
        child: child,
      ),
    );
  }
}

/// Standard Android Material 3 Bottom Sheet Container Wrapper
class AppBottomSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Widget child;

  const AppBottomSheet({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    required this.child,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = true,
    bool useSafeArea = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      barrierColor: Colors.black.withValues(alpha: 0.70),
      backgroundColor: Colors.transparent,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: builder(ctx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Visual Top Handle
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

              // Header
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 18, color: iconColor ?? AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(AppIcons.x, size: 20, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: AppColors.border, height: 24),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Loading Indicator
class AppLoading extends StatelessWidget {
  final String? message;
  const AppLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
          if (message != null) ...[
            const SizedBox(height: 14),
            Text(
              message!,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }
}

/// Empty State Display
class AppEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? action;

  const AppEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = AppIcons.inbox,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, size: 34, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Borrower Full Ledger & Profile Sheet
class BorrowerLedgerSheet extends StatefulWidget {
  final String customerId;
  const BorrowerLedgerSheet({super.key, required this.customerId});

  static void show(BuildContext context, String customerId) {
    AppBottomSheet.show(
      context: context,
      builder: (_) => BorrowerLedgerSheet(customerId: customerId),
    );
  }

  @override
  State<BorrowerLedgerSheet> createState() => _BorrowerLedgerSheetState();
}

class _BorrowerLedgerSheetState extends State<BorrowerLedgerSheet> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() => _isLoading = true);
    final res = await _apiClient.get('${ApiEndpoints.customers}/${widget.customerId}');
    if (res.success && res.data is Map<String, dynamic>) {
      setState(() {
        _data = res.data as Map<String, dynamic>;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AppBottomSheet(
        title: 'Borrower Ledger',
        subtitle: 'Loading profile and loan history...',
        icon: AppIcons.userCheck,
        iconColor: AppColors.primary,
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ),
      );
    }

    final cust = _data?['customer'] as Map<String, dynamic>? ?? {};
    final accounts = (_data?['accounts'] as List<dynamic>?) ?? [];
    final payments = (_data?['recentPayments'] as List<dynamic>?) ?? [];

    final name = cust['name']?.toString() ?? 'Borrower';
    final code = cust['customerCode']?.toString() ?? '';
    final phone = cust['phone']?.toString() ?? '';
    final altPhone = cust['alternatePhone']?.toString() ?? '';
    final addr = cust['address'] as Map<String, dynamic>? ?? {};
    final route = addr['routeArea']?.toString() ?? 'Default Line';
    final street = addr['street']?.toString() ?? '';
    final guarantor = cust['guarantor'] as Map<String, dynamic>? ?? {};
    final gName = guarantor['name']?.toString() ?? '';
    final gPhone = guarantor['phone']?.toString() ?? '';

    return AppBottomSheet(
      title: name,
      subtitle: '$code • Route: $route',
      icon: AppIcons.userCheck,
      iconColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Contact & Guarantor Info Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Phone: $phone ${altPhone.isNotEmpty ? " / $altPhone" : ""}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(route, style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                if (street.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Address: $street', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ),
                ],
                if (gName.isNotEmpty) ...[
                  const Divider(color: AppColors.border, height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Guarantor: $gName', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      Text(gPhone, style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Loan Accounts Section
          const Text('Active & Historical Loans', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (accounts.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(10)),
              child: const Text('No loan accounts on record.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            )
          else
            ...accounts.map((acc) {
              final accNo = acc['accountNumber']?.toString() ?? '';
              final principal = (acc['principalAmount'] as num?)?.toDouble() ?? 0.0;
              final remaining = (acc['remainingAmount'] as num?)?.toDouble() ?? 0.0;
              final paid = (acc['totalPaidAmount'] as num?)?.toDouble() ?? 0.0;
              final status = acc['status']?.toString() ?? 'ACTIVE';
              final freq = acc['frequency']?.toString() ?? 'DAILY';
              final instAmt = (acc['installmentAmount'] as num?)?.toDouble() ?? 0.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(accNo, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                        StatusBadge(status: status, isSmall: true),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Principal: ${CurrencyFormatter.format(principal)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        Text('EMI: ${CurrencyFormatter.format(instAmt)} / $freq', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Paid: ${CurrencyFormatter.format(paid)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11)),
                        Text('Remaining: ${CurrencyFormatter.format(remaining)}', style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 16),

          // Payment History Section
          const Text('Recent Payment Ledger', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (payments.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(10)),
              child: const Text('No payment history recorded yet.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            )
          else
            ...payments.map((p) {
              final amt = (p['amount'] as num?)?.toDouble() ?? 0.0;
              final dateStr = p['paymentDate']?.toString() ?? '';
              final method = p['paymentMethod']?.toString() ?? 'CASH';
              final receipt = p['receiptNumber']?.toString() ?? 'RC-000';

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$receipt • $method', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11)),
                        Text(DateFormatter.formatDate(dateStr), style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                      ],
                    ),
                    Text('+ ${CurrencyFormatter.format(amt)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w800, fontSize: 13)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

/// Interactive Today's Collections Sheet with Agent Attribution
class TodayCollectionActivitySheet extends StatefulWidget {
  const TodayCollectionActivitySheet({super.key});

  static void show(BuildContext context) {
    AppBottomSheet.show(
      context: context,
      builder: (_) => const TodayCollectionActivitySheet(),
    );
  }

  @override
  State<TodayCollectionActivitySheet> createState() => _TodayCollectionActivitySheetState();
}

class _TodayCollectionActivitySheetState extends State<TodayCollectionActivitySheet> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _payments = [];

  @override
  void initState() {
    super.initState();
    _fetchTodayCollections();
  }

  Future<void> _fetchTodayCollections() async {
    setState(() => _isLoading = true);
    final res = await _apiClient.get(ApiEndpoints.todayCollections);
    if (res.success && res.data is List) {
      setState(() {
        _payments = res.data as List<dynamic>;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AppBottomSheet(
        title: "Today's Collection Activity",
        subtitle: "Fetching real-time transactions...",
        icon: AppIcons.badgeCheck,
        iconColor: AppColors.primary,
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ),
      );
    }

    final totalAmount = _payments.fold<double>(0.0, (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0.0));

    return AppBottomSheet(
      title: "Today's Collections",
      subtitle: '${_payments.length} collections • Total: ${CurrencyFormatter.format(totalAmount)}',
      icon: AppIcons.badgeCheck,
      iconColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Total Summary Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Cash Inflow Today', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    Text(CurrencyFormatter.format(totalAmount), style: const TextStyle(color: AppColors.primaryDark, fontSize: 18, fontWeight: FontWeight.w800)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text('${_payments.length} Receipts', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // List of Collected Payments
          if (_payments.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: const Text('No collections recorded yet today.\nUse Quick Collect to collect installments.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            )
          else
            ..._payments.map((p) {
              final cust = p['customerId'] as Map<String, dynamic>?;
              final custName = cust?['name']?.toString() ?? 'Borrower';
              final custCode = cust?['customerCode']?.toString() ?? '';
              final custId = cust?['_id']?.toString() ?? '';
              final amt = (p['amount'] as num?)?.toDouble() ?? 0.0;
              final method = p['paymentMethod']?.toString() ?? 'CASH';
              final collector = p['collectedById'] as Map<String, dynamic>?;
              final collectorName = collector?['name']?.toString() ?? 'Collector';
              final collectorRole = collector?['role']?.toString() ?? 'STAFF';
              final receipt = p['receiptNumber']?.toString() ?? 'RC-000';
              final dateStr = p['paymentDate']?.toString() ?? '';

              return InkWell(
                onTap: custId.isNotEmpty
                    ? () {
                        Navigator.pop(context);
                        BorrowerLedgerSheet.show(context, custId);
                      }
                    : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
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
                              Text(custName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                              if (custCode.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Text('($custCode)', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                              ],
                            ],
                          ),
                          Text('+ ${CurrencyFormatter.format(amt)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w800, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Receipt: $receipt • Mode: $method', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          Text(DateFormatter.formatDate(dateStr), style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                        ],
                      ),
                      const Divider(color: AppColors.border, height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(AppIcons.userCheck, size: 12, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text('Collected by: $collectorName ($collectorRole)', style: const TextStyle(color: AppColors.primaryDark, fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const Row(
                            children: [
                              Text('View Ledger', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                              Icon(Icons.chevron_right, size: 14, color: AppColors.textMuted),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
