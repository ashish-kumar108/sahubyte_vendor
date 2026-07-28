import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sahubyte_vendor/view/app_ui.dart';
import 'package:sahubyte_vendor/model/response/technician_enquiry_model.dart';
import 'package:sahubyte_vendor/view/approval_submitted_view.dart';
import 'package:sahubyte_vendor/view_model/technician_view_model.dart';
import 'package:sahubyte_vendor/view_model/user_view_model.dart';

class FinalJobCardView extends StatefulWidget {
  const FinalJobCardView({super.key, this.booking, this.technicianId});

  final TechnicianEnquiryModel? booking;
  final String? technicianId;

  @override
  State<FinalJobCardView> createState() => _FinalJobCardViewState();
}

class _FinalJobCardViewState extends State<FinalJobCardView> {
  final Set<String> _selectedIssues = {};
  final TechnicianViewModel _viewModel = TechnicianViewModel();
  final UserViewModel _userViewModel = UserViewModel();
  final TextEditingController _observationController = TextEditingController();
  final List<Map<String, Object>> _selectedSolutions = [];
  List<Map<String, Object>> _solutions = const [];
  List<String> _issues = const [];
  Map<String, _IssueOption> _issueOptions = const {};
  bool _isLoadingParts = true;
  bool _isSubmitting = false;
  bool _hasExistingJobCard = false;

  int get _partsTotal => _selectedSolutions.fold<int>(
    0,
    (sum, item) => sum + (item['price']! as int),
  );

  int get _originalProblemTotal =>
      widget.booking?.problemItems.fold<int>(
        0,
        (sum, item) => sum + item.price,
      ) ??
      0;

  int get _selectedProblemTotal => _issues
      .where(_selectedIssues.contains)
      .map((label) => _issueOptions[label]?.price ?? 0)
      .fold<int>(0, (sum, price) => sum + price);

  int get _approvalEstimate => _partsTotal + _selectedProblemTotal;

  Map<String, dynamic> get _problemChangePayload {
    if (!_hasIssueChange) return const {};
    final selectedProblemNames = _selectedIssues
        .map(_issueDisplayName)
        .where((name) => name.trim().isNotEmpty)
        .toList();
    final originalProblemNames =
        widget.booking?.problemItems
            .map((problem) => _issueDisplayName(problem.name))
            .where((name) => name.trim().isNotEmpty)
            .toList() ??
        const <String>[];
    return {
      'oldProblemNames': originalProblemNames,
      'newProblemNames': selectedProblemNames,
      'oldProblemPrice': _originalProblemTotal,
      'newProblemPrice': _selectedProblemTotal,
    };
  }

  String get _problemChangeDetails {
    final payload = _problemChangePayload;
    return payload.isEmpty ? '' : jsonEncode(payload);
  }

