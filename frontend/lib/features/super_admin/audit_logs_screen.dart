import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/app_widgets.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _logs = [];

  @override
  void initState() {
    super.initState();
    _fetchAuditLogs();
  }

  Future<void> _fetchAuditLogs() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get(ApiEndpoints.auditLogs);
      if (res.success && res.data is List) {
        setState(() {
          _logs = res.data as List<dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Global System Audit Trail', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(AppIcons.chevronLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAuditLogs,
        color: AppColors.primary,
        child: _isLoading
            ? const AppLoading(message: 'Loading system audit logs...')
            : _logs.isEmpty
                ? const AppEmptyState(
                    title: 'No Audit Logs Recorded',
                    subtitle: 'All tenant creations, logins & critical actions will appear here.',
                    icon: AppIcons.shield,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      final action = log['action']?.toString() ?? 'SYSTEM_EVENT';
                      final userName = log['userName']?.toString() ?? 'System';
                      final role = log['userRole']?.toString() ?? '';
                      final module = log['module']?.toString() ?? '';
                      final createdAt = log['createdAt']?.toString();
                      final timeStr = createdAt != null ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.tryParse(createdAt) ?? DateTime.now()) : '';

                      return Container(
                        padding: const EdgeInsets.all(12),
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
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(AppIcons.shield, color: AppColors.primary, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        action.replaceAll('_', ' '),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.textPrimary),
                                      ),
                                      if (module.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceCard,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(module, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('$userName • ${role.replaceAll("_", " ")}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                  const SizedBox(height: 2),
                                  Text(timeStr, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
