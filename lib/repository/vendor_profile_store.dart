import 'package:sahubyte_vendor/model/vendor_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VendorProfileStore {
  static const _ownerMobileKey = 'vendor_profile_owner_mobile';
  static const _technicianIdKey = 'vendor_technician_id';
  static const _nameKey = 'vendor_name';
  static const _emailKey = 'vendor_email';
  static const _mobileKey = 'vendor_mobile';
  static const _dobKey = 'vendor_dob';
  static const _expertiseKey = 'vendor_expertise';
  static const _addressKey = 'vendor_address';
  static const _stateKey = 'vendor_state';
  static const _pincodeKey = 'vendor_pincode';
  static const _accountNameKey = 'vendor_account_name';
  static const _ifscKey = 'vendor_ifsc';
  static const _accountNoKey = 'vendor_account_no';
  static const _upiNoKey = 'vendor_upi_no';
  static const _categoryIdKey = 'vendor_category_id';
  static const _subCategoryIdKey = 'vendor_sub_category_id';
  static const _profileImagePathKey = 'vendor_profile_image_path';
  static const _docPathPrefix = 'vendor_doc_path_';

  String _digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

  Future<void> ensureOwner(String mobile) async {
    final nextOwner = _digitsOnly(mobile);
    if (nextOwner.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final currentOwner = _digitsOnly(prefs.getString(_ownerMobileKey) ?? '');
    if (currentOwner == nextOwner) return;

    await Future.wait([
      prefs.remove(_nameKey),
      prefs.remove(_technicianIdKey),
      prefs.remove(_emailKey),
      prefs.remove(_mobileKey),
      prefs.remove(_dobKey),
      prefs.remove(_expertiseKey),
      prefs.remove(_addressKey),
      prefs.remove(_stateKey),
      prefs.remove(_pincodeKey),
      prefs.remove(_accountNameKey),
      prefs.remove(_ifscKey),
      prefs.remove(_accountNoKey),
      prefs.remove(_upiNoKey),
      prefs.remove(_categoryIdKey),
      prefs.remove(_subCategoryIdKey),
      prefs.remove(_profileImagePathKey),
      for (final field in ['aadhar', 'pan', 'driving', 'qualification'])
        prefs.remove('$_docPathPrefix$field'),
    ]);
    await prefs.setString(_ownerMobileKey, nextOwner);
    await prefs.setString(_mobileKey, mobile.trim());
  }

  Future<void> saveProfile(VendorProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final existingTechnicianId = prefs.getString(_technicianIdKey) ?? '';
    final technicianId = profile.technicianId.trim().isNotEmpty
        ? profile.technicianId.trim()
        : existingTechnicianId;
    await Future.wait([
      prefs.setString(_ownerMobileKey, _digitsOnly(profile.mobile)),
      prefs.setString(_technicianIdKey, technicianId),
      prefs.setString(_nameKey, profile.name),
      prefs.setString(_emailKey, profile.email),
      prefs.setString(_mobileKey, profile.mobile),
      prefs.setString(_dobKey, profile.dob),
      prefs.setString(_expertiseKey, profile.expertise),
      prefs.setString(_addressKey, profile.address),
      prefs.setString(_stateKey, profile.state),
      prefs.setString(_pincodeKey, profile.pincode),
      prefs.setString(_accountNameKey, profile.accountName),
      prefs.setString(_ifscKey, profile.ifsc),
      prefs.setString(_accountNoKey, profile.accountNo),
      prefs.setString(_upiNoKey, profile.upiNo),
      prefs.setString(_categoryIdKey, profile.categoryId ?? ''),
      prefs.setString(_subCategoryIdKey, profile.subCategoryId ?? ''),
    ]);
  }

  Future<VendorProfile> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return VendorProfile(
      technicianId: prefs.getString(_technicianIdKey) ?? '',
      name: prefs.getString(_nameKey) ?? 'Vendor Partner',
      email: prefs.getString(_emailKey) ?? '',
      mobile: prefs.getString(_mobileKey) ?? '',
      dob: prefs.getString(_dobKey) ?? '',
      expertise: prefs.getString(_expertiseKey) ?? '',
      address: prefs.getString(_addressKey) ?? '',
      state: prefs.getString(_stateKey) ?? '',
      pincode: prefs.getString(_pincodeKey) ?? '',
      accountName: prefs.getString(_accountNameKey) ?? '',
      ifsc: prefs.getString(_ifscKey) ?? '',
      accountNo: prefs.getString(_accountNoKey) ?? '',
      upiNo: prefs.getString(_upiNoKey) ?? '',
      categoryId: _emptyToNull(prefs.getString(_categoryIdKey)),
      subCategoryId: _emptyToNull(prefs.getString(_subCategoryIdKey)),
    );
  }

  String? _emptyToNull(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }

  Future<void> saveProfileImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileImagePathKey, path);
  }

  Future<String?> getProfileImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    return _emptyToNull(prefs.getString(_profileImagePathKey));
  }

  Future<void> saveDocumentPath(String field, String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_docPathPrefix$field', path);
  }

  Future<Map<String, String>> getDocumentPaths() async {
    final prefs = await SharedPreferences.getInstance();
    final paths = <String, String>{};
    for (final field in ['aadhar', 'pan', 'driving', 'qualification']) {
      final path = _emptyToNull(prefs.getString('$_docPathPrefix$field'));
      if (path != null) paths[field] = path;
    }
    return paths;
  }
}