  bool get _hasIssueChange {
    final booking = widget.booking;
    if (booking == null) return false;
    final originalIds = booking.problemItems
        .map((problem) => problem.id.trim())
        .where((id) => id.isNotEmpty)
        .toList();
    final selectedIds = _issues
        .where(_selectedIssues.contains)
        .map((label) => _issueOptions[label]?.problemId.trim() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
    if (originalIds.length != selectedIds.length) return true;
    for (var i = 0; i < originalIds.length; i++) {
      if (originalIds[i] != selectedIds[i]) return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    final booking = widget.booking;
    final initialIssueOptions = <String, _IssueOption>{};
    final apiIssues =
        booking?.problemItems
            .where((problem) => problem.name.trim().isNotEmpty)
            .map((problem) {
              final label = problem.name.trim();
              initialIssueOptions[label] = _IssueOption(
                label: label,
                problemId: problem.id,
                problemTableId: problem.problemTableId,
                price: problem.price,
              );
              return label;
            })
            .toList() ??
        const <String>[];
    _issues = apiIssues.isEmpty
        ? [_issueDisplayName(booking?.problemSummary ?? 'Not available')]
        : apiIssues;
    _issueOptions = initialIssueOptions;
    _selectedIssues.addAll(_issues);
    _loadJobCardData();
  }

  @override
  void dispose() {
    _observationController.dispose();
    _viewModel.dispose();
    _userViewModel.dispose();
    super.dispose();
  }

  Future<void> _loadJobCardData() async {
    final booking = widget.booking;
    if (booking == null) {
      if (mounted) setState(() => _isLoadingParts = false);
      return;
    }

    try {
      final results = await Future.wait<dynamic>([
        _viewModel.getPartsForService(
          categoryId: booking.categoryId,
          subCategoryId: booking.subCategoryId,
        ),
        _viewModel.getJobCard(enquiryId: booking.id),
        _userViewModel.getData(tableName: 'problemMapping'),
        _userViewModel.getData(tableName: 'problem'),
      ]);
      final parts = results[0] as List<Map<String, dynamic>>;
      final jobCard = results[1] as Map<String, dynamic>?;
      final problemMappings = results[2].rows as List<Map<String, dynamic>>;
      final problems = results[3].rows as List<Map<String, dynamic>>;
      final apiParts = parts
          .map(_partFromJson)
          .where((part) => (part['name'] as String).isNotEmpty)
          .toList();
      final savedParts = _partsFromJobCard(jobCard);
      final savedDetails = _detailsFromJobCard(jobCard);
      final savedIssues = _issuesFromJobCard(jobCard);
      final mappedIssues = _issuesFromProblemMaster(
        categoryId: booking.categoryId,
        subCategoryId: booking.subCategoryId,
        mappings: problemMappings,
        problems: problems,
      );
      final enquiryProblemIssues = await _issuesFromEnquiryProblemTables(
        enquiryId: booking.id,
        categoryId: booking.categoryId,
        subCategoryId: booking.subCategoryId,
        problems: problems,
      );

      if (!mounted) return;
      setState(() {
        _solutions = apiParts;
        _issues = _uniqueStrings([
          ..._issues,
          ...mappedIssues.keys,
          ...enquiryProblemIssues.keys,
        ]);
        _issueOptions = _mergeIssueOptions(
          _mergeIssueOptions(_issueOptions, mappedIssues),
          enquiryProblemIssues,
        );
        _selectedSolutions
          ..clear()
          ..addAll(savedParts);
        if (savedDetails.isNotEmpty) {
          _observationController.text = savedDetails;
        }
        if (savedIssues.isNotEmpty) {
          _selectedIssues
            ..clear()
            ..addAll(savedIssues);
        }
        _hasExistingJobCard = jobCard != null && jobCard.isNotEmpty;
        _isLoadingParts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingParts = false);
      _showMessage('Unable to load parts. Please try again.');
    }
  }

  Map<String, Object> _partFromJson(Map<String, dynamic> json) {
    final id = _firstValue(json, const ['partId', 'id', 'partsId']);
    final name = _firstValue(json, const [
      'partName',
      'partsName',
      'name',
      'title',
    ]);
    final price = _parsePrice(
      _firstValue(json, const ['price', 'amount', 'partPrice']),
    );
    return {'partId': id.isEmpty ? name : id, 'name': name, 'price': price};
  }

  List<Map<String, Object>> _partsFromJobCard(Map<String, dynamic>? json) {
    if (json == null) return const [];
    final source = json['parts'] ?? json['part'] ?? json['items'];
    if (source is! List) return const [];
    return source
        .whereType<Map>()
        .map((item) => _partFromJson(Map<String, dynamic>.from(item)))
        .where((part) => (part['name'] as String).isNotEmpty)
        .toList();
  }

  String _detailsFromJobCard(Map<String, dynamic>? json) {
    if (json == null) return '';
    final raw = _firstValue(json, const ['details', 'note', 'description']);
    final parsed = _jsonMap(raw);
    return _firstValue(parsed, const [
          'technicianObservation',
          'observation',
          'details',
          'note',
        ]).isNotEmpty
        ? _firstValue(parsed, const [
            'technicianObservation',
            'observation',
            'details',
            'note',
          ])
        : raw;
  }

  List<String> _issuesFromJobCard(Map<String, dynamic>? json) {
    if (json == null) return const [];
    final raw = _firstValue(json, const ['details', 'issue', 'problem']);
    final parsed = _jsonMap(raw);
    final source =
        parsed['selectedIssues'] ??
        parsed['issues'] ??
        json['selectedIssues'] ??
        json['issues'];
    if (source is List) {
      return source
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty && item.toLowerCase() != 'null')
          .toList();
    }
    final single = _firstValue(parsed, const ['selectedIssue', 'issue']);
    return single.isEmpty ? const [] : [single];
  }

  Map<String, _IssueOption> _issuesFromProblemMaster({
    required String categoryId,
    required String subCategoryId,
    required List<Map<String, dynamic>> mappings,
    required List<Map<String, dynamic>> problems,
  }) {
    final problemNameById = {
      for (final problem in problems)
        _firstValue(problem, const ['id', 'problemId']): _firstValue(
          problem,
          const ['problemName', 'name', 'title'],
        ),
    };
    final mapped = <String, _IssueOption>{};
    for (final row in mappings) {
      final rowCategoryId = _firstValue(row, const ['categoryId']);
      final rowSubCategoryId = _firstValue(row, const [
        'subCategoryId',
        'subcategoryId',
      ]);
      if (rowCategoryId != categoryId || rowSubCategoryId != subCategoryId) {
        continue;
      }
      final problemId = _firstValue(row, const ['problemId']);
      final problemName = problemNameById[problemId] ?? '';
      if (problemName.trim().isEmpty) continue;
      final label = _issueDisplayName(problemName);
      mapped[label] = _IssueOption(
        label: label,
        problemId: problemId,
        price: _parsePrice(_firstValue(row, const ['price', 'amount'])),
      );
    }
    return mapped;
  }

  Future<Map<String, _IssueOption>> _issuesFromEnquiryProblemTables({
    required String enquiryId,
    required String categoryId,
    required String subCategoryId,
    required List<Map<String, dynamic>> problems,
  }) async {
    final problemNameById = {
      for (final problem in problems)
        _firstValue(problem, const ['id', 'problemId']): _firstValue(
          problem,
          const ['problemName', 'name', 'title'],
        ),
    };
    for (final tableName in const [
      'enquiryProblem',
      'enquiryProblems',
      'enquiryProblemDetails',
    ]) {
      try {
        final response = await _userViewModel.getData(tableName: tableName);
        final mapped = <String, _IssueOption>{};
        for (final row in response.rows) {
          final rowEnquiryId = _firstValue(row, const [
            'enquiryId',
            'enquiry_id',
            'bookingId',
          ]);
          if (rowEnquiryId != enquiryId) continue;

          final rowCategoryId = _firstValue(row, const ['categoryId']);
          final rowSubCategoryId = _firstValue(row, const [
            'subCategoryId',
            'subcategoryId',
          ]);
          final categoryMatches =
              rowCategoryId.isEmpty || rowCategoryId == categoryId;
          final subCategoryMatches =
              rowSubCategoryId.isEmpty || rowSubCategoryId == subCategoryId;
          if (!categoryMatches || !subCategoryMatches) continue;

          final problemId = _firstValue(row, const ['problemId', 'problem_id']);
          if (problemId.isEmpty) continue;
          final problemName =
              _firstValue(row, const [
                'problemName',
                'name',
                'title',
              ]).isNotEmpty
              ? _firstValue(row, const ['problemName', 'name', 'title'])
              : (problemNameById[problemId] ?? '');
          if (problemName.trim().isEmpty) continue;
          final label = _issueDisplayName(problemName);
          mapped[label] = _IssueOption(
            label: label,
            problemId: problemId,
            problemTableId: _firstValue(row, const [
              'problemTableId',
              'enquiryProblemId',
              'enquiryProblemDetailId',
              'id',
            ]),
            price: _parsePrice(_firstValue(row, const ['price', 'amount'])),
          );
        }
        if (mapped.isNotEmpty) return mapped;
      } catch (_) {}
    }
    return const {};
  }

  Map<String, _IssueOption> _mergeIssueOptions(
    Map<String, _IssueOption> current,
    Map<String, _IssueOption> mapped,
  ) {
    final result = <String, _IssueOption>{...current};
    for (final entry in mapped.entries) {
      final existing = result[entry.key];
      if (existing == null) {
        result[entry.key] = entry.value;
        continue;
      }
      result[entry.key] = existing.copyWith(
        problemId: existing.problemId.isNotEmpty
            ? existing.problemId
            : entry.value.problemId,
        problemTableId: entry.value.problemTableId.isNotEmpty
            ? entry.value.problemTableId
            : existing.problemTableId,
        price: existing.price > 0 ? existing.price : entry.value.price,
      );
    }
    return result;
  }

  List<String> _uniqueStrings(Iterable<String> values) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in values) {
      final clean = value.trim();
      if (clean.isEmpty || !seen.add(clean.toLowerCase())) continue;
      result.add(clean);
    }
    return result;
  }

