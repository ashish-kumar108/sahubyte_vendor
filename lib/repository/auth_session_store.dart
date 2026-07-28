import 'package:shared_preferences/shared_preferences.dart';

class AuthSessionStore {
  static const _isLoggedInKey = 'is_logged_in';
  static const _mobileKey = 'logged_in_mobile';

  Future<void> setLoggedIn(bool value, {String? mobile}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, value);
    if (value && mobile != null && mobile.trim().isNotEmpty) {
      await prefs.setString(_mobileKey, mobile.trim());
    }
  }

  Future<void> setPendingApproval({required String mobile}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
    if (mobile.trim().isNotEmpty) {
      await prefs.setString(_mobileKey, mobile.trim());
    }
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  Future<String?> getLoggedInMobile() async {
    final prefs = await SharedPreferences.getInstance();
    final mobile = prefs.getString(_mobileKey);
    if (mobile == null || mobile.trim().isEmpty) return null;
    return mobile.trim();
  }

  Future<bool> hasPendingApproval() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    final mobile = prefs.getString(_mobileKey);
    return !loggedIn && mobile != null && mobile.trim().isNotEmpty;
  }

  Future<void> setLoggedInMobile(String mobile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mobileKey, mobile.trim());
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.remove(_mobileKey);
  }
}
