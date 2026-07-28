import 'dart:convert';

import 'package:sahubyte_vendor/data/network/base_api_service.dart';
import 'package:sahubyte_vendor/data/network/network_api_service.dart';
import 'package:sahubyte_vendor/model/request/add_technician_skills_request.dart';
import 'package:sahubyte_vendor/model/request/get_assigned_enquiries_request.dart';
import 'package:sahubyte_vendor/model/request/get_technician_enquiries_request.dart';
import 'package:sahubyte_vendor/model/request/get_technician_skills_request.dart';
import 'package:sahubyte_vendor/model/request/get_problems_request.dart';
import 'package:sahubyte_vendor/model/request/update_profile_image_request.dart';
import 'package:sahubyte_vendor/model/request/update_enquiry_inspection_request.dart';
import 'package:sahubyte_vendor/model/request/update_enquiry_reallocation_request.dart';
import 'package:sahubyte_vendor/model/request/update_technician_docs_request.dart';
import 'package:sahubyte_vendor/model/response/problem_response.dart';
import 'package:sahubyte_vendor/model/response/technician_enquiry_model.dart';
import 'package:sahubyte_vendor/model/response/technician_skill_model.dart';
import 'package:sahubyte_vendor/model/response/technician_skill_response.dart';
import 'package:sahubyte_vendor/model/response/upload_response.dart';
import 'package:sahubyte_vendor/res/api_constants.dart';

class TechnicianRepository {
  TechnicianRepository({BaseApiService? apiService})
    : _apiService = apiService ?? NetworkApiService();

  final BaseApiService _apiService;

  Future<ProblemResponse> getProblems(GetProblemsRequest request) async {
    final response = await _apiService.getPostApiRequest(
      ApiConstants.getProblems,
      request.toJson(),
    );
    return ProblemResponse.fromJson(Map<String, dynamic>.from(response));
  }

