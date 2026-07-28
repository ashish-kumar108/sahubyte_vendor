import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:sahubyte_vendor/model/request/signup_request.dart';
import 'package:sahubyte_vendor/model/vendor_profile.dart';
import 'package:sahubyte_vendor/repository/auth_session_store.dart';
import 'package:sahubyte_vendor/repository/kyc_gate_repository.dart';
import 'package:sahubyte_vendor/repository/vendor_profile_store.dart';
import 'package:sahubyte_vendor/view/app_ui.dart';
import 'package:sahubyte_vendor/view/home_view.dart';
import 'package:sahubyte_vendor/view/kyc_pending_view.dart';
import 'package:sahubyte_vendor/view/otp_view.dart';
import 'package:sahubyte_vendor/view_model/auth_view_model.dart';
import 'package:sahubyte_vendor/view_model/user_view_model.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key, this.asSheet = false});

  final bool asSheet;

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final _authViewModel = AuthViewModel();
  final _userViewModel = UserViewModel();
  final _profileStore = VendorProfileStore();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _passwordController = TextEditingController();
  List<Map<String, dynamic>> _categories = const [];
  String? _selectedCategoryId;
  String? _selectedState;
  String _phoneNumber = '';
  bool _isLoading = false;
  bool _isLoadingCategories = true;

  static const _stateOptions = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Delhi',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Tamil Nadu',
    'Telangana',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];

  @override
  void initState() {
    super.initState();
    _redirectIfLoggedIn();
    _loadCategories();
  }

  String _rv(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  Future<void> _loadCategories() async {
    try {
      final res = await _userViewModel.getData(tableName: 'category');
      final rows = res.rows
          .where((row) => _rv(row, const ['id']).isNotEmpty)
          .toList();
      if (!mounted) return;
      setState(() {
        _categories = rows.isEmpty
            ? const [
                {'id': '1', 'categoryName': 'Hardware'},
                {'id': '2', 'categoryName': 'Software'},
              ]
            : rows;
        _isLoadingCategories = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _categories = const [
          {'id': '1', 'categoryName': 'Hardware'},
          {'id': '2', 'categoryName': 'Software'},
        ];
        _isLoadingCategories = false;
      });
    }
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
    _authViewModel.dispose();
    _userViewModel.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final adultCutoff = DateTime(now.year - 18, now.month, now.day);
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: adultCutoff,
      firstDate: DateTime(1950),
      lastDate: adultCutoff,
    );

    if (selectedDate == null) return;
    _dobController.text =
        '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
  }

  Future<void> _submitSignup() async {
    final hasMissingDetails =
        _nameController.text.trim().isEmpty ||
        _phoneNumber.trim().length < 10 ||
        _emailController.text.trim().isEmpty ||
        !_emailController.text.contains('@') ||
        _dobController.text.trim().isEmpty ||
        _selectedCategoryId == null ||
        _selectedState == null ||
        _addressController.text.trim().isEmpty ||
        _pincodeController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty;

    if (hasMissingDetails) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete all vendor details before submitting.'),
        ),
      );
      return;
    }
    if (!_isAtLeast18(_dobController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vendor registration is allowed only above 18 years.'),
        ),
      );
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(_pincodeController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 6 digit pincode.')),
      );
      return;
    }
    if (_passwordController.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _authViewModel.signupOtp(_phoneNumber);
      if (!mounted) return;
      if (!response.isSuccess) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.displayMessage)));
        return;
      }

      final signupRequest = SignupRequest(
        mobile: _phoneNumber,
        email: _emailController.text.trim(),
        name: _nameController.text.trim(),
        dob: _dobController.text.trim(),
        state: _selectedState ?? '',
        pincode: _pincodeController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final selectedCategory = _categories.firstWhere(
        (row) => _rv(row, const ['id']) == _selectedCategoryId,
        orElse: () => const {},
      );
      final expertise = _rv(selectedCategory, const ['categoryName', 'name']);
      final profile = VendorProfile(
        name: signupRequest.name,
        email: signupRequest.email,
        mobile: signupRequest.mobile,
        dob: signupRequest.dob,
        expertise: expertise,
        address: _addressController.text.trim(),
        state: _selectedState ?? '',
        pincode: signupRequest.pincode,
        categoryId: _selectedCategoryId,
      );
      await _profileStore.ensureOwner(signupRequest.mobile);
      await _profileStore.saveProfile(profile);
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpView(
            phoneNumber: _phoneNumber,
            flow: OtpFlow.signup,
            expectedOtp: response.otp,
            signupRequest: signupRequest,
            expertise: expertise,
            address: profile.address,
            state: profile.state,
            categoryId: profile.categoryId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            professionalErrorMessage(
              e,
              fallback: 'Account setup could not continue. Please try again.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isAtLeast18(String value) {
    final dob = DateTime.tryParse(value);
    if (dob == null) return false;
    final now = DateTime.now();
    final adultCutoff = DateTime(now.year - 18, now.month, now.day);
    return !dob.isAfter(adultCutoff);
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? hintText,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: icon == null ? null : Icon(icon),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        items: items,
        onChanged: onChanged,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }

  Widget _sectionLabel(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: AppColors.primary),
          ),
          const SizedBox(width: 9),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFFD8BE)),
        ),
        child: const Row(
          children: [
            Icon(Icons.engineering_outlined, color: AppColors.accent),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Create your technician profile for customer bookings.',
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
      _sectionLabel('Personal Information', Icons.badge_outlined),
      _buildTextField('Name', _nameController, icon: Icons.person_outline),
      _buildTextField('Email', _emailController, icon: Icons.mail_outline),
      _buildTextField(
        'Password',
        _passwordController,
        hintText: 'Create password',
        icon: Icons.lock_outline,
      ),
      GestureDetector(
        onTap: _pickDob,
        child: AbsorbPointer(
          child: _buildTextField(
            'Date of Birth',
            _dobController,
            hintText: 'YYYY-MM-DD',
            icon: Icons.cake_outlined,
          ),
        ),
      ),
      const SizedBox(height: 4),
      _sectionLabel('Contact', Icons.phone_android_outlined),
      IntlPhoneField(
        decoration: const InputDecoration(
          labelText: 'Mobile Number',
          hintText: '98765 43210',
          counterText: '',
          prefixIcon: Icon(Icons.phone_outlined),
        ),
        initialCountryCode: 'IN',
        onChanged: (phone) {
          _phoneNumber = phone.number;
        },
        showDropdownIcon: true,
        dropdownIconPosition: IconPosition.trailing,
      ),
      const SizedBox(height: 14),
      _sectionLabel('Service Details', Icons.handyman_outlined),
      if (_isLoadingCategories)
        const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: SkeletonBox(width: double.infinity, height: 56, radius: 12),
        )
      else
        _buildDropdown<String>(
          label: 'Job Expertise',
          icon: Icons.build_outlined,
          hint: 'Select job expertise',
          value: _selectedCategoryId,
          items: _categories.map((row) {
            final id = _rv(row, const ['id']);
            final name = _rv(row, const ['categoryName', 'name']);
            return DropdownMenuItem(value: id, child: Text(name));
          }).toList(),
          onChanged: (value) => setState(() => _selectedCategoryId = value),
        ),
      _buildDropdown<String>(
        label: 'State',
        icon: Icons.map_outlined,
        hint: 'Select state',
        value: _selectedState,
        items: _stateOptions
            .map((state) => DropdownMenuItem(value: state, child: Text(state)))
            .toList(),
        onChanged: (value) => setState(() => _selectedState = value),
      ),
      _buildTextField(
        'Address',
        _addressController,
        icon: Icons.location_on_outlined,
      ),
      _buildTextField(
        'Pincode',
        _pincodeController,
        hintText: 'Enter 6 digit pincode',
        icon: Icons.pin_drop_outlined,
      ),
      const SizedBox(height: 8),
      PrimaryButton(
        label: _isLoading ? 'Sending OTP...' : 'Create Account',
        icon: Icons.arrow_forward_rounded,
        onPressed: _isLoading ? null : _submitSignup,
      ),
    ];
    if (widget.asSheet) {
      return AuthSheetShell(
        title: 'Create vendor account',
        subtitle: 'Complete your technician profile for admin review.',
        children: children,
      );
    }
    return AuthShell(
      title: 'Create vendor account',
      subtitle:
          'Add your details once. They will be used for profile and onboarding review.',
      children: children,
    );
  }
}
