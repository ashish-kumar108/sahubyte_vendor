import 'package:flutter/foundation.dart';
import 'package:sahubyte_vendor/model/request/login_request.dart';
import 'package:sahubyte_vendor/model/request/reset_password_request.dart';
import 'package:sahubyte_vendor/model/request/send_otp_login_request.dart';
import 'package:sahubyte_vendor/model/request/signup_otp_request.dart';
import 'package:sahubyte_vendor/model/request/signup_request.dart';
import 'package:sahubyte_vendor/model/response/auth_response.dart';
import 'package:sahubyte_vendor/repository/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({AuthRepository? repository})
    : _repository = repository ?? AuthRepository();

  final AuthRepository _repository;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<AuthResponse> login({
    required String mobile,
    required String password,
  }) {
    return _run(
      () => _repository.login(LoginRequest(mobile: mobile, password: password)),
    );
  }

  Future<AuthResponse> sendOtpLogin(String mobile) {
    return _run(
      () => _repository.sendOtpLogin(SendOtpLoginRequest(mobile: mobile)),
    );
  }

  Future<AuthResponse> signupOtp(String mobile) {
    return _run(() => _repository.signupOtp(SignupOtpRequest(mobile: mobile)));
  }

  Future<AuthResponse> signup({
    required String mobile,
    required String email,
    required String name,
    required String dob,
    required String state,
    required String pincode,
    required String password,
  }) {
    return _run(
      () => _repository.signup(
        SignupRequest(
          mobile: mobile,
          email: email,
          name: name,
          dob: dob,
          state: state,
          pincode: pincode,
          password: password,
        ),
      ),
    );
  }

  Future<AuthResponse> resetPassword({
    required String technicianId,
    required String password,
  }) {
    return _run(
      () => _repository.resetPassword(
        ResetPasswordRequest(technicianId: technicianId, password: password),
      ),
    );
  }

  Future<T> _run<T>(Future<T> Function() request) async {
    _setLoading(true);
    try {
      return await request();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
