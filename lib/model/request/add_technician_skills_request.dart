class AddTechnicianSkillsRequest {
  const AddTechnicianSkillsRequest({
    required this.technicianId,
    required this.categoryId,
    required this.subCategoryId,
  });

  final String technicianId;
  final String categoryId;
  final String subCategoryId;

  Map<String, String> toJson() {
    return {
      'tableName': 'technicianSkill',
      'act': 'add',
      'technicianId': technicianId,
      'categoryId': categoryId,
      'subCategoryId': subCategoryId,
    };
  }
}
