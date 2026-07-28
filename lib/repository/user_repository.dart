import 'package:sahubyte_vendor/data/network/base_api_service.dart';
import 'package:sahubyte_vendor/data/network/network_api_service.dart';
import 'package:sahubyte_vendor/model/request/get_data_request.dart';
import 'package:sahubyte_vendor/model/response/get_data_response.dart';
import 'package:sahubyte_vendor/res/api_constants.dart';

class UserRepository {
  UserRepository({BaseApiService? apiService})
    : _apiService = apiService ?? NetworkApiService();

  final BaseApiService _apiService;

  Future<GetDataResponse> getData(GetDataRequest request) async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.getData,
      request.toFormData(),
    );
    return GetDataResponse.fromJson(Map<String, dynamic>.from(response));
  }
}
