class UploadResponse {
  const UploadResponse({
    this.status,
    this.message,
    this.data,
    required this.raw,
  });

  final String? status;
  final String? message;
  final dynamic data;
  final Map<String, dynamic> raw;

  bool get isSuccess =>
      status == '200' || status == '1' || status?.toLowerCase() == 'success';

  String get displayMessage {
    return message ??
        (isSuccess ? 'Upload completed successfully.' : 'Upload failed.');
  }

  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(
      status: json['status']?.toString(),
      message: json['message']?.toString() ?? json['msg']?.toString(),
      data: json['data'],
      raw: json,
    );
  }
}
