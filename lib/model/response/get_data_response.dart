class GetDataResponse {
  const GetDataResponse({
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

  List<Map<String, dynamic>> get rows {
    final source = data;
    if (source is! List) return const [];
    return source
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  factory GetDataResponse.fromJson(Map<String, dynamic> json) {
    return GetDataResponse(
      status: json['status']?.toString(),
      message: json['message'] is String ? json['message']?.toString() : null,
      data: json['data'] ?? json['message'],
      raw: json,
    );
  }
}
