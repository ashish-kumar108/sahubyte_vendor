import 'package:flutter/foundation.dart';
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
import 'package:sahubyte_vendor/repository/technician_repository.dart';

class TechnicianViewModel extends ChangeNotifier {
  TechnicianViewModel({TechnicianRepository? repository})
    : _repository = repository ?? TechnicianRepository();

  final TechnicianRepository _repository;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<ProblemResponse> getProblems(List<String> problemIds) {
    return _run(
      () => _repository.getProblems(GetProblemsRequest(problemIds: problemIds)),
    );
  }

  Future<TechnicianSkillResponse> addTechnicianSkills({
    required String technicianId,
    required String categoryId,
    required String subCategoryId,
  }) {
    return _run(
      () => _repository.addTechnicianSkills(
        AddTechnicianSkillsRequest(
          technicianId: technicianId,
          categoryId: categoryId,
          subCategoryId: subCategoryId,
        ),
      ),
    );
  }

  Future<List<TechnicianSkillModel>> getTechnicianSkills({
    required String technicianId,
  }) {
    return _run(
      () => _repository.getTechnicianSkills(
        GetTechnicianSkillsRequest(technicianId: technicianId),
      ),
    );
  }

  Future<UploadResponse> deleteTechnicianSkill(String id) {
    return _run(() => _repository.deleteTechnicianSkill(id));
  }

  Future<List<TechnicianEnquiryModel>> getTechnicianEnquiries({
    required String technicianId,
    int page = 1,
    int limit = 10,
  }) {
    return _run(
      () => _repository.getTechnicianEnquiries(
        GetTechnicianEnquiriesRequest(
          technicianId: technicianId,
          page: page,
          limit: limit,
        ),
      ),
    );
  }

  Future<UploadResponse> assignTechnician({
    required String enquiryId,
    required String technicianId,
  }) {
    return _run(
      () => _repository.assignTechnician(
        enquiryId: enquiryId,
        technicianId: technicianId,
      ),
    );
  }

  Future<List<TechnicianEnquiryModel>> getAssignedEnquiries({
    required String technicianId,
    required String enquiryStatus,
    required String technicianStatus,
    int page = 1,
    int limit = 10,
  }) {
    return _run(
      () => _repository.getAssignedEnquiries(
        GetAssignedEnquiriesRequest(
          technicianId: technicianId,
          enquiryStatus: enquiryStatus,
          technicianStatus: technicianStatus,
          page: page,
          limit: limit,
        ),
      ),
    );
  }

  Future<double?> getTechnicianRating({required String technicianId}) {
    return _run(
      () => _repository.getTechnicianRating(technicianId: technicianId),
    );
  }

  Future<UploadResponse> updateTechnicianStatus({
    required String enquiryId,
    required String technicianId,
    required String status,
    String? reallocatedNote,
  }) {
    return _run(
      () => _repository.updateTechnicianStatus(
        enquiryId: enquiryId,
        technicianId: technicianId,
        status: status,
        reallocatedNote: reallocatedNote,
      ),
    );
  }

  Future<UploadResponse> updateFinalPaymentStatus({
    required String enquiryId,
    required String paymentType,
    required String paymentStatus,
  }) {
    return _run(
      () => _repository.updateFinalPaymentStatus(
        enquiryId: enquiryId,
        paymentType: paymentType,
        paymentStatus: paymentStatus,
      ),
    );
  }

  Future<UploadResponse> saveInspection({
    required String enquiryId,
    required List<String> imagesBase64,
  }) {
    return _run(
      () => _repository.saveInspection(
        UpdateEnquiryInspectionRequest(
          enquiryId: enquiryId,
          imagesBase64: imagesBase64,
        ),
      ),
    );
  }

  Future<UploadResponse> saveReallocationNote({
    required String enquiryId,
    required String note,
  }) {
    return _run(
      () => _repository.saveReallocationNote(
        UpdateEnquiryReallocationRequest(enquiryId: enquiryId, note: note),
      ),
    );
  }

  Future<UploadResponse> createJobCard({
    required String enquiryId,
    required String details,
    required List<Map<String, dynamic>> parts,
    bool resetApproval = false,
    int? enquiryTotalPrice,
    String problemChangeDetails = '',
  }) {
    return _run(
      () => _repository.createJobCard(
        enquiryId: enquiryId,
        details: details,
        parts: parts,
        resetApproval: resetApproval,
        enquiryTotalPrice: enquiryTotalPrice,
        problemChangeDetails: problemChangeDetails,
      ),
    );
  }

  Future<UploadResponse> updateEnquiryProblem({
    required String enquiryId,
    required String problemTableId,
    required String newProblemId,
    required String enquiryCategoryId,
    required String enquirySubCategoryId,
  }) {
    return _run(
      () => _repository.updateEnquiryProblem(
        enquiryId: enquiryId,
        problemTableId: problemTableId,
        newProblemId: newProblemId,
        enquiryCategoryId: enquiryCategoryId,
        enquirySubCategoryId: enquirySubCategoryId,
      ),
    );
  }

  Future<Map<String, dynamic>?> getJobCard({required String enquiryId}) {
    return _run(() => _repository.getJobCard(enquiryId: enquiryId));
  }

  Future<List<Map<String, dynamic>>> getPartsForService({
    required String categoryId,
    required String subCategoryId,
  }) {
    return _run(
      () => _repository.getPartsForService(
        categoryId: categoryId,
        subCategoryId: subCategoryId,
      ),
    );
  }

  Future<UploadResponse> updateProfileImage({
    required String technicianId,
    required String profileImage,
    required String folderName,
    required String fileName,
    required String imageBase64,
  }) {
    return _run(
      () => _repository.updateProfileImage(
        UpdateProfileImageRequest(
          technicianId: technicianId,
          profileImage: profileImage,
          folderName: folderName,
          fileName: fileName,
          imageBase64: imageBase64,
        ),
      ),
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
  }) {
    return _run(
      () => _repository.updateTechnicianProfile(
        technicianId: technicianId,
        name: name,
        email: email,
        mobile: mobile,
        dob: dob,
        address: address,
        state: state,
        pincode: pincode,
      ),
    );
  }

  Future<UploadResponse> updateTechnicianBanking({
    required String technicianId,
    required String accountName,
    required String ifsc,
    required String accountNo,
    required String upiNo,
  }) {
    return _run(
      () => _repository.updateTechnicianBanking(
        technicianId: technicianId,
        accountName: accountName,
        ifsc: ifsc,
        accountNo: accountNo,
        upiNo: upiNo,
      ),
    );
  }

  Future<UploadResponse> updateTechnicianDocs({
    required String technicianId,
    required String folderName,
    required String fileName,
    String? imageBase64,
    String? aadharImage,
    String? panImage,
    String? drivingImage,
    String? additionalDoc,
    String? qualification,
  }) {
    return _run(
      () => _repository.updateTechnicianDocs(
        UpdateTechnicianDocsRequest(
          technicianId: technicianId,
          folderName: folderName,
          fileName: fileName,
          imageBase64: imageBase64,
          aadharImage: aadharImage,
          panImage: panImage,
          drivingImage: drivingImage,
          additionalDoc: additionalDoc,
          qualification: qualification,
        ),
      ),
    );
  }

  Future<UploadResponse> saveAdditionalTechnicianDoc({
    String? id,
    required String technicianId,
    required String documentName,
    String? documentImage,
  }) {
    return _run(
      () => _repository.saveAdditionalTechnicianDoc(
        id: id,
        technicianId: technicianId,
        documentName: documentName,
        documentImage: documentImage,
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
