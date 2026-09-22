import 'package:flutter/material.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final ApiClient _apiClient = ApiClient();
  int _currentStep = 1; // 1: Email/Phone, 2: OTP, 3: New Password
  bool _isLoading = false;

  // Step 1 Controllers
  final _identifierController = TextEditingController();

  // Step 2 Controllers
  final _otpController = TextEditingController();
  String? _maskedTarget;
  String? _devOtp;

  // Step 3 Controllers
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _verifiedResetToken;

  @override
  void dispose() {
    _identifierController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Step 1: Request OTP
  Future<void> _requestOtp() async {
    final input = _identifierController.text.trim();
    if (input.isEmpty) {
      _showToast('Please enter your email or phone number', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final res = await _apiClient.post(
      ApiEndpoints.forgotPassword,
      data: {'emailOrPhone': input},
    );
    setState(() => _isLoading = false);

    if (res.success) {
      final data = res.data as Map<String, dynamic>?;
      final devOtp = data?['devOtp']?.toString();
      final masked = data?['emailMasked']?.toString() ?? data?['phoneMasked']?.toString() ?? input;

      setState(() {
        _maskedTarget = masked;
        _devOtp = devOtp;
        _currentStep = 2;
        if (devOtp != null) {
          _otpController.text = devOtp; // Auto-fill for developer/tester ease
        }
      });

      _showToast(res.message, isError: false);
    } else {
      _showToast(res.message, isError: true);
    }
  }

  // Step 2: Verify OTP
  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showToast('Please enter the 6-digit OTP code', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final res = await _apiClient.post(
      ApiEndpoints.verifyResetOtp,
      data: {
        'emailOrPhone': _identifierController.text.trim(),
        'otp': otp,
      },
    );
    setState(() => _isLoading = false);

    if (res.success) {
      final data = res.data as Map<String, dynamic>?;
      final token = data?['resetToken']?.toString();

      setState(() {
        _verifiedResetToken = token;
        _currentStep = 3;
      });

      _showToast('OTP verified! Please create your new password.', isError: false);
    } else {
      _showToast(res.message, isError: true);
    }
  }

  // Step 3: Set New Password
  Future<void> _resetPassword() async {
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (newPass.length < 6) {
      _showToast('Password must be at least 6 characters long', isError: true);
      return;
    }
    if (newPass != confirmPass) {
      _showToast('Passwords do not match', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final res = await _apiClient.post(
      ApiEndpoints.resetPassword,
      data: {
        'emailOrPhone': _identifierController.text.trim(),
        'resetToken': _verifiedResetToken,
        'newPassword': newPass,
      },
    );
    setState(() => _isLoading = false);

    if (res.success) {
      if (!mounted) return;
      _showSuccessDialog();
    } else {
      _showToast(res.message, isError: true);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(AppIcons.checkCircle2, color: AppColors.success, size: 28),
            SizedBox(width: 10),
            Text('Password Reset!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ],
        ),
        content: const Text(
          'Your password has been changed successfully. You can now log in with your new password.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to login screen
            },
            child: const Text('Back to Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reset Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(AppIcons.chevronLeft, color: AppColors.textPrimary),
          onPressed: () {
            if (_currentStep > 1) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Step Progress Indicator
                _buildProgressHeader(),
                const SizedBox(height: 24),

                // Card Container
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _currentStep == 1
                        ? _buildStep1()
                        : _currentStep == 2
                            ? _buildStep2()
                            : _buildStep3(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStepCircle(1, 'Find Account', _currentStep >= 1),
            _buildStepLine(_currentStep >= 2),
            _buildStepCircle(2, 'Verify OTP', _currentStep >= 2),
            _buildStepLine(_currentStep >= 3),
            _buildStepCircle(3, 'New Password', _currentStep >= 3),
          ],
        ),
      ],
    );
  }

  Widget _buildStepCircle(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primary : AppColors.surfaceCard,
            border: Border.all(color: isActive ? AppColors.primary : AppColors.border, width: 2),
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.textMuted,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.textPrimary : AppColors.textMuted,
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 18),
      color: isActive ? AppColors.primary : AppColors.border,
    );
  }

  // STEP 1: Enter Email or Phone
  Widget _buildStep1() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(AppIcons.lock, size: 42, color: AppColors.primary),
        const SizedBox(height: 12),
        const Text(
          'Forgot Your Password?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          'Enter your registered email address or phone number to receive a 6-digit password reset OTP.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _identifierController,
          decoration: const InputDecoration(
            labelText: 'Email or Mobile Phone *',
            hintText: 'e.g. agent@company.com or 9876543210',
            prefixIcon: Icon(AppIcons.mail, size: 18, color: AppColors.textMuted),
          ),
        ),
        const SizedBox(height: 22),
        AppButton(
          label: 'Send Verification OTP',
          icon: AppIcons.send,
          isLoading: _isLoading,
          onPressed: _requestOtp,
        ),
      ],
    );
  }

  // STEP 2: Enter OTP Code
  Widget _buildStep2() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(AppIcons.shield, size: 42, color: AppColors.warning),
        const SizedBox(height: 12),
        const Text(
          'Enter 6-Digit OTP',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          'We sent a one-time verification code to $_maskedTarget',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        if (_devOtp != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(AppIcons.info, size: 13, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('Test Code: $_devOtp', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8, color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: '000000',
            counterText: '',
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 20),
        AppButton(
          label: 'Verify Code ➔',
          icon: AppIcons.check,
          isLoading: _isLoading,
          onPressed: _verifyOtp,
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: _isLoading ? null : _requestOtp,
            child: const Text('Didn\'t receive code? Resend OTP', style: TextStyle(fontSize: 12, color: AppColors.primary)),
          ),
        ),
      ],
    );
  }

  // STEP 3: Create New Password
  Widget _buildStep3() {
    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(AppIcons.key, size: 42, color: AppColors.success),
        const SizedBox(height: 12),
        const Text(
          'Create New Password',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          'Your identity has been verified. Enter a strong new password for your account.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _newPasswordController,
          obscureText: _obscureNew,
          decoration: InputDecoration(
            labelText: 'New Password *',
            hintText: 'Minimum 6 characters',
            prefixIcon: const Icon(AppIcons.lock, size: 18, color: AppColors.textMuted),
            suffixIcon: IconButton(
              icon: Icon(_obscureNew ? AppIcons.eyeOff : AppIcons.eye, size: 18, color: AppColors.textMuted),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirm,
          decoration: InputDecoration(
            labelText: 'Confirm New Password *',
            hintText: 'Repeat password',
            prefixIcon: const Icon(AppIcons.lock, size: 18, color: AppColors.textMuted),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirm ? AppIcons.eyeOff : AppIcons.eye, size: 18, color: AppColors.textMuted),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
        ),
        const SizedBox(height: 22),
        AppButton(
          label: 'Save & Reset Password',
          icon: AppIcons.checkCircle2,
          isLoading: _isLoading,
          onPressed: _resetPassword,
        ),
      ],
    );
  }
}
