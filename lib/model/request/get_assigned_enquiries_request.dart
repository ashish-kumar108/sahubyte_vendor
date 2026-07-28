class GetAssignedEnquiriesRequest {
  const GetAssignedEnquiriesRequest({
    required this.technicianId,
    required this.enquiryStatus,
    required this.technicianStatus,
    this.page = 1,
    this.limit = 10,
  });

  final String technicianId;
  final String enquiryStatus;
  final String technicianStatus;
  final int page;
  final int limit;

  Map<String, String> toFormData() {
    return {
      'technicianId': technicianId,
      'enquiryStatus': enquiryStatus,
      'technicianStatus': technicianStatus,
      'page': page.toString(),
      'limit': limit.toString(),
    };
  }
}
