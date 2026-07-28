import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sahubyte_vendor/model/response/technician_skill_model.dart';
import 'package:sahubyte_vendor/model/vendor_profile.dart';
import 'package:sahubyte_vendor/repository/auth_session_store.dart';
import 'package:sahubyte_vendor/repository/vendor_profile_store.dart';
import 'package:sahubyte_vendor/view/app_ui.dart';
import 'package:sahubyte_vendor/view/welcome_view.dart';
import 'package:sahubyte_vendor/view_model/technician_view_model.dart';
import 'package:sahubyte_vendor/view_model/user_view_model.dart';

class _PC {
  static const bg = Color(0xFFF5F3EF);
  static const white = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF9F8F6);
  static const border = Color(0xFFE8E4DC);
  static const teal = Color(0xFF1A9E78);
  static const tealSoft = Color(0xFFE8F7F2);
  static const tealBorder = Color(0xFFB8E8D8);
  static const indigo = Color(0xFF4361C2);
  static const indigoSoft = Color(0xFFEEF1FB);
  static const indigoBorder = Color(0xFFC4CEEE);
  static const amber = Color(0xFFB87B2E);
  static const amberSoft = Color(0xFFFBF4E8);
  static const amberBorder = Color(0xFFEDCF9A);
  static const rose = Color(0xFFC0394A);
  static const roseSoft = Color(0xFFFAEAEC);
  static const roseBorder = Color(0xFFEDBBBC);
  static const dim = Color(0xFFC4BFB8);
}

class ProfileView extends StatefulWidget {
  const ProfileView({
    super.key,
    this.onBack,
    this.onProfileUpdated,
    this.completedBookingsCount = 0,
    this.ratingLabel = '--',
    this.totalEarnings = 0,
  });

  final VoidCallback? onBack;
  final VoidCallback? onProfileUpdated;
  final int completedBookingsCount;
  final String ratingLabel;
  final int totalEarnings;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _profileStore = VendorProfileStore();
  final _userViewModel = UserViewModel();
  final _technicianViewModel = TechnicianViewModel();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _dobController = TextEditingController();
  final _expertiseController = TextEditingController();
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _ifscController = TextEditingController();
  final _accountNoController = TextEditingController();
  final _upiNoController = TextEditingController();
  final _imagePicker = ImagePicker();
  VoidCallback? _openSectionRefresh;
  String? _selectedState;

  static const _qualificationOptions = [
    '8th Pass',
    '10th Pass',
    '12th Pass',
    'Graduate',
    'Diploma',
    'ITI',
    'Post Graduate',
  ];
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
  bool _isLoading = true;
  bool _isLoadingProblemData = true;
  bool _isLoadingSavedSkills = false;
  bool _isSavingSkills = false;
  final Set<String> _deletingSkillIds = {};
  bool _isUploadingProfileImage = false;
  final Set<String> _uploadingDocs = {};
  bool _isLoadingAdditionalDocs = false;
  bool _isSavingAdditionalDoc = false;
  String _technicianId = '';
  String? _profileImagePath;
  final Map<String, String> _docImagePaths = {};
  List<Map<String, dynamic>> _additionalDocs = const [];
  String? _selectedQualification;
  String? _storedCategoryId;
  String? _storedSubCategoryId;
  String? _selectedCategoryId;
  String? _selectedSubCategoryId;
  String? _problemDataError;
  List<Map<String, dynamic>> _categories = const [];
  List<Map<String, dynamic>> _subCategories = const [];
  List<TechnicianSkillModel> _savedSkills = const [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadProblemMasterData();
  }

