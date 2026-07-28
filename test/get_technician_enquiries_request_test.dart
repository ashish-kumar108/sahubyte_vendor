import 'package:flutter_test/flutter_test.dart';
import 'package:sahubyte_vendor/model/request/get_technician_enquiries_request.dart';

void main() {
  test('new enquiry request does not apply state filtering', () {
    const request = GetTechnicianEnquiriesRequest(
      technicianId: '10',
      page: 1,
      limit: 10,
    );

    expect(request.toFormData(), {
      'technicianId': '10',
      'page': '1',
      'limit': '10',
    });
    expect(request.toFormData().containsKey('state'), isFalse);
  });
}
