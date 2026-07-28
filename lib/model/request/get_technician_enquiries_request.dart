class GetTechnicianEnquiriesRequest {
  const GetTechnicianEnquiriesRequest({
    required this.technicianId,
    this.page = 1,
    this.limit = 10,
  });

  final String technicianId;
  final int page;
  final int limit;

  Map<String, String> toFormData() {
    return {
      'technicianId': technicianId,
      'page': page.toString(),
      'limit': limit.toString(),
    };
  }
}
