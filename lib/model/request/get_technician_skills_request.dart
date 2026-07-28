class GetTechnicianSkillsRequest {
  const GetTechnicianSkillsRequest({required this.technicianId});

  final String technicianId;

  Map<String, String> toFormData() {
    return {'technicianId': technicianId};
  }
}
