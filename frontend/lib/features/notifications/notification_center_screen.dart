import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/services/notification_service.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final NotificationService _notificationService = NotificationService();
  String _selectedFilter = 'ALL'; // ALL, PAYMENT, SYSTEM, REMINDER
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    await _notificationService.fetchNotifications();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(AppIcons.checkCircle2, size: 20, color: AppColors.primary),
            tooltip: 'Mark All as Read',
            onPressed: () async {
              await _notificationService.markAllAsRead();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications marked as read'), backgroundColor: AppColors.success),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(AppIcons.trash, size: 18, color: AppColors.danger),
            tooltip: 'Clear All',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surfaceElevated,
                  title: const Text('Clear All Notifications?', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  content: const Text('This will delete all notification history.', style: TextStyle(color: AppColors.textSecondary)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Clear All', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await _notificationService.clearAll();
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ValueListenableBuilder<List<AppNotificationItem>>(
        valueListenable: _notificationService.notificationsNotifier,
        builder: (context, allItems, _) {
          final filteredItems = allItems.where((item) {
            if (_selectedFilter == 'ALL') return true;
            if (_selectedFilter == 'PAYMENT') return item.type == 'PAYMENT';
            if (_selectedFilter == 'LOAN') return item.title.contains('Loan') || item.message.contains('Loan');
            return item.type == _selectedFilter;
          }).toList();

          return Column(
            children: [
              // Filter Chips
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                color: AppColors.surface,
                child: Row(
                  children: [
                    _buildFilterChip('All', 'ALL', allItems.length),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      '💰 Collections',
                      'PAYMENT',
                      allItems.where((i) => i.type == 'PAYMENT').length,
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      '📋 Loans',
                      'LOAN',
                      allItems.where((i) => i.title.contains('Loan') || i.message.contains('Loan')).length,
                    ),
                  ],
                ),
              ),

              // Notification List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetch,
                  child: _isLoading && allItems.isEmpty
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : filteredItems.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceCard,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(AppIcons.bell, size: 40, color: AppColors.textMuted),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'No Notifications',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'You\'re all caught up! Important alerts will appear here.',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              itemCount: filteredItems.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final item = filteredItems[index];
                                return _buildNotificationCard(item);
                              },
                            ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String key, int count) {
    final isSelected = _selectedFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = key),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(AppNotificationItem item) {
    final isPayment = item.type == 'PAYMENT' || item.title.contains('Collection');
    final isLoan = item.title.contains('Loan');

    final iconColor = isPayment
        ? AppColors.success
        : isLoan
            ? AppColors.primary
            : AppColors.warning;

    final icon = isPayment
        ? AppIcons.dollarSign
        : isLoan
            ? AppIcons.fileText
            : AppIcons.bell;

    final timeStr = DateFormat('dd MMM, hh:mm a').format(item.createdAt);

    return InkWell(
      onTap: () {
        if (!item.isRead) {
          _notificationService.markAsRead(item.id);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: item.isRead ? AppColors.surfaceCard : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.isRead ? AppColors.border : iconColor.withValues(alpha: 0.5),
            width: item.isRead ? 1 : 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Icon Badge
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),

            // Content Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!item.isRead) ...[
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: iconColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        timeStr,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
