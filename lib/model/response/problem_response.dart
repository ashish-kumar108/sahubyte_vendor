class ProblemResponse {
  const ProblemResponse({
    this.status,
    this.message,
    required this.data,
    required this.raw,
  });

  final String? status;
  final String? message;
  final List<ProblemModel> data;
  final Map<String, dynamic> raw;

  bool get isSuccess => status == '200' || status?.toLowerCase() == 'success';

  factory ProblemResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return ProblemResponse(
      status: json['status']?.toString(),
      message: json['message']?.toString(),
      data: rawData is List
          ? rawData
                .whereType<Map>()
                .map(
                  (item) =>
                      ProblemModel.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
      raw: json,
    );
  }
}

class ProblemModel {
  const ProblemModel({required this.id, required this.problemName});

  final String id;
  final String problemName;

  factory ProblemModel.fromJson(Map<String, dynamic> json) {
    return ProblemModel(
      id: json['id']?.toString() ?? '',
      problemName: json['problemName']?.toString() ?? '',
    );
  }
}
