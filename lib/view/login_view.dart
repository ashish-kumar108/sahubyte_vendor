import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:sahubyte_vendor/model/request/get_data_request.dart';
import 'package:sahubyte_vendor/repository/auth_session_store.dart';
import 'package:sahubyte_vendor/repository/kyc_gate_repository.dart';
import 'package:sahubyte_vendor/repository/user_repository.dart';
import 'package:sahubyte_vendor/view/app_ui.dart';
import 'package:sahubyte_vendor/view/home_view.dart';
import 'package:sahubyte_vendor/view/kyc_pending_view.dart';
import 'package:sahubyte_vendor/view/set_password_view.dart';
import 'package:sahubyte_vendor/view_model/auth_view_model.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key, this.asSheet = false});

  final bool asSheet;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _authViewModel = AuthViewModel();
  final _userRepository = UserRepository();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  String _completePhoneNumber = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _redirectIfLoggedIn();
  }

  Future<void> _redirectIfLoggedIn() async {
    final session = AuthSessionStore();
    if (!await session.isLoggedIn() || !mounted) return;
    final mobile = await session.getLoggedInMobile();
    if (mobile == null || mobile.trim().isEmpty) return;
    try {
      final status = await KycGateRepository().getStatusForMobile(mobile);
      if (!mounted) return;
      if (!status.approved) {
        await session.setPendingApproval(mobile: mobile);
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => KycPendingView(mobile: mobile)),
          (route) => false,
        );
        return;
      }
    } catch (_) {}
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeView()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    _authViewModel.dispose();
    super.dispose();
  }

  Future<void> _loginWithPassword() async {
    final password = _passwordController.text.trim();
    if (_completePhoneNumber.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid mobile number to continue.'),
        ),
      );
      return;
    }
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your password to login.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _authViewModel.login(
        mobile: _completePhoneNumber,
        password: password,
      );
      if (!mounted) return;
      if (!response.isSuccess) {
        final message = response.displayMessage.trim();
        final lowerMessage = message.toLowerCase();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message.isEmpty ||
                      lowerMessage == 'request failed.' ||
                      response.status == '404'
                  ? 'Incorrect mobile number or password.'
                  : message,
            ),
          ),
        );
        return;
      }
      await _completeLogin();
    } catch (e) {
      if (!mounted) return;
      final matchedFromTable = await _tryPasswordLoginFromTechnicianTable(
        password,
      );
      if (!mounted) return;
      if (matchedFromTable) {
        await _completeLogin();
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            professionalErrorMessage(
              e,
              fallback: 'Login could not be completed. Please try again.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _tryPasswordLoginFromTechnicianTable(String password) async {
    try {
      final response = await _userRepository.getData(
        const GetDataRequest(tableName: 'technician'),
      );
      final enteredMobile = _digitsOnly(_completePhoneNumber);
      for (final row in response.rows) {
        final rowMobile = _digitsOnly(row['mobile']?.toString() ?? '');
        if (rowMobile != enteredMobile) continue;
        final savedPassword = row['password']?.toString().trim() ?? '';
        return savedPassword.isNotEmpty && savedPassword == password;
      }
    } catch (_) {}
    return false;
  }

  String _digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

  Future<void> _completeLogin() async {
    final status = await KycGateRepository().getStatusForMobile(
      _completePhoneNumber,
    );
    final session = AuthSessionStore();
    if (!mounted) return;
    if (!status.approved) {
      await session.setPendingApproval(mobile: _completePhoneNumber);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => KycPendingView(mobile: _completePhoneNumber),
        ),
        (route) => false,
      );
      return;
    }
    await session.setLoggedIn(true, mobile: _completePhoneNumber);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeView()),
      (route) => false,
    );
  }

  Future<void> _openPasswordSetup() async {
    final mobile = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.primaryDark.withValues(alpha: .42),
      builder: (_) => FractionallySizedBox(
        heightFactor: .92,
        child: SetPasswordView(
          initialMobile: _completePhoneNumber,
          asSheet: true,
        ),
      ),
    );
    if (!mounted || mobile == null) return;
    setState(() {
      _completePhoneNumber = mobile;
      _mobileController.text = mobile;
    });
    _passwordController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password saved. Login with your new password.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            Icon(Icons.lock_person_outlined, color: AppColors.primary),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Secure password login for bookings, wallet and job cards.',
                style: TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      const Text(
        'Mobile Number',
        style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.text),
      ),
      const SizedBox(height: 8),
      IntlPhoneField(
        controller: _mobileController,
        decoration: const InputDecoration(
          hintText: '98765 43210',
          counterText: '',
          prefixIcon: Icon(Icons.phone_outlined),
        ),
        initialCountryCode: 'IN',
        onChanged: (phone) {
          _completePhoneNumber = phone.number;
        },
        showDropdownIcon: true,
        dropdownIconPosition: IconPosition.trailing,
        flagsButtonPadding: const EdgeInsets.only(left: 10),
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(fontSize: 16),
        dropdownTextStyle: const TextStyle(fontSize: 16),
      ),
      const SizedBox(height: 14),
      const Text(
        'Password',
        style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.text),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _passwordController,
        obscureText: true,
        decoration: const InputDecoration(
          hintText: 'Enter password',
          prefixIcon: Icon(Icons.lock_outline_rounded),
        ),
      ),
      const SizedBox(height: 22),
      PrimaryButton(
        label: _isLoading ? 'Signing in...' : 'Login',
        icon: Icons.arrow_forward_rounded,
        onPressed: _isLoading ? null : _loginWithPassword,
      ),
      const SizedBox(height: 14),
      Center(
        child: TextButton(
          onPressed: _isLoading ? null : _openPasswordSetup,
          child: const Text(
            'Forgot or do not have a password? Set it with OTP',
          ),
        ),
      ),
    ];
    if (widget.asSheet) {
      return AuthSheetShell(
        title: 'Login to workspace',
        subtitle: 'Use your registered mobile number and password.',
        children: children,
      );
    }
    return AuthShell(
      title: 'Login to your workspace',
      subtitle: 'Use your registered mobile number and password to continue.',
      children: children,
    );
  }
}
