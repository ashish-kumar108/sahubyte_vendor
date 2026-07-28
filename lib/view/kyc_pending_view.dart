import 'package:flutter/material.dart';
import 'package:sahubyte_vendor/repository/auth_session_store.dart';
import 'package:sahubyte_vendor/repository/kyc_gate_repository.dart';
import 'package:sahubyte_vendor/repository/vendor_profile_store.dart';
import 'package:sahubyte_vendor/view/app_ui.dart';
import 'package:sahubyte_vendor/view/home_view.dart';
import 'package:sahubyte_vendor/view/profile_view.dart';
import 'package:sahubyte_vendor/view/welcome_view.dart';

class KycPendingView extends StatefulWidget {
  const KycPendingView({super.key, required this.mobile});

  final String mobile;

  @override
  State<KycPendingView> createState() => _KycPendingViewState();
}

class _KycPendingViewState extends State<KycPendingView> {
  final _kycRepository = KycGateRepository();
  final _sessionStore = AuthSessionStore();
  final _profileStore = VendorProfileStore();
  bool _checking = false;
  String _name = '';
  String _statusMessage =
      'Your technician account is waiting for admin review.';

  @override
  void initState() {
    super.initState();
    _syncPendingProfile();
    _checkApproval(showMessage: false);
  }

  Future<void> _syncPendingProfile() async {
    await _sessionStore.setPendingApproval(mobile: widget.mobile);
    await _profileStore.ensureOwner(widget.mobile);
  }

  Future<void> _checkApproval({bool showMessage = true}) async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final status = await _kycRepository.getStatusForMobile(widget.mobile);
      if (!mounted) return;
      if (status.found && status.name.isNotEmpty) {
        setState(() => _name = status.name);
      }
      if (status.approved) {
        await _sessionStore.setLoggedIn(true, mobile: widget.mobile);
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeView()),
          (route) => false,
        );
        return;
      }
      setState(() {
        _statusMessage = status.found
            ? 'Admin approval is still pending. Complete your profile and documents to speed up verification.'
            : 'Your account is being prepared. Please complete profile details and check again shortly.';
      });
      if (showMessage && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_statusMessage),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _statusMessage =
            'Could not check approval right now. Your profile and document upload still work.';
      });
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileView(
          onBack: () => Navigator.maybePop(context),
          onProfileUpdated: () => _checkApproval(showMessage: false),
        ),
      ),
    );
    if (mounted) _checkApproval(showMessage: false);
  }

  Future<void> _logout() async {
    await _sessionStore.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeView()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _checkApproval(showMessage: false),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              compact ? 14 : 20,
              18,
              compact ? 14 : 20,
              26,
            ),
            children: [
              Row(
                children: [
                  Container(
                    width: 78,
                    height: 58,
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Image.asset(appLogo, fit: BoxFit.contain),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Logout'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: .16),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.verified_user_outlined,
                        color: AppColors.warning,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _name.trim().isEmpty
                          ? 'Verification under review'
                          : 'Hi $_name, verification is under review',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _statusMessage,
                      style: const TextStyle(
                        color: Color(0xDDEFF4FF),
                        fontSize: 14,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Before approval',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _StepTile(
                      icon: Icons.badge_outlined,
                      title: 'Complete profile details',
                      subtitle: 'Name, state, address and service expertise.',
                    ),
                    const SizedBox(height: 12),
                    _StepTile(
                      icon: Icons.file_upload_outlined,
                      title: 'Upload verification documents',
                      subtitle:
                          'Profile photo, Aadhaar, PAN and driving proof.',
                    ),
                    const SizedBox(height: 12),
                    _StepTile(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Admin review',
                      subtitle: 'Dashboard access opens after KYC is approved.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: 'Complete profile & documents',
                icon: Icons.edit_document,
                onPressed: _openProfile,
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: _checking ? 'Checking approval...' : 'Check approval',
                icon: Icons.refresh_rounded,
                onPressed: _checking ? null : () => _checkApproval(),
              ),
              const SizedBox(height: 16),
              const Text(
                'You can upload documents anytime. Booking dashboard, wallet and jobs unlock only after admin approval.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.muted,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
