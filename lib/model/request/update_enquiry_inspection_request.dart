class UpdateEnquiryInspectionRequest {
  const UpdateEnquiryInspectionRequest({
    required this.enquiryId,
    required this.imagesBase64,
    this.folderName = 'inspection',
  });

  final String enquiryId;
  final List<String> imagesBase64;
  final String folderName;

  Map<String, String> toFormData() {
    return {
      'tableName': 'enquiries',
      'act': 'edit',
      'id': enquiryId.trim(),
      'folderName': folderName,
      for (var index = 0; index < imagesBase64.length && index < 4; index++)
        'inspectionImage${index + 1}': imagesBase64[index],
    };
  }
}
