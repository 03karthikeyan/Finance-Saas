import 'package:flutter/material.dart';
import '../../core/localization/app_localization.dart';
import '../../core/network/api_client.dart';

class StaffLedgerScreen extends StatefulWidget {
  const StaffLedgerScreen({super.key});

  @override
  State<StaffLedgerScreen> createState() => _StaffLedgerScreenState();
}

class _StaffLedgerScreenState extends State<StaffLedgerScreen> {
  bool _isLoading = true;
  List<dynamic> _staffList = [];
  List<dynamic> _ledgerEntries = [];
  String? _selectedStaffId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final staffRes = await ApiClient().get('/agents');
      final ledgerRes = await ApiClient().get('/staff-ledger');

      if (mounted) {
        setState(() {
          _staffList = staffRes.data['data']['agents'] ?? [];
          _ledgerEntries = ledgerRes.data['data']['entries'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load staff ledger: $e')),
        );
      }
    }
  }

  void _showAddStaffEntryModal(BuildContext context) {
    String? defaultStaffId = _selectedStaffId;
    if (defaultStaffId == null && _staffList.isNotEmpty) {
      final first = _staffList[0];
      if (first['userId'] is Map) {
        defaultStaffId = first['userId']['_id']?.toString();
      } else {
        defaultStaffId = first['_id']?.toString();
      }
    }

    String? staffId = defaultStaffId;
    String transactionType = 'SALARY_PAYOUT';
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Record Staff Transaction',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: staffId,
                    decoration: InputDecoration(
                      labelText: 'Select Staff Member',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _staffList.map<DropdownMenuItem<String>>((staff) {
                      final id = (staff['userId'] is Map ? staff['userId']['_id'] : null) ?? staff['_id'];
                      final name = (staff['userId'] is Map ? staff['userId']['name'] : null) ?? staff['name'] ?? 'Staff';
                      return DropdownMenuItem(value: id?.toString(), child: Text(name.toString()));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => staffId = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: transactionType,
                    decoration: InputDecoration(
                      labelText: 'Transaction Type',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'SALARY_PAYOUT', child: Text('💵 Salary Payment')),
                      DropdownMenuItem(value: 'ADVANCE_GIVEN', child: Text('⚠️ Salary Advance Given')),
                      DropdownMenuItem(value: 'PETROL_ALLOWANCE', child: Text('⛽ Daily Petrol Allowance')),
                      DropdownMenuItem(value: 'COMMISSION', child: Text('🎯 Collection Commission')),
                      DropdownMenuItem(value: 'ADVANCE_RECOVERY', child: Text('🔄 Advance Recovered')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => transactionType = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount (₹)',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes / Voucher Details',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final amount = double.tryParse(amountController.text.trim());
                        if (staffId == null || amount == null || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select staff and enter valid amount')),
                          );
                          return;
                        }

                        try {
                          await ApiClient().post('/staff-ledger', data: {
                            'staffId': staffId,
                            'transactionType': transactionType,
                            'amount': amount,
                            'notes': notesController.text.trim(),
                          });
                          if (context.mounted) {
                            Navigator.pop(context);
                            _loadData();
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to save staff entry: $e')),
                            );
                          }
                        }
                      },
                      child: const Text('Save Staff Ledger Entry'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLocalization.currentLanguage,
      builder: (context, lang, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalization.get('staff_ledger')),
            elevation: 0,
            actions: [
              IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF1E3A8A),
            onPressed: () => _showAddStaffEntryModal(context),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Entry', style: TextStyle(color: Colors.white)),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'Staff Payouts & Advances Log',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _ledgerEntries.isEmpty
                          ? Card(
                              elevation: 0,
                              color: Colors.grey[100],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: const Padding(
                                padding: EdgeInsets.all(32),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.badge, size: 48, color: Colors.grey),
                                      SizedBox(height: 12),
                                      Text('No staff transactions logged yet.'),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _ledgerEntries.length,
                              itemBuilder: (context, index) {
                                final entry = _ledgerEntries[index];
                                final staffName = entry['staffId']?['name'] ?? 'Staff Member';
                                final type = entry['transactionType'] ?? 'PAYOUT';
                                final amount = (entry['amount'] ?? 0).toDouble();

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blue[50],
                                      child: const Icon(Icons.person, color: Colors.blue),
                                    ),
                                    title: Text(
                                      staffName,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      'Type: $type • ${entry['paymentMethod'] ?? 'CASH'}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: Text(
                                      '₹${amount.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E3A8A),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
