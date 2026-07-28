import 'package:flutter_test/flutter_test.dart';
import 'package:sahubyte_vendor/model/request/reset_password_request.dart';

void main() {
  test('legacy vendor password setup edits technician record', () {
    const request = ResetPasswordRequest(
      technicianId: '10',
      password: 'Secure@123',
    );

    expect(request.toFormData(), {
      'tableName': 'technician',
      'act': 'edit',
      'id': '10',
      'password': 'Secure@123',
    });
  });
}
