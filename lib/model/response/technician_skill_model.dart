class TechnicianSkillModel {
  const TechnicianSkillModel({
    required this.id,
    required this.technicianId,
    required this.categoryId,
    required this.subCategoryId,
    required this.categoryName,
    required this.subCategoryName,
  });

  final String id;
  final String technicianId;
  final String categoryId;
  final String subCategoryId;
  final String categoryName;
  final String subCategoryName;

  factory TechnicianSkillModel.fromJson(Map<String, dynamic> json) {
    return TechnicianSkillModel(
      id: json['id']?.toString() ?? '',
      technicianId: json['technicianId']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      subCategoryId:
          json['subCategoryId']?.toString() ??
          json['subcategoryId']?.toString() ??
          '',
      categoryName:
          json['categoryName']?.toString() ??
          json['category']?.toString() ??
          '',
      subCategoryName:
          json['subCategoryName']?.toString() ??
          json['subcategoryName']?.toString() ??
          json['subCategory']?.toString() ??
          '',
    );
  }
}
