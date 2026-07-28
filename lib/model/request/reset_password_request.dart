class ResetPasswordRequest {
  const ResetPasswordRequest({
    required this.technicianId,
    required this.password,
  });

  final String technicianId;
  final String password;

  Map<String, String> toFormData() {
    return {
      'tableName': 'technician',
      'act': 'edit',
      'id': technicianId,
      'password': password,
    };
  }
}
