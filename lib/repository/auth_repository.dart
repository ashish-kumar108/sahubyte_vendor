import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sahubyte_vendor/data/network/base_api_service.dart';
import 'package:sahubyte_vendor/data/network/network_api_service.dart';
import 'package:sahubyte_vendor/model/request/login_request.dart';
import 'package:sahubyte_vendor/model/request/reset_password_request.dart';
import 'package:sahubyte_vendor/model/request/send_otp_login_request.dart';
import 'package:sahubyte_vendor/model/request/signup_otp_request.dart';
import 'package:sahubyte_vendor/model/request/signup_request.dart';
import 'package:sahubyte_vendor/model/response/auth_response.dart';
import 'package:sahubyte_vendor/res/api_constants.dart';

class AuthRepository {
  AuthRepository({BaseApiService? apiService})
    : _apiService = apiService ?? NetworkApiService();

  final BaseApiService _apiService;

  Future<AuthResponse> login(LoginRequest request) async {
    final multipart = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConstants.login),
    )..fields.addAll(request.toFormData());
    final streamed = await multipart.send().timeout(
      const Duration(seconds: 60),
    );
    final rawBody = await streamed.stream.bytesToString();
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception('Login service unavailable. Please try again.');
    }
    final decoded = jsonDecode(rawBody);
    if (decoded is! Map) {
      throw Exception('Invalid login response. Please try again.');
    }
    final response = Map<String, dynamic>.from(decoded);
    return AuthResponse.fromJson(Map<String, dynamic>.from(response));
  }

  Future<AuthResponse> sendOtpLogin(SendOtpLoginRequest request) async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.sendOtpLogin,
      request.toFormData(),
    );
    return AuthResponse.fromJson(Map<String, dynamic>.from(response));
  }

  Future<AuthResponse> signupOtp(SignupOtpRequest request) async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.signupOtp,
      request.toFormData(),
    );
    return AuthResponse.fromJson(Map<String, dynamic>.from(response));
  }

  Future<AuthResponse> signup(SignupRequest request) async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.signup,
      request.toFormData(),
    );
    return AuthResponse.fromJson(Map<String, dynamic>.from(response));
  }

  Future<AuthResponse> resetPassword(ResetPasswordRequest request) async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.createFunction,
      request.toFormData(),
    );
    return AuthResponse.fromJson(Map<String, dynamic>.from(response));
  }
}
