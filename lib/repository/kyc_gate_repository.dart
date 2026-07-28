import 'package:sahubyte_vendor/model/request/get_data_request.dart';
import 'package:sahubyte_vendor/repository/user_repository.dart';

class TechnicianKycStatus {
  const TechnicianKycStatus({
    required this.found,
    required this.approved,
    required this.row,
  });

  final bool found;
  final bool approved;
  final Map<String, dynamic> row;

  String get technicianId =>
      _value(const ['id', 'technicianId', 'userId']).trim();
  String get name =>
      _value(const ['name', 'fullName', 'technicianName']).trim();
  String get email => _value(const ['email', 'emailId', 'emailID']).trim();
  String get mobile => _value(const [
    'mobile',
    'phone',
    'mobileNumber',
    'contact',
    'contactNumber',
  ]).trim();

  String _value(List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    final lower = keys.map((key) => key.toLowerCase()).toSet();
    for (final entry in row.entries) {
      if (lower.contains(entry.key.toLowerCase()) &&
          entry.value != null &&
          entry.value.toString().trim().isNotEmpty) {
        return entry.value.toString();
      }
    }
    return '';
  }
}

class KycGateRepository {
  KycGateRepository({UserRepository? repository})
    : _repository = repository ?? UserRepository();

  final UserRepository _repository;

  Future<TechnicianKycStatus> getStatusForMobile(String mobile) async {
    final digits = _digits(mobile);
    if (digits.isEmpty) {
      return const TechnicianKycStatus(found: false, approved: false, row: {});
    }

    final response = await _repository.getData(
      const GetDataRequest(tableName: 'technician'),
    );
    for (final row in response.rows) {
      final rowMobile = _digits(
        _value(row, const [
          'mobile',
          'phone',
          'mobileNumber',
          'contact',
          'contactNumber',
        ]),
      );
      if (rowMobile != digits) continue;
      return TechnicianKycStatus(
        found: true,
        approved: _isApproved(_value(row, const ['kyc', 'KYC'])),
        row: row,
      );
    }

    return const TechnicianKycStatus(found: false, approved: false, row: {});
  }

  static bool _isApproved(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized == '1' ||
        normalized == 'true' ||
        normalized == 'approved' ||
        normalized == 'yes';
  }

  static String _value(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    final lower = keys.map((key) => key.toLowerCase()).toSet();
    for (final entry in row.entries) {
      if (lower.contains(entry.key.toLowerCase()) &&
          entry.value != null &&
          entry.value.toString().trim().isNotEmpty) {
        return entry.value.toString();
      }
    }
    return '';
  }

  static String _digits(String value) => value.replaceAll(RegExp(r'\D'), '');
}