  Map<String, dynamic> _jsonMap(String value) {
    if (value.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return const {};
  }

  String _firstValue(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'null') return value;
    }
    return '';
  }

  int _parsePrice(String value) {
    return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  String get _jobDetails {
    final selectedProblemNames = _selectedIssues
        .map(_issueDisplayName)
        .where((name) => name.trim().isNotEmpty)
        .toList();
    final problemChange = _problemChangePayload;
    return jsonEncode({
      'technicianObservation': _observationController.text.trim(),
      'selectedIssues': selectedProblemNames,
      'issueChanged': _hasIssueChange,
      'partsTotal': _partsTotal,
      'problemCharge': _selectedProblemTotal,
      'approvalEstimate': _approvalEstimate,
      'oldProblemPrice': _originalProblemTotal,
      'newProblemPrice': _selectedProblemTotal,
      if (problemChange.isNotEmpty) 'problemChange': problemChange,
    });
  }

  String get _observationText {
    return _observationController.text.trim();
  }

  Future<void> _submitJobCard() async {
    if (_isSubmitting) return;
    final booking = widget.booking;
    if (booking == null || booking.id.isEmpty) {
      _showMessage('Booking ID is missing.');
      return;
    }
    if (_selectedIssues.isEmpty) {
      _showMessage('Please select at least one original issue.');
      return;
    }
    if (_observationText.isEmpty) {
      _showMessage('Please enter the technician observation.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final wasEditing = _hasExistingJobCard;
      await _syncChangedProblems(booking);
      final response = await _viewModel.createJobCard(
        enquiryId: booking.id,
        details: _jobDetails,
        parts: _selectedSolutions
            .map(
              (part) => {
                'partId': part['partId'].toString(),
                'partName': part['name'].toString(),
                'price': part['price'].toString(),
              },
            )
            .toList(),
        resetApproval: true,
        enquiryTotalPrice: _approvalEstimate,
        problemChangeDetails: _problemChangeDetails,
      );
      if (!response.isSuccess) throw Exception(response.message);
      if (!mounted) return;
      setState(() => _hasExistingJobCard = true);
      if (wasEditing) {
        _showMessage('Job card updated and sent for approval.');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ApprovalSubmittedView(
              totalAmount: _approvalEstimate,
              solutionCount: _selectedSolutions.length,
              booking: booking,
            ),
          ),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ApprovalSubmittedView(
            totalAmount: _approvalEstimate,
            solutionCount: _selectedSolutions.length,
            booking: booking,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        _showMessage(
          professionalErrorMessage(
            error,
            fallback: 'Unable to submit the job card. Please try again.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _syncChangedProblems(TechnicianEnquiryModel booking) async {
    final originalOptions = booking.problemItems
        .map((problem) => _issueOptionForProblem(problem.id, problem.name))
        .whereType<_IssueOption>()
        .toList();
    final selectedOptions = _issues
        .where(_selectedIssues.contains)
        .map((label) => _issueOptions[label])
        .whereType<_IssueOption>()
        .where((option) => option.problemId.isNotEmpty)
        .toList();

    if (originalOptions.isEmpty || selectedOptions.isEmpty) return;

    final originalIds = originalOptions.map((item) => item.problemId).join(',');
    final selectedIds = selectedOptions.map((item) => item.problemId).join(',');
    if (originalIds == selectedIds) return;

    final updateCount = originalOptions.length < selectedOptions.length
        ? originalOptions.length
        : selectedOptions.length;
    for (var index = 0; index < updateCount; index++) {
      final original = originalOptions[index];
      final selected = selectedOptions[index];
      if (original.problemId == selected.problemId) continue;

      final problemTableId = original.problemTableId;
      if (problemTableId.isEmpty) {
        throw Exception('Missing original problem record ID.');
      }

      final response = await _viewModel.updateEnquiryProblem(
        enquiryId: booking.id,
        problemTableId: problemTableId,
        newProblemId: selected.problemId,
        enquiryCategoryId: booking.categoryId,
        enquirySubCategoryId: booking.subCategoryId,
      );
      if (!response.isSuccess) {
        throw Exception(response.displayMessage);
      }
    }
  }

  _IssueOption? _issueOptionForProblem(String problemId, String problemName) {
    final byId = _issueOptions.values.where(
      (option) => option.problemId == problemId && option.problemId.isNotEmpty,
    );
    if (byId.isNotEmpty) return byId.first;

    final label = _issueDisplayName(problemName);
    return _issueOptions[label];
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryDark,
      ),
    );
  }

  void _showOriginalIssueSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: .78,
        minChildSize: .52,
        maxChildSize: .92,
        expand: false,
        builder: (context, scrollController) => StatefulBuilder(
          builder: (context, modalSetState) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      height: 4,
                      width: 44,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Select Diagnosed Issues',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Keep the reported issues or update them when your inspection finds a different problem.',
                    style: TextStyle(color: AppColors.muted, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: _issues.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final issue = _issues[index];
                        final selected = _selectedIssues.contains(issue);
                        return CheckboxListTile(
                          value: selected,
                          activeColor: AppColors.primary,
                          controlAffinity: ListTileControlAffinity.trailing,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          tileColor: selected
                              ? AppColors.primarySoft
                              : Colors.white,
                          title: Text(
                            _issueDisplayName(issue),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          onChanged: (_) {
                            setState(() {
                              if (selected) {
                                _selectedIssues.remove(issue);
                              } else {
                                _selectedIssues.add(issue);
                              }
                            });
                            modalSetState(() {});
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    label: 'Apply Issues',
                    icon: Icons.check_rounded,
                    onPressed: _selectedIssues.isEmpty
                        ? null
                        : () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddSolutionSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.74,
        maxChildSize: 0.92,
        minChildSize: 0.48,
        expand: false,
        builder: (context, scrollController) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              children: [
                Container(
                  height: 4,
                  width: 44,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Add Parts',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: StatefulBuilder(
                    builder: (context, modalSetState) {
                      return ListView.separated(
                        controller: scrollController,
                        itemCount: _solutions.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final solution = _solutions[index];
                          final name = solution['name']! as String;
                          final price = solution['price']! as int;
                          final selected = _selectedSolutions.any(
                            (item) => item['name'] == name,
                          );

                          return CheckboxListTile(
                            value: selected,
                            activeColor: AppColors.primary,
                            controlAffinity: ListTileControlAffinity.leading,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            tileColor: selected
                                ? AppColors.primarySoft
                                : Colors.white,
                            title: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            subtitle: Text('Estimated cost Rs. $price'),
                            secondary: Text(
                              'Rs. $price',
                              style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            onChanged: (_) {
                              setState(() {
                                if (selected) {
                                  _selectedSolutions.removeWhere(
                                    (item) => item['name'] == name,
                                  );
                                } else {
                                  _selectedSolutions.add({
                                    'partId': solution['partId'] ?? name,
                                    'name': name,
                                    'price': price,
                                  });
                                }
                              });
                              modalSetState(() {});
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                PrimaryButton(
                  label: 'Apply Selection',
                  icon: Icons.check_rounded,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _solutionRow(Map<String, Object> solution) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              solution['name']! as String,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Rs. ${solution['price']}',
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _issueChip(String issue) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.report_problem_outlined,
            color: AppColors.primary,
            size: 17,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              _issueDisplayName(issue),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _estimateRow(String label, int value, {bool bold = false}) {
    final amount = value < 0 ? '- Rs. ${-value}' : 'Rs. $value';
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: bold ? AppColors.text : AppColors.muted,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w800,
            ),
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: bold ? 22 : 15,
            color: bold ? AppColors.primaryDark : AppColors.text,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _serviceTile(String label, IconData icon, Color tint) {
    return Expanded(
      child: Container(
        height: 92,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tint.withValues(alpha: 0.28), width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: tint, size: 25),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label.isEmpty ? 'Not set' : label,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _serviceInfoCard(TechnicianEnquiryModel? booking) {
    return Row(
      children: [
        _serviceTile(
          booking?.categoryName.isNotEmpty == true
              ? booking!.categoryName
              : 'Category',
          Icons.memory_outlined,
          AppColors.primary,
        ),
        const SizedBox(width: 10),
        _serviceTile(
          booking?.subCategoryName.isNotEmpty == true
              ? booking!.subCategoryName
              : 'Sub category',
          Icons.laptop_mac_outlined,
          AppColors.accent,
        ),
        const SizedBox(width: 10),
        _serviceTile(
          booking?.brandName.isNotEmpty == true ? booking!.brandName : 'Brand',
          Icons.router_outlined,
          AppColors.success,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    return AppScaffold(
      title: 'Final Job Card',
      backgroundColor: AppColors.page,
      body: RefreshIndicator(
        onRefresh: _loadJobCardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: appPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                color: const Color(0xFFF8FBFF),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 58,
                      width: 58,
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.fact_check_outlined,
                        color: AppColors.accent,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Approval required',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Prepare an estimate before submitting to the user.',
                            style: TextStyle(
                              color: AppColors.muted,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const SectionTitle('Customer Details'),
              AppCard(
                child: Column(
                  children: [
                    AppInfoRow(
                      icon: Icons.person_outline,
                      label: 'Customer',
                      value: booking?.customerName.isNotEmpty == true
                          ? booking!.customerName
                          : 'Customer #${booking?.userId ?? ''}',
                    ),
                    const Divider(height: 22),
                    AppInfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Address',
                      value: booking?.address.isNotEmpty == true
                          ? booking!.address
                          : 'Address not available',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const SectionTitle('Original Issue'),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      children: _selectedIssues.isEmpty
                          ? _issues.map(_issueChip).toList()
                          : _selectedIssues.map(_issueChip).toList(),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _showOriginalIssueSelection,
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: Text(
                        _selectedIssues.length <= 1
                            ? 'Change Issue'
                            : 'Change Issues',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.border),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
              if (_hasExistingJobCard) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.edit_note_rounded, color: AppColors.accent),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Edit mode: update issues, note or parts, then save the job card again.',
                          style: TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              const SectionTitle('Technician Note'),
              AppCard(
                child: TextField(
                  controller: _observationController,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText:
                        'Write your diagnosis, required work and next step for customer approval...',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFD),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const SectionTitle('Recommended Service For'),
              _serviceInfoCard(booking),
              const SizedBox(height: 18),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Parts & Estimate',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: _isLoadingParts
                              ? null
                              : _showAddSolutionSelection,
                          icon: const Icon(Icons.add_rounded),
                          tooltip: 'Add part',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_isLoadingParts)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: SkeletonInlineLoader(labelWidth: 120),
                        ),
                      )
                    else if (_selectedSolutions.isEmpty)
                      const EmptyState(
                        icon: Icons.playlist_add_check_circle_outlined,
                        title: 'No part selected',
                        message:
                            'Parts are optional. Add a part only when the repair requires one.',
                      )
                    else
                      ..._selectedSolutions.map(_solutionRow),
                    const Divider(height: 26),
                    _estimateRow('Parts total', _partsTotal),
                    const SizedBox(height: 8),
                    _estimateRow(
                      'Current problem charge',
                      _selectedProblemTotal,
                    ),
                    if (_hasIssueChange) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFED7AA)),
                        ),
                        child: const Text(
                          'Diagnosis updated. The current problem charge is included in this job-card estimate; no earlier problem fee was deducted.',
                          style: TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                    const Divider(height: 22),
                    _estimateRow(
                      'Approval estimate',
                      _approvalEstimate,
                      bold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: _hasExistingJobCard
                    ? (_isSubmitting
                          ? 'Updating Job Card...'
                          : 'Update Job Card')
                    : _isSubmitting
                    ? 'Submitting Job Card...'
                    : 'Submit for User Approval',
                icon: _hasExistingJobCard
                    ? Icons.save_outlined
                    : Icons.send_outlined,
                onPressed: _isSubmitting ? null : _submitJobCard,
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Cancel / Exit Job Card',
                icon: Icons.close_rounded,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _issueDisplayName(String issue) {
    return issue
        .replaceFirst(RegExp(r'^Initial\s+Complaint\s*:\s*'), '')
        .trim();
  }
}

class _IssueOption {
  const _IssueOption({
    required this.label,
    required this.problemId,
    required this.price,
    this.problemTableId = '',
  });

  final String label;
  final String problemId;
  final String problemTableId;
  final int price;

  _IssueOption copyWith({
    String? problemId,
    String? problemTableId,
    int? price,
  }) {
    return _IssueOption(
      label: label,
      problemId: problemId ?? this.problemId,
      problemTableId: problemTableId ?? this.problemTableId,
      price: price ?? this.price,
    );
  }
}
