class TechnicianSkillResponse {
  const TechnicianSkillResponse({
    this.status,
    this.message,
    this.data,
    required this.raw,
  });

  final String? status;
  final String? message;
  final dynamic data;
  final Map<String, dynamic> raw;

  bool get isSuccess => status == '200' || status?.toLowerCase() == 'success';

  String get displayMessage {
    return message ??
        (isSuccess ? 'Skills saved successfully.' : 'Unable to save skills.');
  }

  factory TechnicianSkillResponse.fromJson(Map<String, dynamic> json) {
    return TechnicianSkillResponse(
      status: json['status']?.toString(),
      message: json['message']?.toString() ?? json['msg']?.toString(),
      data: json['data'],
      raw: json,
    );
  }
}
