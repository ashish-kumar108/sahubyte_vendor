class GetProblemsRequest {
  const GetProblemsRequest({required this.problemIds});

  final List<String> problemIds;

  Map<String, dynamic> toJson() {
    return {'problemIds': problemIds};
  }
}
