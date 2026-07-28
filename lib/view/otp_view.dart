import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sahubyte_vendor/model/request/signup_request.dart';
import 'package:sahubyte_vendor/model/vendor_profile.dart';
import 'package:sahubyte_vendor/repository/auth_session_store.dart';
import 'package:sahubyte_vendor/repository/kyc_gate_repository.dart';
import 'package:sahubyte_vendor/repository/vendor_profile_store.dart';
import 'package:sahubyte_vendor/view/app_ui.dart';
import 'package:sahubyte_vendor/view/home_view.dart';
import 'package:sahubyte_vendor/view/kyc_pending_view.dart';
import 'package:sahubyte_vendor/view_model/auth_view_model.dart';

enum OtpFlow { login, signup }

class OtpView extends StatefulWidget {
  const OtpView({
    super.key,
    required this.phoneNumber,
    this.flow = OtpFlow.login,
    this.signupRequest,
    this.expectedOtp,
    this.expertise,
    this.address,
    this.state,
    this.categoryId,
  });

  final String phoneNumber;
  final OtpFlow flow;
  final SignupRequest? signupRequest;
  final String? expectedOtp;
  final String? expertise;
  final String? address;
  final String? state;
  final String? categoryId;

  @override
  State<OtpView> createState() => _OtpViewState();
}

class _OtpViewState extends State<OtpView> {
  final _authViewModel = AuthViewModel();
  final _kycRepository = KycGateRepository();
  final _otpControllers = List.generate(4, (_) => TextEditingController());
  final _focusNodes = List.generate(4, (_) => FocusNode());

  int _secondsRemaining = 30;
  Timer? _timer;
  bool _isLoading = false;
  String? _expectedOtp;

  @override
  void initState() {
    super.initState();
    _expectedOtp = widget.expectedOtp;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _authViewModel.dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String get _otp =>
      _otpControllers.map((controller) => controller.text).join();

  Future<void> _resendOtp() async {
    setState(() => _isLoading = true);
    try {
      if (widget.flow == OtpFlow.signup) {
        final response = await _authViewModel.signupOtp(widget.phoneNumber);
        if (!response.isSuccess) {
          throw Exception(response.displayMessage);
        }
        _expectedOtp = response.otp;
      } else {
        final response = await _authViewModel.sendOtpLogin(widget.phoneNumber);
        if (!response.isSuccess) {
          throw Exception(response.displayMessage);
        }
        _expectedOtp = response.otp;
      }
      if (!mounted) return;
      setState(() => _secondsRemaining = 30);
      _startTimer();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OTP sent successfully.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            professionalErrorMessage(
              e,
              fallback: 'OTP could not be resent. Please try again.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitOtp() async {
    if (_otp.length != 4) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter the 4 digit OTP.')));
      return;
    }

    if (_expectedOtp != null && _otp != _expectedOtp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid OTP. Please check and try again.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (widget.flow == OtpFlow.signup) {
        final request = widget.signupRequest;
        if (request == null) {
          throw Exception('Signup details are missing.');
        }
        await _authViewModel.signup(
          mobile: request.mobile,
          email: request.email,
          name: request.name,
          dob: request.dob,
          state: request.state,
          pincode: request.pincode,
          password: request.password,
        );
        final store = VendorProfileStore();
        await store.ensureOwner(request.mobile);
        await store.saveProfile(
          VendorProfile(
            name: request.name,
            email: request.email,
            mobile: request.mobile,
            dob: request.dob,
            expertise: widget.expertise ?? '',
            address: widget.address ?? '',
            state: widget.state ?? '',
            pincode: request.pincode,
            categoryId: widget.categoryId,
          ),
        );
      } else {
        await _saveLoginMobileForProfileSync();
      }

      final session = AuthSessionStore();
      if (!mounted) return;
      if (widget.flow == OtpFlow.signup) {
        await session.setPendingApproval(mobile: widget.phoneNumber);
        _showSignupSuccessDialog();
      } else {
        final status = await _kycRepository.getStatusForMobile(
          widget.phoneNumber,
        );
        if (!status.approved) {
          await session.setPendingApproval(mobile: widget.phoneNumber);
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => KycPendingView(mobile: widget.phoneNumber),
            ),
            (route) => false,
          );
          return;
        }
        await session.setLoggedIn(true, mobile: widget.phoneNumber);
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeView()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            professionalErrorMessage(
              e,
              fallback: 'OTP verification could not be completed.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveLoginMobileForProfileSync() async {
    final store = VendorProfileStore();
    await store.ensureOwner(widget.phoneNumber);
    final current = await store.getProfile();
    await store.saveProfile(current.copyWith(mobile: widget.phoneNumber));
  }

  void _showSignupSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 86,
                  width: 86,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE7F8EF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.task_alt_rounded,
                    color: AppColors.success,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Thank you for applying.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Complete your profile and documents while admin reviews your KYC. Dashboard access opens after approval.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 22),
                PrimaryButton(
                  label: 'Complete profile & documents',
                  icon: Icons.edit_document,
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            KycPendingView(mobile: widget.phoneNumber),
                      ),
                      (route) => false,
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

  Widget _otpBox(int index, double width) {
    return SizedBox(
      height: 62,
      width: width,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        onChanged: (value) {
          if (value.length == 1 && index < _focusNodes.length - 1) {
            _focusNodes[index + 1].requestFocus();
          }
          if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          fillColor: const Color(0xFFF8FBFF),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSignup = widget.flow == OtpFlow.signup;

    return AuthShell(
      title: isSignup ? 'Verify your account' : 'Verify OTP',
      subtitle: 'Enter the 4 digit code sent to your mobile number.',
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FBFF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.sms_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OTP sent to',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.phoneNumber,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Change number',
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final gap = constraints.maxWidth < 300 ? 6.0 : 10.0;
            final boxWidth = ((constraints.maxWidth - (gap * 3)) / 4).clamp(
              44.0,
              58.0,
            );
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Padding(
                  padding: EdgeInsets.only(right: index == 3 ? 0 : gap),
                  child: _otpBox(index, boxWidth),
                );
              }),
            );
          },
        ),
        const SizedBox(height: 18),
        Center(
          child: _secondsRemaining > 0
              ? StatusPill(
                  label:
                      'Resend in 0:${_secondsRemaining.toString().padLeft(2, '0')}',
                  color: AppColors.primary,
                  icon: Icons.timer_outlined,
                )
              : TextButton.icon(
                  onPressed: _isLoading ? null : _resendOtp,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Resend OTP'),
                ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: _isLoading
              ? (isSignup ? 'Creating Account...' : 'Verifying...')
              : (isSignup ? 'Complete Signup' : 'Login'),
          icon: Icons.verified_user_outlined,
          onPressed: _isLoading ? null : _submitOtp,
        ),
      ],
    );
  }
}
