class UpdateProfileImageRequest {
  const UpdateProfileImageRequest({
    required this.technicianId,
    required this.profileImage,
    required this.folderName,
    required this.fileName,
    required this.imageBase64,
  });

  final String technicianId;
  final String profileImage;
  final String folderName;
  final String fileName;
  final String imageBase64;

  Map<String, dynamic> toJson() {
    return {
      'technicianId': technicianId,
      'profileImage': profileImage,
      'folderName': folderName,
      'fileName': fileName,
    };
  }
}
