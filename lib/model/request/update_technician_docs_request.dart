class UpdateTechnicianDocsRequest {
  const UpdateTechnicianDocsRequest({
    required this.technicianId,
    required this.folderName,
    required this.fileName,
    this.imageBase64,
    this.aadharImage,
    this.panImage,
    this.drivingImage,
    this.additionalDoc,
    this.qualification,
  });

  final String technicianId;
  final String folderName;
  final String fileName;
  final String? imageBase64;
  final String? aadharImage;
  final String? panImage;
  final String? drivingImage;
  final String? additionalDoc;
  final String? qualification;

  Map<String, dynamic> toJson() {
    return {
      'technicianId': technicianId,
      'folderName': folderName,
      'fileName': fileName,
      if (aadharImage != null) 'aadharImage': aadharImage,
      if (panImage != null) 'panImage': panImage,
      if (drivingImage != null) 'drivingImage': drivingImage,
      if (additionalDoc != null) 'additionalDoc': additionalDoc,
      if (qualification != null) 'qualification': qualification,
    };
  }
}
