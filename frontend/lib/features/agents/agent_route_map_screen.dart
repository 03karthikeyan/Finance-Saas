import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';

class AgentRouteMapScreen extends StatefulWidget {
  final String? agentId;
  final String? agentName;
  const AgentRouteMapScreen({super.key, this.agentId, this.agentName});

  @override
  State<AgentRouteMapScreen> createState() => _AgentRouteMapScreenState();
}

class _AgentRouteMapScreenState extends State<AgentRouteMapScreen> {
  bool _isLoading = true;
  List<dynamic> _customers = [];
  String? _error;
  final MapController _mapController = MapController();
  dynamic _selectedCustomer;
  LatLng _center = const LatLng(11.0168, 76.9558);

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = widget.agentId != null
          ? await ApiClient().get(ApiEndpoints.customers, queryParameters: {'assignedAgentId': widget.agentId})
          : await ApiClient().get(ApiEndpoints.agentAssignedCustomers);
      if (res.success && res.data is List) {
        final list = res.data as List;
        if (mounted) {
          setState(() {
            _customers = list;
            _isLoading = false;
            for (final item in list) {
              final cust = item['customer'] as Map<String, dynamic>?;
              final geo = cust?['address']?['geo'] as Map<String, dynamic>?;
              if (geo != null) {
                final lat = (geo['lat'] as num?)?.toDouble();
                final lng = (geo['lng'] as num?)?.toDouble();
                if (lat != null && lng != null) { _center = LatLng(lat, lng); break; }
              }
            }
          });
        }
      } else {
        if (mounted) setState(() { _isLoading = false; _error = 'Failed to load customers'; });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  Color _markerColor(Map<String, dynamic>? account) {
    if (account == null) return AppColors.textMuted;
    if (account['isPaidToday'] == true) return AppColors.success;
    if (account['isOverdue'] == true) return AppColors.danger;
    return AppColors.warning;
  }

  String _markerLabel(Map<String, dynamic>? account) {
    if (account == null) return 'No Loan';
    if (account['isPaidToday'] == true) return 'Paid';
    if (account['isOverdue'] == true) return 'Overdue';
    return 'Pending';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Route Map', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            Text('Tap a pin for customer details', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.primary), onPressed: _loadCustomers),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.map_outlined, size: 56, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: AppColors.textMuted)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadCustomers, child: const Text('Retry')),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _center,
                        initialZoom: 13.0,
                        onTap: (_, __) => setState(() => _selectedCustomer = null),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.mediawavetech.financesaas',
                        ),
                        MarkerLayer(
                          markers: _customers.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final item = entry.value;
                            final cust = item['customer'] as Map<String, dynamic>?;
                            final account = item['activeAccount'] as Map<String, dynamic>?;
                            final geo = cust?['address']?['geo'] as Map<String, dynamic>?;
                            double lat = (geo?['lat'] as num?)?.toDouble() ?? (_center.latitude + (idx * 0.001) - 0.01);
                            double lng = (geo?['lng'] as num?)?.toDouble() ?? (_center.longitude + (idx % 5 * 0.001) - 0.002);
                            final color = _markerColor(account);
                            return Marker(
                              point: LatLng(lat, lng),
                              width: 44,
                              height: 44,
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedCustomer = item),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 2)],
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.person_pin_rounded, color: Colors.white, size: 22),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 12, right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)]),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _legendRow(AppColors.success, 'Paid Today'),
                          const SizedBox(height: 4),
                          _legendRow(AppColors.warning, 'Pending'),
                          const SizedBox(height: 4),
                          _legendRow(AppColors.danger, 'Overdue'),
                          const SizedBox(height: 4),
                          _legendRow(AppColors.textMuted, 'No Active Loan'),
                        ]),
                      ),
                    ),
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: const BoxDecoration(color: AppColors.surface,
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))]),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${_customers.length} Customers on Route',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                            Row(children: [
                              _statPill(AppColors.success, '${_customers.where((c) => c['activeAccount']?['isPaidToday'] == true).length} Paid'),
                              const SizedBox(width: 6),
                              _statPill(AppColors.danger, '${_customers.where((c) => c['activeAccount']?['isOverdue'] == true && c['activeAccount']?['isPaidToday'] != true).length} Overdue'),
                            ]),
                          ],
                        ),
                      ),
                    ),
                    if (_selectedCustomer != null)
                      Positioned(bottom: 64, left: 12, right: 12, child: _buildCustomerCard(_selectedCustomer!)),
                  ],
                ),
    );
  }

  Widget _legendRow(Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _statPill(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildCustomerCard(dynamic item) {
    final cust = item['customer'] as Map<String, dynamic>?;
    final account = item['activeAccount'] as Map<String, dynamic>?;
    final name = cust?['name']?.toString() ?? 'Customer';
    final phone = cust?['phone']?.toString() ?? '';
    final area = cust?['address']?['routeArea']?.toString() ?? '';
    final color = _markerColor(account);
    final label = _markerLabel(account);
    final dueAmt = (account?['installmentAmount'] as num?)?.toDouble() ?? 0.0;
    final paidAmt = (account?['todayPaidAmount'] as num?)?.toDouble() ?? 0.0;
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(Icons.person_rounded, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
              if (phone.isNotEmpty) Text(phone, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              if (area.isNotEmpty) Text(area, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
            ),
            if (account != null) ...[
              const SizedBox(height: 4),
              Text(
                account['isPaidToday'] == true ? '${CurrencyFormatter.format(paidAmt)} Paid' : '${CurrencyFormatter.format(dueAmt)} Due',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ]),
        ]),
      ),
    );
  }
}

