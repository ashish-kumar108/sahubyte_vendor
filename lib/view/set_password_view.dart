import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:sahubyte_vendor/repository/kyc_gate_repository.dart';
import 'package:sahubyte_vendor/view/app_ui.dart';
import 'package:sahubyte_vendor/view_model/auth_view_model.dart';

class SetPasswordView extends StatefulWidget {
  const SetPasswordView({
    super.key,
    this.initialMobile = '',
    this.asSheet = false,
  });

  final String initialMobile;
  final bool asSheet;

  @override
  State<SetPasswordView> createState() => _SetPasswordViewState();
}

class _SetPasswordViewState extends State<SetPasswordView> {
  final _authViewModel = AuthViewModel();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late String _mobile;
  String? _expectedOtp;
  String? _technicianId;
  bool _otpVerified = false;

  @override
  void initState() {
    super.initState();
    _mobile = widget.initialMobile.replaceAll(RegExp(r'\D'), '');
    _authViewModel.addListener(_refresh);
  }

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _authViewModel.removeListener(_refresh);
    _authViewModel.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  bool get _validMobile => RegExp(r'^\d{10}$').hasMatch(_mobile);

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _sendOtp() async {
    if (!_validMobile) {
      return _message('Enter a valid 10-digit registered mobile number.');
    }
    try {
      final status = await KycGateRepository().getStatusForMobile(_mobile);
      if (!mounted) return;
      if (!status.found || status.technicianId.isEmpty) {
        return _message('No vendor account was found for this mobile number.');
      }
      final response = await _authViewModel.sendOtpLogin(_mobile);
      if (!mounted) return;
      if (!response.isSuccess) return _message(response.displayMessage);
      setState(() {
        _technicianId = status.technicianId;
        _expectedOtp = response.otp;
      });
      _message('Verification OTP sent successfully.');
    } catch (error) {
      _message(
        professionalErrorMessage(
          error,
          fallback: 'OTP could not be sent. Please try again.',
        ),
      );
    }
  }

  void _verifyOtp() {
    if (_expectedOtp == null) {
      return _message('Request an OTP first.');
    }
    if (_otpController.text.trim() != _expectedOtp) {
      return _message('Enter the correct OTP.');
    }
    setState(() => _otpVerified = true);
    _message('Mobile verified. Create your password.');
  }

  Future<void> _savePassword() async {
    final password = _passwordController.text.trim();
    if (password.length < 6) {
      return _message('Password must be at least 6 characters.');
    }
    if (password != _confirmPasswordController.text.trim()) {
      return _message('Password confirmation does not match.');
    }
    if (_technicianId?.isNotEmpty != true) {
      return _message('Vendor account could not be identified.');
    }
    try {
      final response = await _authViewModel.resetPassword(
        technicianId: _technicianId!,
        password: password,
      );
      if (!mounted) return;
      if (!response.isSuccess) return _message(response.displayMessage);

      final savedAccount = await KycGateRepository().getStatusForMobile(
        _mobile,
      );
      if (!mounted) return;
      final savedPassword = savedAccount.row['password']?.toString() ?? '';
      if (savedPassword != password) {
        return _message(
          'The server responded, but the new password was not saved. Please contact support.',
        );
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.greenSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.success,
              size: 36,
            ),
          ),
          title: const Text(
            'Password saved',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'Your account is ready. Continue to login with your new password.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(),
              icon: const Icon(Icons.login_rounded),
              label: const Text('Continue to login'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(_mobile);
    } catch (error) {
      _message(
        professionalErrorMessage(
          error,
          fallback: 'Password could not be saved. Please try again.',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _otpVerified ? 'Create your password' : 'Verify your account';
    final subtitle = _otpVerified
        ? 'Set a secure password, then use it to login to your workspace.'
        : 'Existing vendors can verify their registered mobile number with OTP.';
    final children = <Widget>[
      const Text(
        'Registered Mobile Number',
        style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.text),
      ),
      const SizedBox(height: 8),
      IntlPhoneField(
        initialValue: _mobile,
        enabled: !_otpVerified,
        initialCountryCode: 'IN',
        decoration: const InputDecoration(
          hintText: '98765 43210',
          counterText: '',
          prefixIcon: Icon(Icons.phone_outlined),
        ),
        onChanged: (phone) => _mobile = phone.number,
      ),
      const SizedBox(height: 14),
      const Text(
        'Verification OTP',
        style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.text),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _otpController,
        enabled: !_otpVerified,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: 'Enter OTP',
          prefixIcon: const Icon(Icons.verified_user_outlined),
          suffixIcon: TextButton(
            onPressed: _authViewModel.isLoading || _otpVerified
                ? null
                : _sendOtp,
            child: Text(_expectedOtp == null ? 'Send OTP' : 'Resend'),
          ),
        ),
      ),
      if (_otpVerified) ...[
        const SizedBox(height: 16),
        const Text(
          'New Password',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Create password',
            prefixIcon: Icon(Icons.lock_reset_rounded),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Confirm Password',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Enter password again',
            prefixIcon: Icon(Icons.lock_outline_rounded),
          ),
        ),
      ],
      const SizedBox(height: 22),
      PrimaryButton(
        label: _authViewModel.isLoading
            ? (_otpVerified ? 'Saving password...' : 'Verifying...')
            : (_otpVerified ? 'Save password' : 'Verify OTP'),
        icon: Icons.arrow_forward_rounded,
        onPressed: _authViewModel.isLoading
            ? null
            : (_otpVerified ? _savePassword : _verifyOtp),
      ),
    ];
    if (widget.asSheet) {
      return AuthSheetShell(
        title: title,
        subtitle: subtitle,
        children: children,
      );
    }
    return AuthShell(title: title, subtitle: subtitle, children: children);
  }
}
