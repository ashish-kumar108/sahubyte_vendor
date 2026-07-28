class UpdateEnquiryReallocationRequest {
  const UpdateEnquiryReallocationRequest({
    required this.enquiryId,
    required this.note,
  });

  final String enquiryId;
  final String note;

  Map<String, String> toFormData() {
    return {
      'tableName': 'enquiries',
      'act': 'edit',
      'id': enquiryId.trim(),
      'reallocatedNote': note.trim(),
      'workConfirmation': '0',
      'workConfirmationDate': '',
      'partTotalPrice': '0',
    };
  }
}
