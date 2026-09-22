import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../constants/app_colors.dart';
import '../constants/app_icons.dart';
import '../network/api_client.dart';
import '../storage/storage_service.dart';

class ServerConfigDialog extends StatefulWidget {
  const ServerConfigDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const ServerConfigDialog(),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late final TextEditingController _urlController;
  bool _isTesting = false;
  bool? _testSuccess;
  String? _testStatusMessage;
  int? _latencyMs;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: AppConfig.baseApiUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _applyPreset(String presetUrl) {
    setState(() {
      _urlController.text = presetUrl;
      _testSuccess = null;
      _testStatusMessage = null;
      _latencyMs = null;
    });
  }

  Future<void> _testConnection() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isTesting = true;
      _testSuccess = null;
      _testStatusMessage = null;
      _latencyMs = null;
    });

    final result = await ApiClient().testConnection(url);

    if (!mounted) return;

    setState(() {
      _isTesting = false;
      _testSuccess = result['success'] as bool? ?? false;
      _testStatusMessage = result['message'] as String?;
      _latencyMs = result['latencyMs'] as int?;
    });
  }

  Future<void> _saveAndApply() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    // Persist to storage
    await StorageService().saveBaseApiUrl(url);
    // Update live Dio client
    ApiClient().updateBaseUrl(url);

    if (!mounted) return;

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Server URL updated to: $url'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: isDesktop ? 500 : double.infinity,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(AppIcons.server, color: AppColors.primaryLight, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Server Connection Settings',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Configure IP address for Real Mobile Device',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(AppIcons.x, size: 20, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Presets Selection
              const Text(
                'Quick Presets:',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPresetButton(
                    label: '☁️ Render Cloud',
                    subtitle: 'onrender.com',
                    url: AppConfig.presetRenderCloud,
                    icon: AppIcons.globe,
                  ),
                  _buildPresetButton(
                    label: '🏠 Wi-Fi LAN',
                    subtitle: '192.168.1.33',
                    url: AppConfig.presetWifiLan,
                    icon: AppIcons.wifi,
                  ),
                  _buildPresetButton(
                    label: '🔌 USB / ADB',
                    subtitle: 'localhost',
                    url: AppConfig.presetLocalhost,
                    icon: AppIcons.zap,
                  ),
                  _buildPresetButton(
                    label: '📱 Emulator',
                    subtitle: '10.0.2.2',
                    url: AppConfig.presetEmulator,
                    icon: AppIcons.layoutDashboard,
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Server URL Input Field
              const Text(
                'Base API URL',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _urlController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: 'http://192.168.x.x:5000/api/v1',
                  prefixIcon: const Icon(AppIcons.server, size: 18, color: AppColors.textMuted),
                  suffixIcon: IconButton(
                    icon: const Icon(AppIcons.refreshCw, size: 16, color: AppColors.textMuted),
                    tooltip: 'Reset to default',
                    onPressed: () => _applyPreset(AppConfig.presetWifiLan),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),

              // Test Connection Button & Result Box
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _isTesting ? null : _testConnection,
                    icon: _isTesting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryLight),
                          )
                        : const Icon(AppIcons.zap, size: 16, color: AppColors.primaryLight),
                    label: Text(
                      _isTesting ? 'Testing...' : 'Test Connection',
                      style: const TextStyle(color: AppColors.primaryLight, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_latencyMs != null)
                    Text(
                      'Latency: ${_latencyMs}ms',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                ],
              ),

              // Test Result Feedback Banner
              if (_testStatusMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (_testSuccess ?? false)
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (_testSuccess ?? false)
                          ? AppColors.success.withValues(alpha: 0.4)
                          : AppColors.danger.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        (_testSuccess ?? false) ? AppIcons.checkCircle2 : AppIcons.alertCircle,
                        size: 18,
                        color: (_testSuccess ?? false) ? AppColors.success : AppColors.danger,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _testStatusMessage!,
                          style: TextStyle(
                            color: (_testSuccess ?? false) ? AppColors.textPrimary : AppColors.danger,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Help / Tips Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Tips for Real Device Connection:',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• Ensure both your PC and Mobile phone are connected to the SAME Wi-Fi network.\n• For USB testing: run "adb reverse tcp:5000 tcp:5000" in PC PowerShell and select "USB / ADB".',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.4),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _saveAndApply,
                    icon: const Icon(AppIcons.check, size: 16),
                    label: const Text('Save & Apply'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetButton({
    required String label,
    required String subtitle,
    required String url,
    required IconData icon,
  }) {
    final isSelected = _urlController.text == url;
    return InkWell(
      onTap: () => _applyPreset(url),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.25) : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryLight : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? AppColors.primaryLight : AppColors.textMuted),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isSelected ? AppColors.primaryLight : AppColors.textMuted,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