  Future<TechnicianSkillResponse> addTechnicianSkills(
    AddTechnicianSkillsRequest request,
  ) async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.createFunction,
      request.toJson(),
    );
    return TechnicianSkillResponse.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  Future<List<TechnicianSkillModel>> getTechnicianSkills(
    GetTechnicianSkillsRequest request,
  ) async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.getTechnicianSkills,
      request.toFormData(),
    );
    return _extractListJson(response)
        .map(TechnicianSkillModel.fromJson)
        .where((skill) => skill.categoryId.isNotEmpty)
        .toList();
  }

  Future<UploadResponse> deleteTechnicianSkill(String id) async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.createFunction,
      {'tableName': 'technicianSkill', 'act': 'delete', 'id': id},
    );
    return _uploadResponse(response, 'Skill deleted successfully.');
  }

  Future<List<TechnicianEnquiryModel>> getTechnicianEnquiries(
    GetTechnicianEnquiriesRequest request,
  ) async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.getTechnicianEnquiries,
      request.toFormData(),
    );
    final fallbackResponse = await _apiService.getPostFormApiRequest(
      ApiConstants.getData,
      {'tableName': 'enquiries'},
    );
    final latestHistoryByEnquiry = await _latestTechnicianHistoryByEnquiry();
    final mergedRows = [
      ..._extractListJson(response),
      ..._extractListJson(fallbackResponse),
    ];
    final seenIds = <String>{};
    final enquiries = mergedRows
        .map(
          (row) => _applyLatestTechnicianHistory(
            row,
            currentTechnicianId: request.technicianId,
            latestHistoryByEnquiry: latestHistoryByEnquiry,
          ),
        )
        .whereType<Map<String, dynamic>>()
        .where(_isAvailableForNewPool)
        .map(TechnicianEnquiryModel.fromJson)
        .where(
          (enquiry) => enquiry.id.isNotEmpty && seenIds.add(enquiry.id.trim()),
        )
        .toList();
    final filtered = await _filterEnquiriesForTechnicianSkills(
      technicianId: request.technicianId,
      enquiries: enquiries,
    );
    return _withCustomerDetails(filtered);
  }

  Future<UploadResponse> assignTechnician({
    required String enquiryId,
    required String technicianId,
  }) async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.assignTechnician,
      {'enquiryId': enquiryId, 'technicianId': technicianId},
    );
    return _uploadResponse(response, 'Booking accepted successfully.');
  }

  Future<UploadResponse> updateTechnicianStatus({
    required String enquiryId,
    required String technicianId,
    required String status,
    String? reallocatedNote,
  }) async {
    final data = <String, String>{
      'enquiryId': enquiryId,
      'technicianId': technicianId,
      'status': status,
    };
    final note = reallocatedNote?.trim();
    if (note != null && note.isNotEmpty) {
      data['reallocatedNote'] = note;
    }
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.updateTechnicianStatus,
      data,
    );
    return _uploadResponse(response, 'Technician status updated.');
  }

  Future<UploadResponse> updateFinalPaymentStatus({
    required String enquiryId,
    required String paymentType,
    required String paymentStatus,
  }) async {
    final response = await _apiService
        .getPostFormApiRequest(ApiConstants.createFunction, {
          'tableName': 'enquiries',
          'act': 'edit',
          'id': enquiryId.trim(),
          'paymentType': paymentType.trim().toLowerCase(),
          'paymentStatus': paymentStatus.trim().toLowerCase(),
        });
    return _uploadResponse(response, 'Payment status updated.');
  }

  Future<UploadResponse> saveInspection(
    UpdateEnquiryInspectionRequest request,
  ) async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.createFunction,
      request.toFormData(),
    );
    return _uploadResponse(response, 'Inspection images saved successfully.');
  }

  Future<UploadResponse> saveReallocationNote(
    UpdateEnquiryReallocationRequest request,
  ) async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.createFunction,
      request.toFormData(),
    );
    return _uploadResponse(response, 'Reallocation note saved successfully.');
  }

  Future<List<TechnicianEnquiryModel>> getAssignedEnquiries(
    GetAssignedEnquiriesRequest request,
  ) async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.getAssignedEnquiries,
      request.toFormData(),
    );
    final enquiries = _extractListJson(response)
        .map(TechnicianEnquiryModel.fromJson)
        .where((enquiry) => enquiry.id.isNotEmpty)
        .where((enquiry) => enquiry.statusLabel != 'Reallocated')
        .toList();
    return _withCustomerDetails(enquiries);
  }

  Future<double?> getTechnicianRating({required String technicianId}) async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.getTechnicianRating,
      {'technicianId': technicianId.trim()},
    );
    if (response is! Map) return null;
    final json = Map<String, dynamic>.from(response);
    final data = json['data'];
    if (data is Map) {
      return double.tryParse(
        _firstUserValue(Map<String, dynamic>.from(data), const [
          'averageRating',
          'avgRating',
          'rating',
        ]),
      );
    }
    return double.tryParse(
      _firstUserValue(json, const ['averageRating', 'avgRating', 'rating']),
    );
  }

  Future<UploadResponse> createJobCard({
    required String enquiryId,
    required String details,
    required List<Map<String, dynamic>> parts,
    bool resetApproval = false,
    int? enquiryTotalPrice,
    String problemChangeDetails = '',
  }) async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.createJobCard,
      {
        'enquiryId': enquiryId.trim(),
        'details': details,
        'parts': jsonEncode(parts),
      },
    );
    final uploadResponse = _uploadResponse(
      response,
      'Job card created successfully.',
    );
    if (resetApproval && uploadResponse.isSuccess) {
      await _apiService.getPostFormApiRequest(ApiConstants.createFunction, {
        'tableName': 'enquiries',
        'act': 'edit',
        'id': enquiryId.trim(),
        'workConfirmation': '0',
        'workConfirmationDate': '',
        'partTotalPrice': '0',
        'problemChangeDetails': problemChangeDetails,
        if (enquiryTotalPrice != null)
          'totalPrice': enquiryTotalPrice.toString(),
      });
    }
    return uploadResponse;
  }

  Future<UploadResponse> updateEnquiryProblem({
    required String enquiryId,
    required String problemTableId,
    required String newProblemId,
    required String enquiryCategoryId,
    required String enquirySubCategoryId,
  }) async {
    final response = await _apiService
        .getPostFormApiRequest(ApiConstants.updateEnquiryProblem, {
          'enquiryId': enquiryId.trim(),
          'probelmTableId': problemTableId.trim(),
          'newProblemId': newProblemId.trim(),
          'enquiryCateogyrId': enquiryCategoryId.trim(),
          'enquirySubCateogyrId': enquirySubCategoryId.trim(),
        });
    return _uploadResponse(response, 'Problem updated successfully.');
  }

  Future<Map<String, dynamic>?> getJobCard({required String enquiryId}) async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.getJobCard,
      {'enquiryId': enquiryId},
    );
    final rows = _extractListJson(response);
    if (rows.isNotEmpty) return rows.first;
    if (response is Map) {
      final json = Map<String, dynamic>.from(response);
      final data = json['data'] ?? json['jobCard'] ?? json['result'];
      if (data is Map) return Map<String, dynamic>.from(data);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getPartsForService({
    required String categoryId,
    required String subCategoryId,
  }) async {
    var rows = <Map<String, dynamic>>[];
    for (final tableName in const ['parts', 'part']) {
      final response = await _apiService.getPostFormApiRequest(
        ApiConstants.getData,
        {'tableName': tableName},
      );
      rows = _extractListJson(response);
      if (rows.isNotEmpty) break;
    }

    return rows.where((row) {
      final rowCategoryId = _firstUserValue(row, const [
        'categoryId',
        'category_id',
      ]);
      final rowSubCategoryId = _firstUserValue(row, const [
        'subCategoryId',
        'subcategoryId',
        'sub_category_id',
      ]);
      final matchesCategory =
          rowCategoryId.isEmpty || rowCategoryId == categoryId;
      final matchesSubCategory =
          rowSubCategoryId.isEmpty || rowSubCategoryId == subCategoryId;
      return matchesCategory && matchesSubCategory;
    }).toList();
  }

  Future<UploadResponse> updateProfileImage(
    UpdateProfileImageRequest request,
  ) async {
    final response = await _apiService
        .getPostFormApiRequest(ApiConstants.createFunction, {
          'tableName': 'technician',
          'act': 'edit',
          'id': request.technicianId,
          'profileImage': request.imageBase64,
          'folderName': request.folderName,
          'kyc': '0',
        });
    return _uploadResponse(
      response,
      'Profile image updated. Admin approval is required again.',
    );
  }

  Future<UploadResponse> updateTechnicianProfile({
    required String technicianId,
    required String name,
    required String email,
    required String mobile,
    required String dob,
    required String address,
    required String state,
    required String pincode,
  }) async {
    final response = await _apiService
        .getPostFormApiRequest(ApiConstants.createFunction, {
          'tableName': 'technician',
          'act': 'edit',
          'id': technicianId,
          'name': name,
          'email': email,
          'mobile': mobile,
          'dob': dob,
          'address': address,
          'state': state,
          'pincode': pincode,
          'kyc': '0',
        });
    return _uploadResponse(
      response,
      'Profile updated. Admin approval is required again.',
    );
  }

  Future<UploadResponse> updateTechnicianBanking({
    required String technicianId,
    required String accountName,
    required String ifsc,
    required String accountNo,
    required String upiNo,
  }) async {
    final response = await _apiService
        .getPostFormApiRequest(ApiConstants.createFunction, {
          'tableName': 'technician',
          'act': 'edit',
          'id': technicianId,
          'accountName': accountName,
          'ifscCode': ifsc,
          'accountNo': accountNo,
          'upiNo': upiNo,
          'kyc': '0',
        });
    return _uploadResponse(
      response,
      'Banking details updated. Admin approval is required again.',
    );
  }

  Future<UploadResponse> updateTechnicianDocs(
    UpdateTechnicianDocsRequest request,
  ) async {
    final existingDocId = await _getExistingTechnicianDocsId(
      request.technicianId,
    );
    final isUpdate = existingDocId != null;
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.createFunction,
      {
        'tableName': 'technicianDocs',
        'act': isUpdate ? 'edit' : 'add',
        if (isUpdate) 'id': existingDocId,
        'technicianId': request.technicianId,
        'folderName': request.folderName,
        if (request.aadharImage != null) 'aadharImage': request.aadharImage!,
        if (request.panImage != null) 'panImage': request.panImage!,
        if (request.drivingImage != null) 'drivingImage': request.drivingImage!,
        if (request.qualification != null)
          'qualification': request.qualification!,
      },
    );
    final uploadResponse = _uploadResponse(
      response,
      'Document uploaded. Admin approval is required again.',
    );
    if (uploadResponse.isSuccess) {
      await _markTechnicianPendingReview(request.technicianId);
    }
    return uploadResponse;
  }

  Future<UploadResponse> saveAdditionalTechnicianDoc({
    String? id,
    required String technicianId,
    required String documentName,
    String? documentImage,
  }) async {
    final isUpdate = id != null && id.trim().isNotEmpty;
    final response = await _apiService
        .getPostFormApiRequest(ApiConstants.createFunction, {
          'tableName': 'technicianAdditionalDocs',
          'act': isUpdate ? 'edit' : 'add',
          if (isUpdate) 'id': id.trim(),
          'technicianId': technicianId,
          'documentName': documentName,
          'folderName': 'technicianAdditionalDocs',
          if (documentImage != null && documentImage.trim().isNotEmpty)
            'documentImage': documentImage,
        });
    final uploadResponse = _uploadResponse(
      response,
      isUpdate
          ? 'Additional document updated. Admin approval is required again.'
          : 'Additional document uploaded. Admin approval is required again.',
    );
    if (uploadResponse.isSuccess) {
      await _markTechnicianPendingReview(technicianId);
    }
    return uploadResponse;
  }

  Future<void> _markTechnicianPendingReview(String technicianId) async {
    await _apiService.getPostFormApiRequest(ApiConstants.createFunction, {
      'tableName': 'technician',
      'act': 'edit',
      'id': technicianId,
      'kyc': '0',
    });
  }

  Future<String?> _getExistingTechnicianDocsId(String technicianId) async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.getData,
      {'tableName': 'technicianDocs'},
    );
    if (response is! Map) return null;
    final source = response['data'] ?? response['message'];
    if (source is! List) return null;
    for (final item in source.whereType<Map>()) {
      final row = Map<String, dynamic>.from(item);
      if (row['technicianId']?.toString() == technicianId) {
        return row['id']?.toString();
      }
    }
    return null;
  }

  UploadResponse _uploadResponse(dynamic response, String fallbackMessage) {
    if (response is Map) {
      return UploadResponse.fromJson(Map<String, dynamic>.from(response));
    }
    return UploadResponse.fromJson({
      'status': '200',
      'message': fallbackMessage,
      'data': response,
    });
  }

  List<Map<String, dynamic>> _extractListJson(dynamic response) {
    if (response is List) {
      return response
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (response is! Map) return const [];

    final json = Map<String, dynamic>.from(response);
    final data =
        json['data'] ??
        json['enquiries'] ??
        json['result'] ??
        json['rows'] ??
        json['message'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (data is Map) return [Map<String, dynamic>.from(data)];
    return const [];
  }

  Future<List<TechnicianEnquiryModel>> _withCustomerDetails(
    List<TechnicianEnquiryModel> enquiries,
  ) async {
    if (enquiries.isEmpty ||
        enquiries.every(
          (item) =>
              item.customerName.isNotEmpty && item.customerMobile.isNotEmpty,
        )) {
      return enquiries;
    }

    try {
      final response = await _apiService.getPostFormApiRequest(
        ApiConstants.getData,
        {'tableName': 'users'},
      );
      final users = _extractListJson(response);
      if (users.isEmpty) return enquiries;

      final usersById = <String, Map<String, dynamic>>{};
      for (final user in users) {
        final id = user['id']?.toString().trim() ?? '';
        if (id.isNotEmpty) usersById[id] = user;
      }

      return enquiries.map((enquiry) {
        final user = usersById[enquiry.userId];
        if (user == null) return enquiry;
        return enquiry.copyWith(
          customerName: enquiry.customerName.isNotEmpty
              ? enquiry.customerName
              : _firstUserValue(user, const ['name', 'fullName', 'userName']),
          customerMobile: enquiry.customerMobile.isNotEmpty
              ? enquiry.customerMobile
              : _firstUserValue(user, const [
                  'mobile',
                  'phone',
                  'phoneNumber',
                  'mobileNumber',
                ]),
          customerEmail: enquiry.customerEmail.isNotEmpty
              ? enquiry.customerEmail
              : _firstUserValue(user, const ['email', 'userEmail']),
        );
      }).toList();
    } catch (_) {
      return enquiries;
    }
  }

  String _firstUserValue(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'null') return value;
    }
    return '';
  }

  bool _isAvailableForNewPool(Map<String, dynamic> row) {
    final status = _norm(
      _firstUserValue(row, const ['status', 'enquiryStatus', 'enquiry_status']),
    );
    final technicianStatus = _norm(
      _firstUserValue(row, const [
        'technicianStatus',
        'technician_status',
        'techStatus',
      ]),
    );
    final assignedTechnicianId = _firstUserValue(row, const [
      'technicianId',
      'technician_id',
      'assignedTechnicianId',
      'assigned_technician_id',
    ]);
    final assignedTechnicianName = _firstUserValue(row, const [
      'technicianName',
      'technician_name',
      'assignedTechnicianName',
      'assigned_technician_name',
    ]);

    final isPending =
        status.isEmpty ||
        status == '0' ||
        status == 'pending' ||
        status == 'new';
    final isReallocated =
        technicianStatus == '7' || technicianStatus == 'reallocated';
    final isUnassigned =
        assignedTechnicianId.isEmpty && assignedTechnicianName.isEmpty;

    return isReallocated || (isPending && isUnassigned);
  }

  Future<Map<String, Map<String, dynamic>>>
  _latestTechnicianHistoryByEnquiry() async {
    try {
      final response = await _apiService.getPostFormApiRequest(
        ApiConstants.getData,
        {'tableName': 'enquiryTechnicianHistory'},
      );
      final rows = _extractListJson(response);
      final latestByEnquiry = <String, Map<String, dynamic>>{};
      for (final row in rows) {
        final enquiryId = _firstUserValue(row, const [
          'enquiryId',
          'enquiry_id',
        ]);
        if (enquiryId.isEmpty) continue;
        final existing = latestByEnquiry[enquiryId];
        final currentTime = _firstUserValue(row, const [
          'createdAt',
          'created_at',
        ]);
        final existingTime = existing == null
            ? ''
            : _firstUserValue(existing, const ['createdAt', 'created_at']);
        if (existing == null || currentTime.compareTo(existingTime) >= 0) {
          latestByEnquiry[enquiryId] = row;
        }
      }
      return latestByEnquiry;
    } catch (_) {
      return const {};
    }
  }

  Map<String, dynamic>? _applyLatestTechnicianHistory(
    Map<String, dynamic> row, {
    required String currentTechnicianId,
    required Map<String, Map<String, dynamic>> latestHistoryByEnquiry,
  }) {
    final enquiryId = _firstUserValue(row, const [
      'id',
      'enquiryId',
      'enquiry_id',
    ]);
    if (enquiryId.isEmpty) return row;

    final latestHistory = latestHistoryByEnquiry[enquiryId];
    if (latestHistory == null) return row;

    final latestStatus = _norm(
      _firstUserValue(latestHistory, const ['status', 'technicianStatus']),
    );
    final latestTechnicianId = _firstUserValue(latestHistory, const [
      'technicianId',
      'technician_id',
    ]);

    if (latestStatus != '7' && latestStatus != 'reallocated') {
      return row;
    }

    if (latestTechnicianId.trim() == currentTechnicianId.trim()) {
      return null;
    }

    return {
      ...row,
      'status': '0',
      'technicianStatus': '',
      'technicianId': '',
      'technicianName': '',
    };
  }

  Future<List<TechnicianEnquiryModel>> _filterEnquiriesForTechnicianSkills({
    required String technicianId,
    required List<TechnicianEnquiryModel> enquiries,
  }) async {
    if (enquiries.isEmpty) return enquiries;

    final skills = await getTechnicianSkills(
      GetTechnicianSkillsRequest(technicianId: technicianId),
    );
    if (skills.isEmpty) return const [];

    return enquiries.where((enquiry) {
      final enquiryCategory = enquiry.categoryId.trim();
      final enquirySubCategory = enquiry.subCategoryId.trim();
      return skills.any((skill) {
        final categoryMatches =
            skill.categoryId.trim().isNotEmpty &&
            skill.categoryId.trim() == enquiryCategory;
        final skillSubCategory = skill.subCategoryId.trim();
        final subCategoryMatches =
            skillSubCategory.isEmpty ||
            enquirySubCategory.isEmpty ||
            skillSubCategory == enquirySubCategory;
        return categoryMatches && subCategoryMatches;
      });
    }).toList();
  }

  String _norm(String value) => value.trim().toLowerCase();
}
