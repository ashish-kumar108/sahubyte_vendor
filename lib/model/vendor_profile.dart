class VendorProfile {
  const VendorProfile({
    this.technicianId = '',
    required this.name,
    required this.email,
    required this.mobile,
    required this.dob,
    required this.expertise,
    required this.address,
    required this.state,
    this.pincode = '',
    this.accountName = '',
    this.ifsc = '',
    this.accountNo = '',
    this.upiNo = '',
    this.categoryId,
    this.subCategoryId,
  });

  final String technicianId;
  final String name;
  final String email;
  final String mobile;
  final String dob;
  final String expertise;
  final String address;
  final String state;
  final String pincode;
  final String accountName;
  final String ifsc;
  final String accountNo;
  final String upiNo;
  final String? categoryId;
  final String? subCategoryId;

  VendorProfile copyWith({
    String? technicianId,
    String? name,
    String? email,
    String? mobile,
    String? dob,
    String? expertise,
    String? address,
    String? state,
    String? pincode,
    String? accountName,
    String? ifsc,
    String? accountNo,
    String? upiNo,
    String? categoryId,
    String? subCategoryId,
  }) {
    return VendorProfile(
      technicianId: technicianId ?? this.technicianId,
      name: name ?? this.name,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      dob: dob ?? this.dob,
      expertise: expertise ?? this.expertise,
      address: address ?? this.address,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      accountName: accountName ?? this.accountName,
      ifsc: ifsc ?? this.ifsc,
      accountNo: accountNo ?? this.accountNo,
      upiNo: upiNo ?? this.upiNo,
      categoryId: categoryId ?? this.categoryId,
      subCategoryId: subCategoryId ?? this.subCategoryId,
    );
  }
}
