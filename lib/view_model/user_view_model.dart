import 'package:flutter/foundation.dart';
import 'package:sahubyte_vendor/model/request/get_data_request.dart';
import 'package:sahubyte_vendor/model/response/get_data_response.dart';
import 'package:sahubyte_vendor/repository/user_repository.dart';

class UserViewModel extends ChangeNotifier {
  UserViewModel({UserRepository? repository})
    : _repository = repository ?? UserRepository();

  final UserRepository _repository;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<GetDataResponse> getData({
    required String tableName,
    Map<String, dynamic> params = const {},
  }) {
    return _run(
      () => _repository.getData(
        GetDataRequest(tableName: tableName, params: params),
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
