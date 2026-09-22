import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/app_widgets.dart';
import '../authentication/presentation/auth_cubit.dart';

class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;
  bool _isSaving = false;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _regNumCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _supportPhoneCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _receiptNoteCtrl = TextEditingController();
  final _logoUrlCtrl = TextEditingController();

  final List<String> _districts = [
    'Chennai',
    'Coimbatore',
    'Cuddalore',
    'Dharmapuri',
    'Dindigul',
    'Erode',
    'Kallakurichi',
    'Kanchipuram',
    'Kanyakumari',
    'Karur',
    'Krishnagiri',
    'Madurai',
    'Mayiladuthurai',
    'Nagapattinam',
    'Namakkal',
    'Nilgiris',
    'Perambalur',
    'Pudukkottai',
    'Ramanathapuram',
    'Ranipet',
    'Salem',
    'Sivaganga',
    'Tenkasi',
    'Thanjavur',
    'Theni',
    'Thoothukudi',
    'Tiruchirappalli',
    'Tirunelveli',
    'Tirupathur',
    'Tiruppur',
    'Tiruvallur',
    'Tiruvannamalai',
    'Tiruvarur',
    'Vellore',
    'Viluppuram',
    'Virudhunagar',
    'Other District'
  ];

  String _selectedDistrict = 'Tiruchirappalli';

  @override
  void initState() {
    super.initState();
    _fetchCompanyProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _regNumCtrl.dispose();
    _gstCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _supportPhoneCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _receiptNoteCtrl.dispose();
    _logoUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCompanyProfile() async {
    setState(() => _isLoading = true);
    final res = await _apiClient.get(ApiEndpoints.companyProfile);
    setState(() => _isLoading = false);

    if (res.success && res.data is Map) {
      final data = res.data as Map<String, dynamic>;
      final addr = data['address'] as Map<String, dynamic>? ?? {};

      setState(() {
        _nameCtrl.text = data['name']?.toString() ?? '';
        _codeCtrl.text = data['companyCode']?.toString() ?? '';
        _regNumCtrl.text = data['registrationNumber']?.toString() ?? '';
        _gstCtrl.text = data['taxNumber']?.toString() ?? '';
        _phoneCtrl.text = data['phone']?.toString() ?? '';
        _emailCtrl.text = data['email']?.toString() ?? '';
        _supportPhoneCtrl.text = data['supportPhone']?.toString() ?? '';
        _logoUrlCtrl.text = data['logo']?.toString() ?? '';
        _streetCtrl.text = addr['street']?.toString() ?? '';
        _cityCtrl.text = addr['city']?.toString() ?? '';
        _districtCtrl.text = addr['district']?.toString() ?? 'Tiruchirappalli';
        _stateCtrl.text = addr['state']?.toString() ?? 'Tamil Nadu';
        _pincodeCtrl.text = addr['pincode']?.toString() ?? '';
        _receiptNoteCtrl.text = data['receiptFooterNote']?.toString() ??
            'Thank you for your timely repayment! Please collect physical/digital receipt for every installment.';

        if (_districts.contains(_districtCtrl.text)) {
          _selectedDistrict = _districtCtrl.text;
        } else {
          _selectedDistrict = _districts.first;
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _showToast('Company name is required', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    final res = await _apiClient.put(
      ApiEndpoints.companyProfile,
      data: {
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'registrationNumber': _regNumCtrl.text.trim(),
        'taxNumber': _gstCtrl.text.trim(),
        'supportPhone': _supportPhoneCtrl.text.trim(),
        'receiptFooterNote': _receiptNoteCtrl.text.trim(),
        if (_logoUrlCtrl.text.trim().isNotEmpty) 'logo': _logoUrlCtrl.text.trim(),
        'address': {
          'street': _streetCtrl.text.trim(),
          'city': _cityCtrl.text.trim(),
          'district': _selectedDistrict,
          'state': _stateCtrl.text.trim().isEmpty ? 'Tamil Nadu' : _stateCtrl.text.trim(),
          'pincode': _pincodeCtrl.text.trim(),
          'country': 'India',
        },
      },
    );
    setState(() => _isSaving = false);

    if (res.success) {
      if (mounted) {
        context.read<AuthCubit>().updateCompanyInfo(
          name: _nameCtrl.text.trim(),
          logo: _logoUrlCtrl.text.trim(),
        );
      }
      _showToast('Company Profile & Branding updated successfully!', isError: false);
    } else {
      _showToast(res.message, isError: true);
    }
  }

  void _showToast(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // appBar: AppBar(
      //   title: const Text('Company Profile & Branding', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      //   centerTitle: true,
      //   actions: [
      //     TextButton.icon(
      //       onPressed: _isSaving ? null : _saveProfile,
      //       icon: const Icon(AppIcons.check, size: 16, color: AppColors.primary),
      //       label: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
      //     ),
      //     const SizedBox(width: 8),
      //   ],
      // ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Banner Card
                  _buildHeaderCard(),
                  const SizedBox(height: 16),

                  // Section 0: Brand Logo & Visual Emblem
                  _buildSectionCard(
                    title: 'Brand Logo & Visual Identity',
                    icon: AppIcons.sparkles,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            AppAvatar(
                              imageSource: _logoUrlCtrl.text,
                              radius: 32,
                              fallbackIcon: AppIcons.building2,
                              isEditable: true,
                              onTap: () async {
                                final picked = await AppImagePicker.showImageSourceDialog(
                                  context,
                                  title: 'Upload Company Logo',
                                  allowRemove: _logoUrlCtrl.text.trim().isNotEmpty,
                                );
                                if (picked != null) {
                                  setState(() => _logoUrlCtrl.text = picked);
                                }
                              },
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Company Logo & Crest',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Printed on customer collection receipts, PDF reports & app header.',
                                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          final picked = await AppImagePicker.showImageSourceDialog(
                                            context,
                                            title: 'Upload Company Logo',
                                            allowRemove: _logoUrlCtrl.text.trim().isNotEmpty,
                                          );
                                          if (picked != null) {
                                            setState(() => _logoUrlCtrl.text = picked);
                                          }
                                        },
                                        icon: const Icon(Icons.photo_camera_outlined, size: 14, color: Colors.white),
                                        label: Text(
                                          _logoUrlCtrl.text.trim().isNotEmpty ? 'Change Photo' : 'Upload Photo',
                                          style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                      if (_logoUrlCtrl.text.trim().isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        OutlinedButton(
                                          onPressed: () => setState(() => _logoUrlCtrl.clear()),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.danger,
                                            side: const BorderSide(color: AppColors.danger),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: const Text('Remove', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Section 1: Business Identity
                  _buildSectionCard(
                    title: 'Business Identity',
                    icon: AppIcons.building2,
                    children: [
                      TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Finance Company Name *',
                          hintText: 'e.g. Sri Murugan Microfinance',
                          prefixIcon: Icon(AppIcons.building, size: 18, color: AppColors.textMuted),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _codeCtrl,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Company Code',
                                prefixIcon: Icon(AppIcons.badgeCheck, size: 18, color: AppColors.textMuted),
                                helperText: 'Unique Tenant ID',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _regNumCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Registration / MSME No',
                                hintText: 'UDYAM-XX-000000',
                                prefixIcon: Icon(AppIcons.fileSpreadsheet, size: 18, color: AppColors.textMuted),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _gstCtrl,
                        decoration: const InputDecoration(
                          labelText: 'GSTIN / PAN Number',
                          hintText: '33AAAAA0000A1Z5',
                          prefixIcon: Icon(AppIcons.creditCard, size: 18, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Section 2: Registered Office Address
                  _buildSectionCard(
                    title: 'Registered Office Address',
                    icon: AppIcons.calendar,
                    children: [
                      TextField(
                        controller: _streetCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Street Address / Building *',
                          hintText: 'No. 12, Main Road, Gandhi Market',
                          prefixIcon: Icon(AppIcons.building, size: 18, color: AppColors.textMuted),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _cityCtrl,
                              decoration: const InputDecoration(
                                labelText: 'City / Town *',
                                hintText: 'Trichy',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedDistrict,
                                  isExpanded: true,
                                  dropdownColor: AppColors.surfaceElevated,
                                  items: _districts
                                      .map((d) => DropdownMenuItem(
                                            value: d,
                                            child: Text(d, style: const TextStyle(fontSize: 12)),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedDistrict = val);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _stateCtrl,
                              decoration: const InputDecoration(
                                labelText: 'State',
                                hintText: 'Tamil Nadu',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _pincodeCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Pincode *',
                                hintText: '620001',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Section 3: Contact & Support Helplines
                  _buildSectionCard(
                    title: 'Contact & Support',
                    icon: AppIcons.phoneCall,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Primary Office Phone *',
                                hintText: '9876543210',
                                prefixIcon: Icon(AppIcons.phone, size: 18, color: AppColors.textMuted),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _supportPhoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Support WhatsApp',
                                hintText: '9876543210',
                                prefixIcon: Icon(AppIcons.messageCircle, size: 18, color: AppColors.success),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Official Billing Email *',
                          hintText: 'billing@financecompany.com',
                          prefixIcon: Icon(AppIcons.mail, size: 18, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Section 4: Receipt Note & Branding
                  _buildSectionCard(
                    title: 'Receipt & Printing Branding',
                    icon: AppIcons.receipt,
                    children: [
                      TextField(
                        controller: _receiptNoteCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Receipt Footer Message / Terms',
                          hintText: 'Thank you for your timely repayment! Please collect official receipt.',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  AppButton(
                    label: 'Save & Apply Company Branding',
                    icon: AppIcons.checkCircle2,
                    isLoading: _isSaving,
                    onPressed: _saveProfile,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          AppAvatar(
            imageSource: _logoUrlCtrl.text,
            radius: 24,
            fallbackIcon: AppIcons.building2,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            foregroundColor: Colors.white,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Company Branding',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'District: $_selectedDistrict | Multi-Tenant SaaS',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.border, height: 20),
          ...children,
        ],
      ),
    );
  }
}