  @override
  void dispose() {
    _userViewModel.dispose();
    _technicianViewModel.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _dobController.dispose();
    _expertiseController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _accountNameController.dispose();
    _ifscController.dispose();
    _accountNoController.dispose();
    _upiNoController.dispose();
    super.dispose();
  }

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
    _nameController.text = profile.name;
    _emailController.text = profile.email;
    _mobileController.text = profile.mobile;
    _dobController.text = profile.dob;
    _expertiseController.text = profile.expertise;
    _addressController.text = profile.address;
    _pincodeController.text = profile.pincode;
    _accountNameController.text = profile.accountName;
    _ifscController.text = profile.ifsc;
    _accountNoController.text = profile.accountNo;
    _upiNoController.text = profile.upiNo;
    _selectedState = profile.state.isEmpty ? null : profile.state;
    _storedCategoryId = profile.categoryId;
    _storedSubCategoryId = profile.subCategoryId;
    // Load cached images first so something shows immediately
    _profileImagePath ??= await _profileStore.getProfileImagePath();
    _docImagePaths
      ..clear()
      ..addAll(await _profileStore.getDocumentPaths());
    await _loadServerDocumentImages();
    await _loadAdditionalDocs();
    await _loadSavedSkills();
    if (_categories.isNotEmpty) _applyStoredServiceSelection();
    setState(() => _isLoading = false);
  }

  Future<void> _refreshProfileData() async {
    try {
      await Future.wait([_loadProfile(), _loadProblemMasterData()]);
    } catch (error) {
      if (!mounted) return;
      _snack(
        professionalErrorMessage(
          error,
          fallback: 'Profile could not be refreshed. Please try again.',
        ),
      );
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
          final rawImg = _rv(row, const ['profileImage']);
          debugPrint('RAW profileImage from server [$t]: "$rawImg"');
          final img = _resolveImg(rawImg);
          debugPrint('RESOLVED URL: "$img"');
          if (img != null) {
            _profileImagePath =
                img; // always override — server is source of truth
            await _profileStore.saveProfileImagePath(img);
          }
          return _profileFromRow(row, local);
        }
      } catch (_) {}
    }
    return null;
  }

  Future<void> _loadServerDocumentImages() async {
    try {
      final res = await _userViewModel.getData(tableName: 'technicianDocs');
      if (res.rows.isEmpty) return;
      // Match only by the current technician id so another user's docs never leak in.
      Map<String, dynamic>? row;
      for (final r in res.rows) {
        if (r['technicianId']?.toString() == _technicianId) {
          row = r;
          break;
        }
      }
      if (row == null) return;
      final docs = {
        'aadhar': _resolveImg(_rv(row, const ['aadharImage'])),
        'pan': _resolveImg(_rv(row, const ['panImage'])),
        'driving': _resolveImg(_rv(row, const ['drivingImage'])),
      };
      debugPrint('RAW aadharImage: "${_rv(row, const ['aadharImage'])}"');
      debugPrint('RAW panImage: "${_rv(row, const ['panImage'])}"');
      debugPrint('RAW drivingImage: "${_rv(row, const ['drivingImage'])}"');
      debugPrint('RESOLVED docs: $docs');
      final q = _rv(row, const ['qualification']);
      if (q.isNotEmpty && q.toLowerCase() != 'null') _selectedQualification = q;
      for (final e in docs.entries) {
        if (e.value != null) {
          _docImagePaths[e.key] = e.value!;
          await _profileStore.saveDocumentPath(e.key, e.value!);
        }
      }
    } catch (_) {}
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
        pincode: _vof(
          _rv(row, const ['pincode', 'pinCode', 'postalCode']),
          fb.pincode,
        ),
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

  Future<void> _loadProblemMasterData() async {
    setState(() {
      _isLoadingProblemData = true;
      _problemDataError = null;
    });
    try {
      final r = await Future.wait([
        _userViewModel.getData(tableName: 'category'),
        _userViewModel.getData(tableName: 'subCategory'),
      ]);
      if (!mounted) return;
      _categories = r[0].rows;
      _subCategories = r[1].rows;
      if (_savedSkills.isNotEmpty) {
        _storedCategoryId = _savedSkills.last.categoryId;
        _storedSubCategoryId = _savedSkills.last.subCategoryId;
      }
      _applyStoredServiceSelection();
      setState(() => _isLoadingProblemData = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _problemDataError = professionalErrorMessage(
          e,
          fallback: 'Service categories could not be refreshed.',
        );
        _isLoadingProblemData = false;
      });
    }
  }

  Future<void> _loadSavedSkills() async {
    if (_technicianId.trim().isEmpty) return;
    setState(() => _isLoadingSavedSkills = true);
    try {
      final skills = await _technicianViewModel.getTechnicianSkills(
        technicianId: _technicianId,
      );
      if (!mounted) return;
      setState(() {
        _savedSkills = skills;
        if (skills.isNotEmpty) {
          _storedCategoryId = skills.last.categoryId;
          _storedSubCategoryId = skills.last.subCategoryId;
        }
        _isLoadingSavedSkills = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingSavedSkills = false);
    }
  }

  List<Map<String, dynamic>> get _filteredSubs {
    if (_selectedCategoryId == null) return const [];
    return _subCategories
        .where((i) => i['categoryId']?.toString() == _selectedCategoryId)
        .toList();
  }

  String get _catName => _rowName(_categories, _selectedCategoryId, const [
    'categoryName',
    'name',
  ]);
  String get _subName => _rowName(
    _subCategories,
    _selectedSubCategoryId,
    const ['subCategoryName', 'name'],
  );

  String _rowName(
    List<Map<String, dynamic>> rows,
    String? id,
    List<String> keys,
  ) {
    if (id == null) return '';
    for (final r in rows) {
      if (r['id']?.toString() == id) return _rv(r, keys);
    }
    return '';
  }

  void _applyStoredServiceSelection() {
    if (_categories.isEmpty) return;
    final sc = _storedCategoryId;
    final ss = _storedSubCategoryId;
    final exp = _expertiseController.text.trim().toLowerCase();
    final catFromId =
        sc != null && _categories.any((i) => i['id']?.toString() == sc);
    final catFromName = _categories
        .where(
          (i) => _rv(i, const ['categoryName', 'name']).toLowerCase() == exp,
        )
        .toList();
    _selectedCategoryId = catFromId
        ? sc
        : catFromName.isNotEmpty
        ? catFromName.first['id']?.toString()
        : _categories.first['id']?.toString();
    final filtered = _filteredSubs;
    final subFromId =
        ss != null && filtered.any((i) => i['id']?.toString() == ss);
    _selectedSubCategoryId = subFromId
        ? ss
        : filtered.isNotEmpty
        ? filtered.first['id']?.toString()
        : null;
    final cn = _catName;
    if (cn.isNotEmpty) _expertiseController.text = cn;
  }

  // ── save / actions ────────────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    final cn = _catName;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final mobile = _mobileController.text.trim();
    final dob = _dobController.text.trim();
    final address = _addressController.text.trim();
    final state = _selectedState ?? '';
    final pincode = _pincodeController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(pincode)) {
      throw Exception('Enter a valid 6 digit pincode.');
    }
    final accountName = _accountNameController.text.trim();
    final ifsc = _ifscController.text.trim();
    final accountNo = _accountNoController.text.trim();
    final upiNo = _upiNoController.text.trim();
    await _profileStore.saveProfile(
      VendorProfile(
        technicianId: _technicianId,
        name: name,
        email: email,
        mobile: mobile,
        dob: dob,
        expertise: cn.isEmpty ? _expertiseController.text.trim() : cn,
        address: address,
        state: state,
        pincode: pincode,
        accountName: accountName,
        ifsc: ifsc,
        accountNo: accountNo,
        upiNo: upiNo,
        categoryId: _selectedCategoryId,
        subCategoryId: _selectedSubCategoryId,
      ),
    );
    final response = await _technicianViewModel.updateTechnicianProfile(
      technicianId: _technicianId,
      name: name,
      email: email,
      mobile: mobile,
      dob: dob,
      address: address,
      state: state,
      pincode: pincode,
    );
    if (!response.isSuccess) throw Exception(response.displayMessage);
    if (!mounted) return;
    widget.onProfileUpdated?.call();
    _snack('Profile saved successfully.');
    setState(() {});
  }

  Future<void> _saveBanking() async {
    final cn = _catName;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final mobile = _mobileController.text.trim();
    final dob = _dobController.text.trim();
    final address = _addressController.text.trim();
    final state = _selectedState ?? '';
    final pincode = _pincodeController.text.trim();
    final accountName = _accountNameController.text.trim();
    final ifsc = _ifscController.text.trim();
    final accountNo = _accountNoController.text.trim();
    final upiNo = _upiNoController.text.trim();
    await _profileStore.saveProfile(
      VendorProfile(
        technicianId: _technicianId,
        name: name,
        email: email,
        mobile: mobile,
        dob: dob,
        expertise: cn.isEmpty ? _expertiseController.text.trim() : cn,
        address: address,
        state: state,
        pincode: pincode,
        accountName: accountName,
        ifsc: ifsc,
        accountNo: accountNo,
        upiNo: upiNo,
        categoryId: _selectedCategoryId,
        subCategoryId: _selectedSubCategoryId,
      ),
    );
    final response = await _technicianViewModel.updateTechnicianBanking(
      technicianId: _technicianId,
      accountName: accountName,
      ifsc: ifsc,
      accountNo: accountNo,
      upiNo: upiNo,
    );
    if (!response.isSuccess) throw Exception(response.displayMessage);
    if (!mounted) return;
    widget.onProfileUpdated?.call();
    _snack('Banking details saved successfully.');
    setState(() {});
  }

  Future<void> _submitSkills() async {
    try {
      final saved = await _saveSkills(validate: true);
      if (!mounted) return;
      if (saved) {
        widget.onProfileUpdated?.call();
        _snack('Technician skills saved successfully.');
      }
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString());
    }
  }

  Future<bool> _saveSkills({required bool validate}) async {
    final cid = _selectedCategoryId;
    final sid = _selectedSubCategoryId;
    if (cid == null || sid == null) {
      if (validate) throw Exception('Select category and sub category.');
      return false;
    }
    setState(() => _isSavingSkills = true);
    try {
      final alreadySaved = await _hasSavedSkill(
        categoryId: cid,
        subCategoryId: sid,
      );
      if (alreadySaved) {
        if (validate) {
          _snack('This category and sub category is already added.');
        }
        return false;
      }
      final res = await _technicianViewModel.addTechnicianSkills(
        technicianId: _technicianId,
        categoryId: cid,
        subCategoryId: sid,
      );
      if (!res.isSuccess) throw Exception(res.displayMessage);
      await _loadSavedSkills();
      _refreshOpen();
      return true;
    } finally {
      if (mounted) setState(() => _isSavingSkills = false);
    }
  }

  Future<bool> _hasSavedSkill({
    required String categoryId,
    required String subCategoryId,
  }) async {
    if (_technicianId.trim().isEmpty) return false;
    final latest = await _technicianViewModel.getTechnicianSkills(
      technicianId: _technicianId,
    );
    if (mounted) setState(() => _savedSkills = latest);
    return latest.any(
      (skill) =>
          skill.categoryId == categoryId &&
          skill.subCategoryId == subCategoryId,
    );
  }

  Future<void> _deleteSkill(TechnicianSkillModel skill) async {
    if (skill.id.trim().isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete service skill?'),
        content: const Text(
          'This category and sub category will be removed from your technician skills.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: _PC.rose)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _deletingSkillIds.add(skill.id));
    _refreshOpen();
    try {
      final response = await _technicianViewModel.deleteTechnicianSkill(
        skill.id,
      );
      if (!response.isSuccess) throw Exception(response.displayMessage);
      await _loadSavedSkills();
      if (!mounted) return;
      widget.onProfileUpdated?.call();
      _snack('Skill deleted successfully.');
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString());
    } finally {
      if (mounted) {
        setState(() => _deletingSkillIds.remove(skill.id));
        _refreshOpen();
      }
    }
  }

  Future<void> _logout() async {
    await AuthSessionStore().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeView()),
      (_) => false,
    );
  }

  Future<void> _updateProfileImage() async {
    setState(() => _isUploadingProfileImage = true);
    try {
      final img = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 72,
        maxWidth: 1000,
      );
      if (img == null) return;
      final saved = await _copyImage(
        img,
        'technicianProfile',
        'profile_${_technicianId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final fileName = saved.uri.pathSegments.last;
      final imageBase64 = await _fileToBase64(saved);
      final res = await _technicianViewModel.updateProfileImage(
        technicianId: _technicianId,
        profileImage: imageBase64,
        folderName: 'technicianProfile',
        fileName: fileName,
        imageBase64: imageBase64,
      );
      if (!res.isSuccess) throw Exception(res.displayMessage);
      if (!mounted) return;

      // Server doesn't return the path in response — re-fetch the row to get actual saved URL
      final serverPath = await _fetchProfileImageFromServer();
      final finalPath = serverPath ?? saved.path;
      debugPrint(
        'RE-FETCHED serverPath: $serverPath  →  finalPath: $finalPath',
      );

      await _profileStore.saveProfileImagePath(finalPath);
      setState(() => _profileImagePath = finalPath);
      _snack('Profile image updated successfully.');
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _isUploadingProfileImage = false);
    }
  }

  // Re-fetch technician row and return the actual profileImage URL from server
  Future<String?> _fetchProfileImageFromServer() async {
    try {
      for (final t in ['technician', 'userLogin', 'userlogin']) {
        final res = await _userViewModel.getData(tableName: t);
        final sessionMobile = await AuthSessionStore().getLoggedInMobile();
        final storedLocal = await _profileStore.getProfile();
        final local = sessionMobile == null
            ? storedLocal
            : storedLocal.copyWith(mobile: sessionMobile);
        final row = _findMatchingProfileRow(res.rows, local);
        if (row != null) {
          final img = _resolveImg(_rv(row, const ['profileImage']));
          if (img != null && img.isNotEmpty) return img;
          return null; // row found but no image yet
        }
      }
    } catch (_) {}
    return null;
  }

  // Re-fetch technicianDocs row and return the actual doc URL from server
  Future<String?> _fetchDocImageFromServer(String field) async {
    try {
      final res = await _userViewModel.getData(tableName: 'technicianDocs');
      for (final r in res.rows) {
        if (r['technicianId']?.toString() == _technicianId) {
          final keyMap = {
            'aadhar': const ['aadharImage'],
            'pan': const ['panImage'],
            'driving': const ['drivingImage'],
          };
          final keys = keyMap[field];
          if (keys == null) return null;
          final url = _resolveImg(_rv(r, keys));
          if (url != null && url.isNotEmpty) return url;
          return null;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _loadAdditionalDocs() async {
    if (_technicianId.trim().isEmpty) return;
    setState(() => _isLoadingAdditionalDocs = true);
    _refreshOpen();
    try {
      final res = await _userViewModel.getData(
        tableName: 'technicianAdditionalDocs',
      );
      final docs = res.rows
          .where((row) => row['technicianId']?.toString() == _technicianId)
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      if (!mounted) return;
      setState(() => _additionalDocs = docs);
      _refreshOpen();
    } catch (_) {
      if (!mounted) return;
      setState(() => _additionalDocs = const []);
      _refreshOpen();
    } finally {
      if (mounted) {
        setState(() => _isLoadingAdditionalDocs = false);
        _refreshOpen();
      }
    }
  }

  Future<void> _openAdditionalDocSheet({Map<String, dynamic>? doc}) async {
    final nameController = TextEditingController(
      text: _rv(doc ?? const {}, const ['documentName']),
    );
    XFile? selectedImage;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _PC.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> pick(ImageSource source) async {
              final img = await _imagePicker.pickImage(
                source: source,
                imageQuality: 72,
                maxWidth: 1200,
              );
              if (img != null) setSheetState(() => selectedImage = img);
            }

            Future<void> submit() async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                _snack('Enter document name.');
                return;
              }
              if (doc == null && selectedImage == null) {
                _snack('Select document image.');
                return;
              }
              Navigator.pop(ctx, true);
              await _saveAdditionalDoc(
                id: _rv(doc ?? const {}, const ['id']),
                documentName: name,
                image: selectedImage,
              );
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                12,
                18,
                18 + MediaQuery.viewInsetsOf(ctx).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _PC.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    doc == null ? 'Add Document' : 'Update Document',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Document name',
                      hintText: 'Experience certificate, marksheet, etc.',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _PC.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _PC.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selectedImage == null
                              ? Icons.file_upload_outlined
                              : Icons.check_circle_rounded,
                          color: selectedImage == null ? _PC.indigo : _PC.teal,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            selectedImage == null
                                ? doc == null
                                      ? 'Choose image from camera or gallery'
                                      : 'Choose image only if you want to replace'
                                : selectedImage!.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => pick(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Camera'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => pick(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Gallery'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSavingAdditionalDoc ? null : submit,
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: Text(doc == null ? 'Upload Document' : 'Save'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    nameController.dispose();
    if (saved == true) _refreshOpen();
  }

  Future<void> _saveAdditionalDoc({
    required String id,
    required String documentName,
    XFile? image,
  }) async {
    setState(() => _isSavingAdditionalDoc = true);
    _refreshOpen();
    try {
      String? imageBase64;
      if (image != null) {
        final saved = await _copyImage(
          image,
          'technicianAdditionalDocs',
          'additional_${_technicianId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        imageBase64 = await _fileToBase64(saved);
      }
      final res = await _technicianViewModel.saveAdditionalTechnicianDoc(
        id: id,
        technicianId: _technicianId,
        documentName: documentName,
        documentImage: imageBase64,
      );
      if (!res.isSuccess) throw Exception(res.displayMessage);
      await _loadAdditionalDocs();
      if (!mounted) return;
      _snack(res.displayMessage);
    } catch (e) {
      if (!mounted) return;
      _snack(
        professionalErrorMessage(
          e,
          fallback: 'Additional document could not be saved. Try again.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingAdditionalDoc = false);
        _refreshOpen();
      }
    }
  }

  Future<void> _uploadDocument(
    String field, {
    ImageSource source = ImageSource.camera,
  }) async {
    setState(() => _uploadingDocs.add(field));
    _refreshOpen();
    try {
      final img = await _imagePicker.pickImage(
        source: source,
        imageQuality: 72,
        maxWidth: 1200,
      );
      if (img == null) return;
      final saved = await _copyImage(
        img,
        'technicianDocs',
        '${field}_${_technicianId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final fileName = saved.uri.pathSegments.last;
      final imageBase64 = await _fileToBase64(saved);
      final res = await _technicianViewModel.updateTechnicianDocs(
        technicianId: _technicianId,
        folderName: 'technicianDocs',
        fileName: fileName,
        aadharImage: field == 'aadhar' ? imageBase64 : null,
        panImage: field == 'pan' ? imageBase64 : null,
        drivingImage: field == 'driving' ? imageBase64 : null,
        additionalDoc: field == 'additional' ? imageBase64 : null,
      );
      if (!res.isSuccess) throw Exception(res.displayMessage);
      if (!mounted) return;

      // Server doesn't return path — re-fetch the row to get actual saved URL
      final serverPath = await _fetchDocImageFromServer(field);
      final finalPath = serverPath ?? saved.path;
      debugPrint(
        'DOC RE-FETCHED serverPath: $serverPath  →  finalPath: $finalPath',
      );

      await _profileStore.saveDocumentPath(field, finalPath);
      setState(() => _docImagePaths[field] = finalPath);
      _refreshOpen();
      _snack('${_docLabel(field)} uploaded.');
    } catch (e) {
      if (!mounted) return;
      _snack(
        professionalErrorMessage(
          e,
          fallback: '${_docLabel(field)} could not be uploaded. Try again.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _uploadingDocs.remove(field));
        _refreshOpen();
      }
    }
  }

  Future<void> _saveQualification(String value) async {
    setState(() => _selectedQualification = value);
    _refreshOpen();
    try {
      final res = await _technicianViewModel.updateTechnicianDocs(
        technicianId: _technicianId,
        folderName: 'technicianDocs',
        fileName: 'qualification',
        qualification: value,
      );
      if (!res.isSuccess) throw Exception(res.displayMessage);
      if (!mounted) return;
      _snack('Qualification updated successfully.');
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString());
    }
  }

  Future<File> _copyImage(XFile img, String folder, String name) async {
    final dir = await getApplicationDocumentsDirectory();
    final target = Directory('${dir.path}/$folder');
    if (!await target.exists()) await target.create(recursive: true);
    return File(img.path).copy('${target.path}/$name');
  }

  Future<String> _fileToBase64(File file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(professionalErrorMessage(msg, fallback: msg)),
        backgroundColor: AppColors.text,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(14),
      ),
    );
  }

  void _refreshOpen() => _openSectionRefresh?.call();

  String _docLabel(String f) {
    switch (f) {
      case 'aadhar':
        return 'Aadhaar Card';
      case 'pan':
        return 'PAN Card';
      case 'driving':
        return 'Driving License';
      case 'additional':
        return 'Additional Document';
      default:
        return 'Document';
    }
  }

  // ── image helpers ─────────────────────────────────────────────────────────

  // Returns: 'data:image/...' | 'https://...' | null
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

  Widget _imgPreview(String src, {BoxFit fit = BoxFit.cover}) {
    if (_isNet(src)) {
      return Image.network(
        src,
        fit: fit,
        headers: const {'Accept': 'image/*'},
        loadingBuilder: (_, child, p) => p == null
            ? child
            : const SkeletonBox(
                width: double.infinity,
                height: double.infinity,
                radius: 14,
              ),
        errorBuilder: (_, _, _) => const Center(
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
          fit: fit,
          errorBuilder: (_, _, _) => const Center(
            child: Icon(Icons.person_rounded, color: AppColors.muted),
          ),
        );
      } catch (_) {
        return const Center(
          child: Icon(Icons.person_rounded, color: AppColors.muted),
        );
      }
    }
    return Image.file(File(src), fit: fit);
  }

  // ── util ──────────────────────────────────────────────────────────────────
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

  String _moneyShort(int value) {
    if (value <= 0) return 'Rs. 0';
    if (value >= 100000) {
      final lakhs = value / 100000;
      return 'Rs. ${lakhs.toStringAsFixed(lakhs >= 10 ? 0 : 1)}L';
    }
    if (value >= 1000) {
      final thousands = value / 1000;
      return 'Rs. ${thousands.toStringAsFixed(thousands >= 10 ? 0 : 1)}k';
    }
    return 'Rs. $value';
  }

  bool get _hasBankingDetails =>
      _accountNameController.text.trim().isNotEmpty ||
      _ifscController.text.trim().isNotEmpty ||
      _accountNoController.text.trim().isNotEmpty ||
      _upiNoController.text.trim().isNotEmpty;

  String get _bankingSummary {
    final account = _accountNoController.text.trim();
    final upi = _upiNoController.text.trim();
    if (account.isNotEmpty) {
      final suffix = account.length <= 4
          ? account
          : account.substring(account.length - 4);
      return 'Account ending $suffix';
    }
    if (upi.isNotEmpty) return 'UPI: $upi';
    return 'Acc name, IFSC, account no, UPI no.';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _PC.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _isLoading
                  ? const SkeletonCardList(
                      itemCount: 5,
                      padding: EdgeInsets.fromLTRB(16, 4, 16, 40),
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshProfileData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeroCard(),
                            const SizedBox(height: 20),
                            _groupLabel('Account'),
                            const SizedBox(height: 8),
                            _buildMenuCard([
                              _menuRow(
                                icon: Icons.badge_outlined,
                                iconBg: _PC.amberSoft,
                                iconBorder: _PC.amberBorder,
                                iconColor: _PC.amber,
                                title: 'Personal Details',
                                sub: 'Name, mobile, email, DOB, address',
                                onTap: _showPersonalSheet,
                              ),
                              _menuRow(
                                icon: Icons.account_balance_outlined,
                                iconBg: _PC.tealSoft,
                                iconBorder: _PC.tealBorder,
                                iconColor: _PC.teal,
                                title: 'Banking Details',
                                sub: _bankingSummary,
                                badge: _hasBankingDetails ? 'Added' : 'Add',
                                badgeBg: _hasBankingDetails
                                    ? _PC.tealSoft
                                    : _PC.amberSoft,
                                badgeBorder: _hasBankingDetails
                                    ? _PC.tealBorder
                                    : _PC.amberBorder,
                                badgeColor: _hasBankingDetails
                                    ? _PC.teal
                                    : _PC.amber,
                                onTap: _showBankingSheet,
                              ),
                            ]),
                            const SizedBox(height: 16),
                            _groupLabel('Services'),
                            const SizedBox(height: 8),
                            _buildMenuCard([
                              _menuRow(
                                icon: Icons.handyman_outlined,
                                iconBg: _PC.indigoSoft,
                                iconBorder: _PC.indigoBorder,
                                iconColor: _PC.indigo,
                                title: 'Service Category',
                                sub: _catName.isEmpty
                                    ? 'Choose category and sub category'
                                    : _subName.isEmpty
                                    ? _catName
                                    : '$_catName — $_subName',
                                badge: _selectedSubCategoryId == null
                                    ? 'Select'
                                    : 'Ready',
                                badgeBg: _PC.indigoSoft,
                                badgeBorder: _PC.indigoBorder,
                                badgeColor: _PC.indigo,
                                onTap: () => _openSection(
                                  'Services',
                                  _buildServicesSection,
                                ),
                              ),
                            ]),
                            const SizedBox(height: 16),
                            _groupLabel('Verification'),
                            const SizedBox(height: 8),
                            _buildMenuCard([
                              _menuRow(
                                icon: Icons.shield_outlined,
                                iconBg: _PC.tealSoft,
                                iconBorder: _PC.tealBorder,
                                iconColor: _PC.teal,
                                title: 'Documents',
                                sub: _selectedQualification == null
                                    ? 'Qualification, Aadhaar, PAN, Driving'
                                    : 'Qualification: $_selectedQualification',
                                badge:
                                    '${_docImagePaths.values.where(_hasImg).length} / 3',
                                badgeBg: _PC.tealSoft,
                                badgeBorder: _PC.tealBorder,
                                badgeColor: _PC.teal,
                                onTap: () => _openSection(
                                  'Documents',
                                  _buildDocsSection,
                                ),
                              ),
                            ]),
                            const SizedBox(height: 24),
                            _buildLogoutBtn(),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _iconBtn(
            Icons.arrow_back_ios_new_rounded,
            widget.onBack ?? () => Navigator.maybePop(context),
          ),
          const Spacer(),
          const Text(
            'My Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _PC.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _PC.border),
      ),
      child: Icon(icon, size: 18, color: AppColors.text),
    ),
  );

  Widget _buildHeroCard() {
    final role = _catName.isNotEmpty
        ? '$_catName Technician'
        : _expertiseController.text.isEmpty
        ? 'Technician Partner'
        : '${_expertiseController.text} Technician';
    final sub = _subName.isEmpty ? 'Service profile' : _subName;

    return Container(
      decoration: BoxDecoration(
        color: _PC.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _PC.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // accent bar
          Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_PC.teal, _PC.indigo, _PC.amber],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAvatar(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nameController.text.isEmpty
                                ? 'Your Name'
                                : _nameController.text,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _emailController.text.isEmpty
                                ? 'Complete your profile'
                                : _emailController.text,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _chip(
                                Icons.phone_outlined,
                                _mobileController.text.isEmpty
                                    ? 'Mobile'
                                    : _mobileController.text,
                                _PC.tealSoft,
                                _PC.tealBorder,
                                _PC.teal,
                              ),
                              _chip(
                                Icons.school_outlined,
                                _selectedQualification ?? 'Qualification',
                                _PC.indigoSoft,
                                _PC.indigoBorder,
                                _PC.indigo,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // status strip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _PC.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _PC.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _PC.indigoSoft,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _PC.indigoBorder),
                        ),
                        child: const Icon(
                          Icons.handyman_outlined,
                          color: _PC.indigo,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              role,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              sub,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: _PC.tealSoft,
                          shape: BoxShape.circle,
                          border: Border.all(color: _PC.tealBorder),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: _PC.teal,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // stats
                Row(
                  children: [
                    _stat('${widget.completedBookingsCount}', 'Bookings'),
                    const SizedBox(width: 8),
                    _stat(widget.ratingLabel, 'Rating'),
                    const SizedBox(width: 8),
                    _stat(_moneyShort(widget.totalEarnings), 'Earned'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final has = _hasImg(_profileImagePath);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: has
              ? () => _previewDoc('Profile Image', _profileImagePath!)
              : _updateProfileImage,
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: _PC.tealSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _PC.tealBorder, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: has
                ? _imgPreview(_profileImagePath!)
                : const Icon(Icons.person_rounded, color: _PC.teal, size: 32),
          ),
        ),
        Positioned(
          bottom: -5,
          right: -5,
          child: GestureDetector(
            onTap: _isUploadingProfileImage ? null : _updateProfileImage,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: _PC.teal,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _PC.white, width: 2),
              ),
              child: _isUploadingProfileImage
                  ? const SkeletonBox(width: 22, height: 22, radius: 7)
                  : const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 13,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stat(String val, String lbl) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: _PC.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _PC.border),
      ),
      child: Column(
        children: [
          Text(
            val,
            style: const TextStyle(
              fontSize: 18,
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
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );

  Widget _groupLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.muted,
        letterSpacing: 1.0,
      ),
    ),
  );

  Widget _buildMenuCard(List<Widget> items) => Container(
    decoration: BoxDecoration(
      color: _PC.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _PC.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(children: items),
  );

  Widget _menuRow({
    required IconData icon,
    required Color iconBg,
    required Color iconBorder,
    required Color iconColor,
    required String title,
    required String sub,
    required VoidCallback onTap,
    String? badge,
    Color? badgeBg,
    Color? badgeBorder,
    Color? badgeColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: badgeBorder!),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Widget _buildLogoutBtn() => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: _logout,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: _PC.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _PC.roseBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: _PC.rose, size: 18),
            const SizedBox(width: 9),
            const Text(
              'Sign Out',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _PC.rose,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // ─── Personal details sheet ───────────────────────────────────────────────
  Future<void> _showPersonalSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _PC.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 12,
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHandle(),
                const SizedBox(height: 18),
                _sheetHeader(
                  Icons.person_outline,
                  _PC.amberSoft,
                  _PC.amberBorder,
                  _PC.amber,
                  'Personal Details',
                  'Update your contact information',
                ),
                const SizedBox(height: 20),
                _field('Full Name', _nameController, Icons.person_outline),
                _field('Email Address', _emailController, Icons.mail_outline),
                _field(
                  'Mobile Number',
                  _mobileController,
                  Icons.phone_outlined,
                  type: TextInputType.phone,
                ),
                _field('Date of Birth', _dobController, Icons.cake_outlined),
                _field(
                  'Address',
                  _addressController,
                  Icons.location_on_outlined,
                  lines: 2,
                ),
                _field(
                  'Pincode',
                  _pincodeController,
                  Icons.pin_drop_outlined,
                  type: TextInputType.number,
                ),
                _dropdown<String>(
                  label: 'State',
                  hint: 'Select state',
                  icon: Icons.map_outlined,
                  value: _stateOptions.contains(_selectedState)
                      ? _selectedState
                      : null,
                  items: _stateOptions
                      .map(
                        (state) =>
                            DropdownMenuItem(value: state, child: Text(state)),
                      )
                      .toList(),
                  onChanged: (state) {
                    setState(() => _selectedState = state);
                  },
                ),
                const SizedBox(height: 6),
                _primaryBtn(
                  label: _isSavingSkills ? 'Saving…' : 'Save Profile',
                  icon: Icons.check_rounded,
                  color: _PC.teal,
                  onPressed: _isSavingSkills
                      ? null
                      : () async {
                          try {
                            await _saveProfile();
                            if (ctx.mounted) Navigator.pop(ctx);
                          } catch (e) {
                            if (!mounted) return;
                            _snack(e.toString());
                          }
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showBankingSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _PC.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 12,
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHandle(),
                const SizedBox(height: 18),
                _sheetHeader(
                  Icons.account_balance_outlined,
                  _PC.tealSoft,
                  _PC.tealBorder,
                  _PC.teal,
                  'Banking Details',
                  'Add payout account and UPI details',
                ),
                const SizedBox(height: 20),
                _field(
                  'Acc name',
                  _accountNameController,
                  Icons.person_pin_outlined,
                ),
                _field(
                  'IFSC',
                  _ifscController,
                  Icons.tag_outlined,
                  type: TextInputType.text,
                ),
                _field(
                  'Acc no',
                  _accountNoController,
                  Icons.account_balance_wallet_outlined,
                  type: TextInputType.number,
                ),
                _field(
                  'Upi no.',
                  _upiNoController,
                  Icons.qr_code_2_outlined,
                  type: TextInputType.text,
                ),
                const SizedBox(height: 6),
                _primaryBtn(
                  label: _isSavingSkills ? 'Saving...' : 'Save Banking',
                  icon: Icons.check_rounded,
                  color: _PC.teal,
                  onPressed: _isSavingSkills
                      ? null
                      : () async {
                          try {
                            await _saveBanking();
                            if (ctx.mounted) Navigator.pop(ctx);
                          } catch (e) {
                            if (!mounted) return;
                            _snack(e.toString());
                          }
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    if (_isLoadingProblemData) {
      return const SkeletonCardList(itemCount: 3, padding: EdgeInsets.zero);
    }

    if (_problemDataError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _PC.roseSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _PC.roseBorder),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: _PC.rose,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _problemDataError!,
                    style: const TextStyle(fontSize: 12, color: _PC.rose),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _primaryBtn(
            label: 'Retry',
            icon: Icons.refresh_rounded,
            color: _PC.indigo,
            onPressed: _loadProblemMasterData,
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // summary
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _PC.indigoSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _PC.indigoBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _PC.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _PC.indigoBorder),
                ),
                child: const Icon(
                  Icons.handyman_outlined,
                  color: _PC.indigo,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _catName.isEmpty ? 'Choose service expertise' : _catName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _PC.indigo,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subName.isEmpty ? 'Select sub category' : _subName,
                      style: TextStyle(
                        fontSize: 11,
                        color: _PC.indigo.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _dropdown<String>(
          label: 'Service Category',
          icon: Icons.design_services_outlined,
          value: _selectedCategoryId,
          items: _categories
              .map(
                (i) => DropdownMenuItem(
                  value: i['id']?.toString(),
                  child: Text(i['categoryName']?.toString() ?? ''),
                ),
              )
              .toList(),
          onChanged: (v) async {
            setState(() {
              _selectedCategoryId = v;
              _storedCategoryId = v;
              _selectedSubCategoryId = _filteredSubs.isNotEmpty
                  ? _filteredSubs.first['id']?.toString()
                  : null;
              _storedSubCategoryId = _selectedSubCategoryId;
              final cn = _catName;
              if (cn.isNotEmpty) _expertiseController.text = cn;
            });
            _refreshOpen();
          },
        ),
        const SizedBox(height: 12),
        _dropdown<String>(
          key: ValueKey(_selectedCategoryId),
          label: 'Sub Category',
          icon: Icons.category_outlined,
          value: _selectedSubCategoryId,
          items: _filteredSubs
              .map(
                (i) => DropdownMenuItem(
                  value: i['id']?.toString(),
                  child: Text(i['subCategoryName']?.toString() ?? ''),
                ),
              )
              .toList(),
          onChanged: (v) async {
            setState(() {
              _selectedSubCategoryId = v;
              _storedSubCategoryId = v;
            });
            _refreshOpen();
          },
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _PC.indigoSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _PC.indigoBorder),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: _PC.indigo, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Category and sub category are saved as technician skills. Matching enquiries are fetched from these selected services.',
                  style: TextStyle(
                    color: AppColors.text,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _primaryBtn(
          label: _isSavingSkills ? 'Saving...' : 'Save Service Skills',
          icon: Icons.verified_outlined,
          color: _PC.teal,
          onPressed: _isSavingSkills ? null : _submitSkills,
        ),
        const SizedBox(height: 18),
        _buildSavedSkillsList(),
      ],
    );
  }

  Widget _buildSavedSkillsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Saved service skills',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (_isLoadingSavedSkills)
              const SkeletonBox(width: 18, height: 18, radius: 6)
            else
              IconButton(
                onPressed: _loadSavedSkills,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                color: _PC.indigo,
                tooltip: 'Refresh skills',
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_savedSkills.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _PC.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _PC.border),
            ),
            child: const Text(
              'No saved service skills yet. Add category and sub category above.',
              style: TextStyle(color: AppColors.muted, height: 1.35),
            ),
          )
        else
          ..._savedSkills.map(_savedSkillTile),
      ],
    );
  }

  Widget _savedSkillTile(TechnicianSkillModel skill) {
    final deleting = _deletingSkillIds.contains(skill.id);
    final category = skill.categoryName.isNotEmpty
        ? skill.categoryName
        : _rowName(_categories, skill.categoryId, const [
            'categoryName',
            'name',
          ]);
    final subCategory = skill.subCategoryName.isNotEmpty
        ? skill.subCategoryName
        : _rowName(_subCategories, skill.subCategoryId, const [
            'subCategoryName',
            'name',
          ]);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _PC.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _PC.indigoBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: _PC.indigoSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.handyman_outlined, color: _PC.indigo),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.isEmpty ? 'Category ${skill.categoryId}' : category,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subCategory.isEmpty
                      ? 'Sub category ${skill.subCategoryId}'
                      : subCategory,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (deleting)
            const SkeletonBox(width: 22, height: 22, radius: 7)
          else
            IconButton(
              onPressed: () => _deleteSkill(skill),
              tooltip: 'Delete skill',
              icon: const Icon(Icons.delete_outline_rounded),
              color: _PC.rose,
              style: IconButton.styleFrom(
                backgroundColor: _PC.roseSoft,
                side: const BorderSide(color: _PC.roseBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDocsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _dropdown<String>(
          label: 'Qualification',
          icon: Icons.school_outlined,
          value: _qualificationOptions.contains(_selectedQualification)
              ? _selectedQualification
              : null,
          items: _qualificationOptions
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: (v) {
            if (v != null) _saveQualification(v);
          },
        ),
        const SizedBox(height: 14),
        _docTile('Aadhaar Card', 'aadhar', Icons.badge_outlined),
        const SizedBox(height: 10),
        _docTile('PAN Card', 'pan', Icons.credit_card_outlined),
        const SizedBox(height: 10),
        _docTile('Driving License', 'driving', Icons.drive_eta_outlined),
        const SizedBox(height: 18),
        _additionalDocsSection(),
      ],
    );
  }

  Widget _additionalDocsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _PC.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _PC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _PC.indigoSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _PC.indigoBorder),
                ),
                child: const Icon(
                  Icons.folder_copy_outlined,
                  color: _PC.indigo,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Additional Documents',
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Certificates, marksheets and experience proof',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _isSavingAdditionalDoc
                    ? null
                    : () => _openAdditionalDocSheet(),
                icon: const Icon(Icons.add_rounded),
                color: _PC.indigo,
                style: IconButton.styleFrom(
                  backgroundColor: _PC.indigoSoft,
                  side: const BorderSide(color: _PC.indigoBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingAdditionalDocs)
            const SkeletonBox(width: double.infinity, height: 74, radius: 14)
          else if (_additionalDocs.isEmpty)
            InkWell(
              onTap: _isSavingAdditionalDoc
                  ? null
                  : () => _openAdditionalDocSheet(),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _PC.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _PC.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, color: _PC.indigo),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Add your first extra document',
                        style: TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._additionalDocs.map(_additionalDocTile),
        ],
      ),
    );
  }

  Widget _additionalDocTile(Map<String, dynamic> doc) {
    final name = _rv(doc, const ['documentName']).isEmpty
        ? 'Additional Document'
        : _rv(doc, const ['documentName']);
    final image = _resolveImg(_rv(doc, const ['documentImage']));
    final hasImage = _hasImg(image);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _PC.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _PC.border),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: hasImage ? _PC.tealSoft : _PC.indigoSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasImage ? _PC.tealBorder : _PC.indigoBorder,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasImage
                  ? _imgPreview(image!)
                  : const Icon(Icons.description_outlined, color: _PC.indigo),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasImage ? 'Tap to view' : 'Image missing',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (hasImage)
              _docActionButton(
                icon: Icons.visibility_outlined,
                color: _PC.teal,
                bg: _PC.tealSoft,
                border: _PC.tealBorder,
                onTap: () => _previewDoc(name, image!),
              ),
            const SizedBox(width: 8),
            _docActionButton(
              icon: Icons.edit_outlined,
              color: _PC.indigo,
              bg: _PC.indigoSoft,
              border: _PC.indigoBorder,
              onTap: () => _openAdditionalDocSheet(doc: doc),
            ),
          ],
        ),
      ),
    );
  }

  Widget _docTile(String label, String field, IconData icon) {
    final uploading = _uploadingDocs.contains(field);
    final src = _docImagePaths[field];
    final has = _hasImg(src);

    return Container(
      decoration: BoxDecoration(
        color: _PC.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _PC.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: uploading
              ? null
              : has
              ? () => _previewDoc(label, src!)
              : () => _uploadDocument(field),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: has ? _PC.tealSoft : _PC.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: has ? _PC.tealBorder : _PC.border,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: has
                      ? _imgPreview(src!)
                      : Icon(icon, color: AppColors.muted, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        has ? 'Tap to view' : 'Tap camera to upload',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (uploading)
                  const SkeletonBox(width: 22, height: 22, radius: 7)
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _docActionButton(
                        icon: Icons.camera_alt_rounded,
                        color: _PC.teal,
                        bg: _PC.tealSoft,
                        border: _PC.tealBorder,
                        onTap: () =>
                            _uploadDocument(field, source: ImageSource.camera),
                      ),
                      const SizedBox(width: 8),
                      _docActionButton(
                        icon: Icons.edit_outlined,
                        color: _PC.indigo,
                        bg: _PC.indigoSoft,
                        border: _PC.indigoBorder,
                        onTap: () =>
                            _uploadDocument(field, source: ImageSource.gallery),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _docActionButton({
    required IconData icon,
    required Color color,
    required Color bg,
    required Color border,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Icon(icon, size: 17, color: color),
      ),
    );
  }

  Future<void> _previewDoc(String label, String path) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _PC.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.86,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              children: [
                _sheetHandle(),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: _PC.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _PC.border),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      color: _PC.surface,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return InteractiveViewer(
                            minScale: 0.8,
                            maxScale: 4,
                            child: SizedBox(
                              width: constraints.maxWidth,
                              height: constraints.maxHeight,
                              child: _imgPreview(path, fit: BoxFit.contain),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openSection(String title, Widget Function() builder) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => StatefulBuilder(
          builder: (ctx, refresh) {
            _openSectionRefresh = () => refresh(() {});
            return Scaffold(
              backgroundColor: _PC.bg,
              body: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          _iconBtn(
                            Icons.arrow_back_ios_new_rounded,
                            () => Navigator.pop(ctx),
                          ),
                          const Spacer(),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                        child: builder(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
    _openSectionRefresh = null;
  }

  Widget _sheetHandle() => Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: _PC.dim,
        borderRadius: BorderRadius.circular(99),
      ),
    ),
  );

  Widget _sheetHeader(
    IconData icon,
    Color bg,
    Color bc,
    Color fg,
    String title,
    String sub,
  ) => Row(
    children: [
      Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: bc),
        ),
        child: Icon(icon, color: fg, size: 22),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _field(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    TextInputType? type,
    int lines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          suffixIcon: const Icon(
            Icons.edit_outlined,
            size: 17,
            color: AppColors.muted,
          ),
          filled: true,
          fillColor: _PC.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _PC.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _PC.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _PC.teal, width: 1.5),
          ),
        ),
      ),
    );
  }

  //
  Widget _dropdown<T>({
    Key? key,
    required String label,
    String? hint,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) => DropdownButtonFormField<T>(
    key: key,
    initialValue: value,
    hint: hint == null ? null : Text(hint),
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: _PC.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _PC.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _PC.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _PC.teal, width: 1.5),
      ),
    ),
    items: items,
    onChanged: onChanged,
  );
  Widget _primaryBtn({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
  }) {
    final off = onPressed == null;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: off ? _PC.surface : color,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: off ? AppColors.muted : Colors.white, size: 18),
              const SizedBox(width: 9),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: off ? AppColors.muted : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
