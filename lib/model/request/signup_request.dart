class SignupRequest {
  const SignupRequest({
    required this.mobile,
    required this.email,
    required this.name,
    required this.dob,
    required this.state,
    required this.pincode,
    required this.password,
  });

  final String mobile;
  final String email;
  final String name;
  final String dob;
  final String state;
  final String pincode;
  final String password;

  Map<String, String> toFormData() {
    return {
      'mobile': mobile,
      'email': email,
      'name': name,
      'dob': dob,
      'state': state,
      'pincode': pincode,
      'password': password,
    };
  }
}
