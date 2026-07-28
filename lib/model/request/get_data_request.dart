class GetDataRequest {
  const GetDataRequest({required this.tableName, this.params = const {}});

  final String tableName;
  final Map<String, dynamic> params;

  Map<String, dynamic> toJson() {
    return {'tableName': tableName, ...params};
  }

  Map<String, String> toFormData() {
    return {
      'tableName': tableName,
      ...params.map((key, value) => MapEntry(key, value.toString())),
    };
  }
}
