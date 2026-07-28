import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sahubyte_vendor/model/response/technician_enquiry_model.dart';
import 'package:sahubyte_vendor/model/vendor_profile.dart';
import 'package:sahubyte_vendor/repository/auth_session_store.dart';
import 'package:sahubyte_vendor/repository/vendor_profile_store.dart';
import 'package:sahubyte_vendor/view/app_ui.dart';
import 'package:sahubyte_vendor/view/bookings_view.dart';
import 'package:sahubyte_vendor/view/profile_view.dart';
import 'package:sahubyte_vendor/view/wallet_view.dart';
import 'package:sahubyte_vendor/view_model/technician_view_model.dart';
import 'package:sahubyte_vendor/view_model/user_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Internal palette (mirrors profile_view _PC) -----------------------------
class _HC {
  static const white = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF9F8F6);
  static const border = Color(0xFFDDE4EF);
  static const teal = Color(0xFF1A9E78);
  static const tealSoft = Color(0xFFE8F7F2);
  static const tealBorder = Color(0xFFB8E8D8);
  static const indigo = Color(0xFF4361C2);
  static const indigoSoft = Color(0xFFEEF1FB);
  static const indigoBorder = Color(0xFFC4CEEE);
  static const amber = Color(0xFFB87B2E);
  static const amberSoft = Color(0xFFFBF4E8);
  static const amberBorder = Color(0xFFEDCF9A);
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  // -- nav -------------------------------------------------------------------
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  int _bookingsRefreshToken = 0;
  bool _isOn = true;

  // -- profile data (same as ProfileView) -----------------------------------
  final _profileStore = VendorProfileStore();
  final _userViewModel = UserViewModel();
  final _technicianViewModel = TechnicianViewModel();

  bool _isLoading = true;
  bool _isLoadingRecentBookings = false;
  bool _isStoreLoading = true;
  String? _storeError;
  String _technicianId = '';
  String _name = '';
  String _email = '';
  String _mobile = '';
  String _state = '';
  String _rating = '';
  String _storeName = '';
  String _storeLocation = '';
  String _storeContactNumber = '';
  String _storeContactEmail = '';
  String _baseServiceFee = '';
  String _taxPercent = '';
  List<String> _availableServices = const [];
  String? _profileImagePath;
  List<TechnicianEnquiryModel> _allBookings = const [];
  List<TechnicianEnquiryModel> _recentBookings = const [];

  // -- lifecycle -------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _userViewModel.dispose();
    _technicianViewModel.dispose();
    super.dispose();
  }

  // -- data loading (exact same flow as ProfileView._loadProfile) ------------
  Future<void> _loadProfile() async {
    final sessionMobile = await AuthSessionStore().getLoggedInMobile();
    if (sessionMobile != null) {
      await _profileStore.ensureOwner(sessionMobile);
    }
    final storedLocal = await _profileStore.getProfile();
    final local = sessionMobile == null
        ? storedLocal
        : storedLocal.copyWith(mobile: sessionMobile);
    final server = await _fetchLoggedInProfile(local);
    final profile = server ?? local;
    if (server != null) await _profileStore.saveProfile(profile);
    if (!mounted) return;
    if (profile.technicianId.trim().isNotEmpty) {
      _technicianId = profile.technicianId.trim();
    }
    _name = profile.name;
    _email = profile.email;
    _mobile = profile.mobile;
    _state = profile.state;
    _profileImagePath ??= await _profileStore.getProfileImagePath();
    await _loadAvailabilityPreference();
    setState(() => _isLoading = false);
    await _loadRecentBookings();
    await _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    if (mounted) {
      setState(() {
        _isStoreLoading = true;
        _storeError = null;
      });
    }
    try {
      final settingsResponse = await _userViewModel.getData(
        tableName: 'settings',
      );
      final settings = settingsResponse.rows.isEmpty
          ? null
          : settingsResponse.rows.first;
      if (settings == null) {
        throw Exception('Store settings were not found.');
      }

      final technicianRating = _technicianId.trim().isEmpty
          ? null
          : await _technicianViewModel.getTechnicianRating(
              technicianId: _technicianId,
            );

      if (!mounted) return;
      setState(() {
        _storeName = _rv(settings, const ['storeName']);
        _storeLocation = _rv(settings, const ['location']);
        _storeContactNumber = _rv(settings, const ['contactNumber']);
        _storeContactEmail = _rv(settings, const ['contactEmail']);
        _baseServiceFee = _rv(settings, const ['baseServiceFee']);
        _taxPercent = _rv(settings, const ['taxPercent']);
        _availableServices = _parseAvailableServices(
          settings['availableService'],
        );
        if (_storeName.isEmpty ||
            _storeLocation.isEmpty ||
            _storeContactNumber.isEmpty ||
            _storeContactEmail.isEmpty ||
            _baseServiceFee.isEmpty ||
            _taxPercent.isEmpty ||
            _availableServices.isEmpty) {
          throw Exception('Store settings are incomplete.');
        }
        _rating = technicianRating == null || technicianRating <= 0
            ? ''
            : technicianRating.toStringAsFixed(1);
        _isStoreLoading = false;
      });
    } catch (error) {
      debugPrint('[HomeView] Could not load store settings: $error');
      if (!mounted) return;
      setState(() {
        _storeError = professionalErrorMessage(
          error,
          fallback: 'Store details could not be refreshed.',
        );
        _isStoreLoading = false;
      });
    }
  }

  List<String> _parseAvailableServices(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return raw
        .split(RegExp(r'[,|\n]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Future<void> _handleProfileUpdated() async {
    await _loadProfile();
    if (!mounted) return;
    setState(() => _bookingsRefreshToken++);
  }

  Future<void> _refreshHomeData() async {
    try {
      await _loadProfile();
      if (!mounted) return;
      setState(() => _bookingsRefreshToken++);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            professionalErrorMessage(
              error,
              fallback: 'Dashboard could not be refreshed. Please try again.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _loadRecentBookings() async {
    if (_technicianId.trim().isEmpty) return;
    setState(() => _isLoadingRecentBookings = true);
    try {
      final bookings = await _technicianViewModel.getAssignedEnquiries(
        technicianId: _technicianId,
        enquiryStatus: '',
        technicianStatus: '',
        page: 1,
        limit: 100,
      );
      bookings.sort((a, b) => b.id.compareTo(a.id));
      if (!mounted) return;
      setState(() {
        _allBookings = bookings;
        _recentBookings = bookings.take(2).toList();
        _isLoadingRecentBookings = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _allBookings = const [];
        _recentBookings = const [];
        _isLoadingRecentBookings = false;
      });
    }
  }

  Future<VendorProfile?> _fetchLoggedInProfile(VendorProfile local) async {
    for (final t in ['technician', 'userLogin', 'userlogin']) {
      try {
        final res = await _userViewModel.getData(tableName: t);
        final row = _findMatchingProfileRow(res.rows, local);
        if (row != null) {
          _technicianId = _vof(
            _rv(row, const ['technicianId', 'id', 'userId']),
            _technicianId,
          );
          final img = _resolveImg(_rv(row, const ['profileImage']));
          if (img != null) {
            _profileImagePath = img;
            await _profileStore.saveProfileImagePath(img);
          }
          _rating = _rv(row, const ['rating', 'averageRating', 'avgRating']);
          return _profileFromRow(row, local);
        }
      } catch (_) {}
    }
    return null;
  }

  Map<String, dynamic>? _findMatchingProfileRow(
    List<Map<String, dynamic>> rows,
    VendorProfile local,
  ) {
    if (rows.isEmpty) return null;
    final lm = _digits(local.mobile);
    final le = local.email.trim().toLowerCase();
    for (final row in rows) {
      final rm = _digits(
        _rv(row, const [
          'mobile',
          'phone',
          'mobileNumber',
          'contact',
          'contactNumber',
        ]),
      );
      final re = _rv(row, const [
        'email',
        'emailId',
        'emailID',
      ]).trim().toLowerCase();
      if (lm.isNotEmpty && rm == lm) return row;
      if (le.isNotEmpty && re == le) return row;
    }
    final hasIdentity = lm.isNotEmpty || le.isNotEmpty;
    return hasIdentity ? null : (rows.length == 1 ? rows.first : null);
  }

  VendorProfile _profileFromRow(Map<String, dynamic> row, VendorProfile fb) =>
      fb.copyWith(
        technicianId: _vof(
          _rv(row, const ['technicianId', 'id', 'userId']),
          fb.technicianId,
        ),
        name: _vof(
          _rv(row, const ['name', 'fullName', 'technicianName']),
          fb.name,
        ),
        email: _vof(_rv(row, const ['email', 'emailId', 'emailID']), fb.email),
        mobile: _vof(
          _rv(row, const [
            'mobile',
            'phone',
            'mobileNumber',
            'contact',
            'contactNumber',
          ]),
          fb.mobile,
        ),
        dob: _vof(_rv(row, const ['dob', 'dateOfBirth', 'birthDate']), fb.dob),
        expertise: fb.expertise,
        address: _vof(_rv(row, const ['address', 'location']), fb.address),
        state: _vof(_rv(row, const ['state']), fb.state),
        accountName: _vof(
          _rv(row, const ['accountName', 'accName', 'bankAccountName']),
          fb.accountName,
        ),
        ifsc: _vof(_rv(row, const ['ifsc', 'ifscCode', 'IFSC']), fb.ifsc),
        accountNo: _vof(
          _rv(row, const ['accountNo', 'accNo', 'bankAccountNo']),
          fb.accountNo,
        ),
        upiNo: _vof(_rv(row, const ['upiNo', 'upi', 'upiId']), fb.upiNo),
        categoryId: _vof(
          _rv(row, const ['categoryId', 'serviceCategoryId']),
          fb.categoryId ?? '',
        ),
        subCategoryId: _vof(
          _rv(row, const ['subCategoryId', 'serviceSubCategoryId']),
          fb.subCategoryId ?? '',
        ),
      );

  // -- image helpers (same as ProfileView) -----------------------------------
  String? _resolveImg(String v) {
    final t = v.trim();
    if (t.isEmpty || t.toLowerCase() == 'null') return null;
    if (t.startsWith('data:image')) return t;
    if (t.length > 100 && RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(t)) {
      return 'data:image/jpeg;base64,$t';
    }
    if (t.startsWith('http://') || t.startsWith('https://')) {
      return t.replaceAll(r'\/', '/');
    }
    final normalized = t
        .replaceAll(r'\/', '/')
        .replaceAll(RegExp(r'/+'), '/')
        .replaceFirst(RegExp(r'^/'), '');
    const base = 'https://techcanopusdemo.com/sahubyte/public/uploads/';
    var path = normalized;
    if (path.startsWith('sahubyte/public/uploads/')) {
      path = path.substring('sahubyte/public/uploads/'.length);
    } else if (path.startsWith('public/uploads/')) {
      path = path.substring('public/uploads/'.length);
    } else if (path.startsWith('uploads/')) {
      path = path.substring('uploads/'.length);
    }
    return '$base${path.replaceFirst(RegExp(r'^/+'), '')}';
  }

  bool _isNet(String? s) =>
      s != null && (s.startsWith('http://') || s.startsWith('https://'));

  bool _isBase64(String? s) =>
      s != null &&
      (s.startsWith('data:image') ||
          (s.length > 100 && RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(s)));

  bool _hasImg(String? s) {
    if (s == null || s.trim().isEmpty) return false;
    return _isNet(s) || _isBase64(s) || File(s).existsSync();
  }

  Widget _imgPreview(String src) {
    if (_isNet(src)) {
      return Image.network(
        src,
        fit: BoxFit.cover,
        headers: const {'Accept': 'image/*'},
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : const SkeletonBox(
                width: double.infinity,
                height: double.infinity,
                radius: 16,
              ),
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.person_rounded, color: AppColors.muted),
        ),
      );
    }
    if (src.startsWith('data:image')) {
      try {
        final b64 = src.contains(',') ? src.split(',').last : src;
        final bytes = base64Decode(b64);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.person_rounded, color: AppColors.muted),
          ),
        );
      } catch (_) {
        return const Center(
          child: Icon(Icons.person_rounded, color: AppColors.muted),
        );
      }
    }
    return Image.file(File(src), fit: BoxFit.cover);
  }

  Widget _buildProfileAvatar(double size) {
    final hasImg = _hasImg(_profileImagePath);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _HC.tealSoft,
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: _HC.tealBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImg
          ? _imgPreview(_profileImagePath!)
          : Icon(Icons.person_rounded, color: _HC.teal, size: size * 0.52),
    );
  }

  // -- util (same as ProfileView) --------------------------------------------
  String _rv(Map<String, dynamic> row, List<String> keys) {
    for (final k in keys) {
      final v = row[k];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    final lower = keys.map((k) => k.toLowerCase()).toSet();
    for (final e in row.entries) {
      if (lower.contains(e.key.toLowerCase()) &&
          e.value != null &&
          e.value.toString().trim().isNotEmpty) {
        return e.value.toString().trim();
      }
    }
    return '';
  }

  String _vof(String v, String fb) => v.trim().isEmpty ? fb : v.trim();
  String _digits(String v) => v.replaceAll(RegExp(r'[^0-9]'), '');

  List<TechnicianEnquiryModel> get _completedBookings => _allBookings
      .where(
        (booking) =>
            booking.statusLabel == 'Job Completed' ||
            booking.statusLabel == 'Completed' ||
            booking.technicianStatus.trim() == '6',
      )
      .toList();

  int get _totalEarnings => _completedBookings.fold<int>(
    0,
    (total, booking) => total + booking.amount,
  );

  String get _ratingLabel {
    final parsed = double.tryParse(_rating.trim());
    return parsed == null ? '--' : parsed.toStringAsFixed(1);
  }

  String _money(int value) {
    final negative = value < 0;
    final digits = value.abs().toString();
    if (digits.length <= 3) return 'Rs ${negative ? '-' : ''}$digits';
    final tail = digits.substring(digits.length - 3);
    var head = digits.substring(0, digits.length - 3);
    final groups = <String>[];
    while (head.length > 2) {
      groups.insert(0, head.substring(head.length - 2));
      head = head.substring(0, head.length - 2);
    }
    if (head.isNotEmpty) groups.insert(0, head);
    return 'Rs ${negative ? '-' : ''}${groups.join(',')},$tail';
  }

  Future<void> _loadAvailabilityPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isOn = prefs.getBool('accepting_jobs_${_technicianId.trim()}') ?? true;
  }

  Future<void> _setAvailability(bool value) async {
    setState(() => _isOn = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('accepting_jobs_${_technicianId.trim()}', value);
  }

  void _openWallet() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WalletView(
          completedBookings: _completedBookings,
          totalEarnings: _totalEarnings,
          vendorName: _name,
          vendorMobile: _mobile,
        ),
      ),
    );
  }

  // -- greeting helper -------------------------------------------------------
  String get _greeting {
    final h = TimeOfDay.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // =========================================================================
  //  DASHBOARD
  // =========================================================================
  Widget _buildDashboard() {
    if (_isLoading) {
      return const SkeletonCardList(
        itemCount: 5,
        padding: EdgeInsets.fromLTRB(14, 14, 14, 110),
      );
    }
    return RefreshIndicator(
      onRefresh: _refreshHomeData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroCard(),
            const SizedBox(height: 10),
            _buildMetricsGrid(),
            const SizedBox(height: 10),
            _buildRecentBookingsSection(),
            const SizedBox(height: 10),
            _buildTipCard(),
          ],
        ),
      ),
    );
  }

  // -- Hero card -------------------------------------------------------------
  Widget _buildHeroCard() {
    final hasImg = _hasImg(_profileImagePath);

    return Container(
      decoration: BoxDecoration(
        color: _HC.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _HC.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3264).withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_HC.teal, _HC.indigo, Color(0xFFF79009)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _name.isEmpty ? 'Welcome!' : _name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.text,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_email.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              _email,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _chip(
                                Icons.workspace_premium_outlined,
                                'Vendor Console',
                                _HC.amberSoft,
                                _HC.amberBorder,
                                _HC.amber,
                              ),
                              _chip(
                                _isOn
                                    ? Icons.check_circle_rounded
                                    : Icons.pause_circle_outline_rounded,
                                _isOn ? 'Available' : 'Offline',
                                _isOn ? _HC.tealSoft : const Color(0xFFF2F4F7),
                                _isOn ? _HC.tealBorder : AppColors.border,
                                _isOn ? _HC.teal : AppColors.muted,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => setState(() => _selectedIndex = 3),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              color: _HC.tealSoft,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _HC.tealBorder,
                                width: 1.5,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: hasImg
                                ? _imgPreview(_profileImagePath!)
                                : const Icon(
                                    Icons.person_rounded,
                                    color: _HC.teal,
                                    size: 30,
                                  ),
                          ),
                          Positioned(
                            bottom: -4,
                            right: -4,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: _HC.teal,
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(color: _HC.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                color: Colors.white,
                                size: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _HC.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _HC.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _isOn ? _HC.tealSoft : const Color(0xFFF2F4F7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _isOn ? _HC.tealBorder : AppColors.border,
                          ),
                        ),
                        child: Icon(
                          _isOn
                              ? Icons.check_circle_rounded
                              : Icons.pause_circle_outline_rounded,
                          color: _isOn ? _HC.teal : AppColors.muted,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Accepting new jobs',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isOn
                                  ? 'Availability preference saved'
                                  : 'New-job preference paused',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isOn,
                        activeThumbColor: _HC.teal,
                        activeTrackColor: _HC.tealSoft,
                        inactiveThumbColor: AppColors.muted,
                        onChanged: _setAvailability,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _stat('${_allBookings.length}', 'Bookings'),
                    const SizedBox(width: 7),
                    _stat(_ratingLabel, 'Rating'),
                    const SizedBox(width: 7),
                    _stat(_money(_totalEarnings), 'Earned'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String val, String lbl) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: _HC.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _HC.border),
      ),
      child: Column(
        children: [
          Text(
            val,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            lbl.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _chip(IconData icon, String label, Color bg, Color bc, Color fg) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: bc),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );

  // -- Metrics 2×2 grid ------------------------------------------------------
  Widget _buildMetricsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _metricTile(
                label: 'Total Bookings',
                value: '${_allBookings.length}',
                icon: Icons.calendar_today_outlined,
                tint: AppColors.primary,
                onTap: () => setState(() => _selectedIndex = 1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricTile(
                label: 'Total Services',
                value: '${_completedBookings.length}',
                icon: Icons.build_outlined,
                tint: AppColors.accent,
                onTap: () => setState(() => _selectedIndex = 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _metricTile(
                label: 'Total Earning',
                value: _money(_totalEarnings),
                icon: Icons.currency_rupee_outlined,
                tint: AppColors.success,
                onTap: _openWallet,
                showArrow: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricTile(
                label: 'My Wallet',
                value: _money(_totalEarnings),
                icon: Icons.account_balance_wallet_outlined,
                tint: AppColors.warning,
                onTap: _openWallet,
                showArrow: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _metricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color tint,
    VoidCallback? onTap,
    bool showArrow = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _HC.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _HC.border),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A3264).withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: tint, size: 22),
                ),
                if (showArrow) ...[
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: AppColors.muted,
                  ),
                ],
              ],
            ),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // -- Recent Bookings -------------------------------------------------------
  Widget _buildRecentBookingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Recent Bookings',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _selectedIndex = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCFE0FF)),
                ),
                child: const Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoadingRecentBookings)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(child: SkeletonInlineLoader(labelWidth: 126)),
          )
        else if (_recentBookings.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _HC.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _HC.border),
            ),
            child: const Text(
              'No recent assigned bookings yet.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else
          ..._recentBookings.map(
            (booking) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _bookingRow(
                icon: _bookingIcon(booking),
                iconBg: _bookingStatusSoft(booking.statusLabel),
                iconBorder: _bookingStatusBorder(booking.statusLabel),
                iconColor: _bookingStatusColor(booking.statusLabel),
                title: booking.serviceTitle,
                subtitle: _bookingSubtitle(booking),
                statusLabel: booking.statusLabel,
                statusBg: _bookingStatusSoft(booking.statusLabel),
                statusBorder: _bookingStatusBorder(booking.statusLabel),
                statusColor: _bookingStatusColor(booking.statusLabel),
              ),
            ),
          ),
      ],
    );
  }

  String _bookingSubtitle(TechnicianEnquiryModel booking) {
    final customer = booking.customerName.trim().isNotEmpty
        ? booking.customerName.trim()
        : 'Customer #${booking.userId}';
    final slot = booking.dateTimeSlot.trim().isNotEmpty
        ? booking.dateTimeSlot.trim()
        : booking.createdAt.trim();
    return slot.isEmpty ? customer : '$customer - $slot';
  }

  IconData _bookingIcon(TechnicianEnquiryModel booking) {
    final title = booking.serviceTitle.toLowerCase();
    if (title.contains('network') || title.contains('wifi')) {
      return Icons.wifi_outlined;
    }
    if (title.contains('screen') || title.contains('display')) {
      return Icons.monitor_outlined;
    }
    if (title.contains('software') || title.contains('app')) {
      return Icons.developer_mode_outlined;
    }
    return Icons.laptop_outlined;
  }

  Color _bookingStatusColor(String status) {
    if (status == 'Accepted') return _HC.teal;
    if (status == 'On The Way') return const Color(0xFF0EA5E9);
    if (status == 'Arrived') return const Color(0xFF8B5CF6);
    if (status == 'Inspection') return _HC.amber;
    if (status == 'Job Card') return _HC.indigo;
    if (status == 'Job Started') return _HC.teal;
    if (status == 'Job Completed' || status == 'Completed') return _HC.teal;
    if (status == 'Reallocated' || status == 'Expired') {
      return AppColors.muted;
    }
    return _HC.amber;
  }

  Color _bookingStatusSoft(String status) {
    final color = _bookingStatusColor(status);
    if (color == _HC.teal) return _HC.tealSoft;
    if (color == _HC.indigo) return _HC.indigoSoft;
    if (color == _HC.amber) return _HC.amberSoft;
    return color.withValues(alpha: .10);
  }

  Color _bookingStatusBorder(String status) {
    final color = _bookingStatusColor(status);
    if (color == _HC.teal) return _HC.tealBorder;
    if (color == _HC.indigo) return _HC.indigoBorder;
    if (color == _HC.amber) return _HC.amberBorder;
    return color.withValues(alpha: .24);
  }

  Widget _bookingRow({
    required IconData icon,
    required Color iconBg,
    required Color iconBorder,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String statusLabel,
    required Color statusBg,
    required Color statusBorder,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _HC.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _HC.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3264).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: iconBorder),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusBorder),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -- Tip card --------------------------------------------------------------
  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD4B0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFD4B0)),
            ),
            child: const Icon(
              Icons.tips_and_updates_outlined,
              color: AppColors.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keep documents updated',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: AppColors.text,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Verified profiles get faster approvals & higher bookings.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  //  STORE VIEW  — no scroll, full screen, premium design
  // =========================================================================
  Widget _buildStoreView() {
    if (_isStoreLoading) {
      return const _VendorStoreSkeleton();
    }
    if (_storeError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  size: 44,
                  color: AppColors.muted,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Store details could not be loaded',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _storeError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _loadStoreData,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Column(
      children: [
        // ── Full-bleed gradient hero ─────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F7A5A), Color(0xFF1A9E78), Color(0xFF2563C4)],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar inside hero
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'My Store',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // Live status toggle
                      GestureDetector(
                        onTap: () => setState(() => _isOn = !_isOn),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _isOn
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: _isOn
                                      ? _HC.teal
                                      : Colors.white.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _isOn ? 'Open' : 'Offline',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: _isOn
                                      ? _HC.teal
                                      : Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Store name + subtitle
                  Text(
                    _storeName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _storeLocation,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Stats row inside hero
                  Row(
                    children: [
                      _heroStat(_ratingLabel, '★  Rating'),
                      _heroDivider(),
                      _heroStat('${_completedBookings.length}', 'Jobs Done'),
                      _heroDivider(),
                      _heroStat(
                        _baseServiceFee.isEmpty ? '--' : 'Rs $_baseServiceFee',
                        'Base Fee',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Body — fills remaining space ─────────────────────────────────
        Expanded(
          child: Container(
            color: AppColors.page,
            child: RefreshIndicator(
              onRefresh: _loadStoreData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info rows — compact list style
                    _infoCard(
                      children: [
                        _infoRow(
                          Icons.location_on_outlined,
                          'Location',
                          _storeLocation,
                          _HC.indigo,
                          isFirst: true,
                        ),
                        _infoDivider(),
                        _infoRow(
                          Icons.payments_outlined,
                          'Base service fee',
                          'Rs $_baseServiceFee',
                          _HC.amber,
                        ),
                        _infoDivider(),
                        _infoRow(
                          Icons.call_outlined,
                          'Contact',
                          _storeContactNumber,
                          _HC.teal,
                        ),
                        _infoDivider(),
                        _infoRow(
                          Icons.email_outlined,
                          'Email',
                          _storeContactEmail,
                          _HC.indigo,
                        ),
                        _infoDivider(),
                        _infoRow(
                          Icons.percent_rounded,
                          'GST',
                          '$_taxPercent%',
                          _HC.teal,
                          isLast: true,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Services card
                    _infoCard(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 11, 14, 8),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: const Icon(
                                  Icons.handyman_outlined,
                                  color: AppColors.primary,
                                  size: 15,
                                ),
                              ),
                              const SizedBox(width: 9),
                              const Text(
                                'Available Services',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _availableServices
                                .map(
                                  (e) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySoft,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFFCFE0FF),
                                      ),
                                    ),
                                    child: Text(
                                      e,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),

                    // Bottom tip row
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _HC.amberSoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _HC.amberBorder),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.tips_and_updates_outlined,
                            color: _HC.amber,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Keep availability on to receive more customer bookings.',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _heroStat(String value, String label) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.72),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _heroDivider() => Container(
    width: 1,
    height: 32,
    color: Colors.white.withValues(alpha: 0.25),
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );

  Widget _infoCard({required List<Widget> children}) => Container(
    decoration: BoxDecoration(
      color: _HC.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _HC.border),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF1A3264).withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );

  Widget _infoDivider() => const Divider(
    height: 1,
    indent: 52,
    endIndent: 0,
    color: Color(0xFFEEF1F7),
  );

  Widget _infoRow(
    IconData icon,
    String label,
    String value,
    Color accent, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14, isFirst ? 10 : 9, 14, isLast ? 10 : 9),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accent, size: 15),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  //  BUILD
  // =========================================================================

  void _openHomeMenu() {
    _scaffoldKey.currentState?.openDrawer();
  }

  Widget _buildHomeDrawer() {
    final name = _name.trim().isEmpty ? 'SahuByte Partner' : _name.trim();
    final email = _email.trim().isEmpty ? _mobile.trim() : _email.trim();
    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.82,
      backgroundColor: _HC.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          child: Column(
            children: [
              Row(
                children: [
                  _buildProfileAvatar(50),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                          ),
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _menuTile(
                icon: Icons.home_rounded,
                title: 'Dashboard',
                subtitle: 'Today overview and recent bookings',
                selected: _selectedIndex == 0,
                onTap: () => _selectTabFromMenu(0),
              ),
              _menuTile(
                icon: Icons.assignment_rounded,
                title: 'Bookings',
                subtitle: 'New, accepted and completed jobs',
                selected: _selectedIndex == 1,
                onTap: () => _selectTabFromMenu(1),
              ),
              _menuTile(
                icon: Icons.store_rounded,
                title: 'Store',
                subtitle: 'Service area and problem list',
                selected: _selectedIndex == 2,
                onTap: () => _selectTabFromMenu(2),
              ),
              _menuTile(
                icon: Icons.person_rounded,
                title: 'Profile',
                subtitle: 'Documents, skills and account details',
                selected: _selectedIndex == 3,
                onTap: () => _selectTabFromMenu(3),
              ),
              const Spacer(),
              Material(
                color: _HC.surface,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    Navigator.pop(context);
                    await _handleProfileUpdated();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    child: Row(
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Refresh latest data',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectTabFromMenu(int index) {
    Navigator.pop(context);
    setState(() => _selectedIndex = index);
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? AppColors.primarySoft : _HC.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? _HC.indigoBorder : _HC.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: selected ? _HC.indigoSoft : _HC.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: selected ? AppColors.primary : AppColors.muted,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  color: selected ? _HC.teal : AppColors.muted,
                  size: 21,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Returns the AppBar for the given tab index (null for tabs that manage
  /// their own appbar, like Profile).
  PreferredSizeWidget? _appBarFor(int index) {
    if (index == 0) {
      // Home appbar
      return AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: IconButton(
            tooltip: 'Open menu',
            onPressed: _openHomeMenu,
            icon: const Icon(
              Icons.menu_rounded,
              color: AppColors.text,
              size: 28,
            ),
          ),
        ),
        title: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _HC.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Image.asset('assets/sahubyte_logo.png', height: 32),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.text,
                  size: 26,
                ),
                Positioned(
                  top: 8,
                  right: 1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC0394A),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      );
    }

    if (index == 2) {
      // Store tab manages its own header inside the hero banner
      return null;
    }

    return null; // Bookings & Profile manage their own appbar
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.page,
      appBar: _appBarFor(_selectedIndex),
      drawer: _buildHomeDrawer(),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboard(),
          BookingsView(
            technicianId: _technicianId,
            state: _state,
            refreshToken: _bookingsRefreshToken,
            onBack: () => setState(() => _selectedIndex = 0),
          ),
          _buildStoreView(),
          ProfileView(
            onBack: () => setState(() => _selectedIndex = 0),
            onProfileUpdated: _handleProfileUpdated,
            completedBookingsCount: _completedBookings.length,
            ratingLabel: _ratingLabel,
            totalEarnings: _totalEarnings,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _HC.white,
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A3264).withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.muted,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment_rounded),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.store_outlined),
              activeIcon: Icon(Icons.store_rounded),
              label: 'Store',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _VendorStoreSkeleton extends StatelessWidget {
  const _VendorStoreSkeleton();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const SkeletonBox(width: double.infinity, height: 210, radius: 0),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: const [
            SkeletonBox(width: double.infinity, height: 235, radius: 16),
            SizedBox(height: 12),
            SkeletonBox(width: double.infinity, height: 130, radius: 16),
          ],
        ),
      ),
    ],
  );
}
