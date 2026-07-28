import 'dart:convert';

class TechnicianProblemItem {
  const TechnicianProblemItem({
    required this.id,
    required this.problemTableId,
    required this.name,
    required this.price,
  });

  final String id;
  final String problemTableId;
  final String name;
  final int price;

  factory TechnicianProblemItem.fromJson(Map<String, dynamic> json) {
    final problemId = _stringFrom(json, const ['problemId', 'problem_id']);
    return TechnicianProblemItem(
      id: problemId.isNotEmpty ? problemId : _stringFrom(json, const ['id']),
      problemTableId: _stringFrom(json, const [
        'problemTableId',
        'problemTable_id',
        'enquiryProblemId',
        'enquiryProblem_id',
        'enquiryProblemDetailId',
        'enquiryProblemDetail_id',
        'tableId',
        'rowId',
        'id',
      ]),
      name: _stringFrom(json, const ['problemName', 'name', 'title']),
      price: TechnicianEnquiryModel._toInt(json['price']),
    );
  }
}

class TechnicianAttachmentItem {
  const TechnicianAttachmentItem({required this.url, required this.type});

  final String url;
  final String type;
  String get name => _fileName(url);
  bool get isVideo => type.toLowerCase().contains('video') || _looksVideo(url);
  bool get isImage => !isVideo;

  factory TechnicianAttachmentItem.fromJson(Map<String, dynamic> json) {
    return TechnicianAttachmentItem(
      url: _stringFrom(json, const [
        'url',
        'file',
        'filePath',
        'path',
        'attachment',
        'document',
        'document1',
        'document2',
        'image',
        'video',
        'media',
      ]),
      type: _stringFrom(json, const [
        'type',
        'fileType',
        'documentType',
        'document1Type',
        'document2Type',
      ]),
    );
  }
}

class TechnicianEnquiryModel {
  const TechnicianEnquiryModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.subCategoryId,
    required this.brandId,
    required this.categoryName,
    required this.subCategoryName,
    required this.brandName,
    required this.dateTimeSlot,
    required this.address,
    required this.state,
    required this.serviceFee,
    required this.tax,
    required this.totalPrice,
    required this.status,
    required this.workConfirmation,
    required this.technicianStatus,
    required this.details,
    required this.createdAt,
    required this.customerName,
    required this.customerMobile,
    required this.customerEmail,
    required this.problemItems,
    required this.attachments,
    this.oldProblemPrice = 0,
    this.newProblemPrice = 0,
    this.problemAdjustmentAmount = 0,
    this.problemAdditionalAmount = 0,
    this.changedProblemName = '',
    this.paymentType = '',
    this.paymentStatus = '',
  });

  final String id;
  final String userId;
  final String categoryId;
  final String subCategoryId;
  final String brandId;
  final String categoryName;
  final String subCategoryName;
  final String brandName;
  final String dateTimeSlot;
  final String address;
  final String state;
  final int serviceFee;
  final int tax;
  final int totalPrice;
  final String status;
  final String workConfirmation;
  final String technicianStatus;
  final String details;
  final String createdAt;
  final String customerName;
  final String customerMobile;
  final String customerEmail;
  final List<TechnicianProblemItem> problemItems;
  final List<TechnicianAttachmentItem> attachments;
  final int oldProblemPrice;
  final int newProblemPrice;
  final int problemAdjustmentAmount;
  final int problemAdditionalAmount;
  final String changedProblemName;
  final String paymentType;
  final String paymentStatus;

  factory TechnicianEnquiryModel.fromJson(Map<String, dynamic> json) {
    final detailsText = json['details']?.toString() ?? '';
    final detailsJson = _jsonMap(detailsText);
    final problemChange = _firstMap(json, const [
      'problemChangeDetails',
      'problemChange',
      'problem_change_details',
      'problem_change',
    ]);
    final userJson = _firstMap(json, const [
      'user',
      'userData',
      'userDetail',
      'customer',
      'customerData',
      'client',
      'clientData',
    ]);
    return TechnicianEnquiryModel(
      id: _stringFrom(json, const ['enquiryId', 'enquiry_id', 'id']),
      userId: _stringFrom(json, const ['userId', 'customerId']),
      categoryId: _stringFrom(json, const ['categoryId']),
      subCategoryId: _stringFrom(json, const [
        'subCategoryId',
        'subcategoryId',
      ]),
      brandId: _stringFrom(json, const ['brandId']),
      categoryName: _stringFrom(json, const ['categoryName']),
      subCategoryName: _stringFrom(json, const [
        'subCategoryName',
        'subcategoryName',
      ]),
      brandName: _stringFrom(json, const ['brandName']),
      dateTimeSlot: _stringFrom(json, const [
        'dateTimeSlot',
        'appointmentSlot',
        'slot',
      ]),
      address: _stringFrom(json, const ['address', 'serviceAddress']),
      state: _stringFrom(json, const ['state']),
      serviceFee: _toInt(json['serviceFee']),
      tax: _toInt(json['tax']),
      totalPrice: _toInt(json['totalPrice']),
      status: _stringFrom(json, const ['status']),
      workConfirmation: _stringFrom(json, const ['workConfirmation']),
      technicianStatus: _stringFrom(json, const ['technicianStatus']),
      details: detailsText,
      createdAt: _stringFrom(json, const ['createdAt', 'created_at']),
      customerName: _firstString([
        _stringFrom(json, const [
          'userName',
          'customerName',
          'customer_name',
          'clientName',
          'name',
          'fullName',
        ]),
        _stringFrom(userJson, const ['name', 'fullName', 'userName']),
      ]),
      customerMobile: _firstString([
        _stringFrom(json, const [
          'mobile',
          'userMobile',
          'customerMobile',
          'customer_mobile',
          'clientMobile',
          'phone',
          'phoneNumber',
          'mobileNumber',
        ]),
        _stringFrom(userJson, const [
          'mobile',
          'phone',
          'phoneNumber',
          'mobileNumber',
        ]),
      ]),
      customerEmail: _firstString([
        _stringFrom(json, const [
          'email',
          'userEmail',
          'customerEmail',
          'customer_email',
          'clientEmail',
        ]),
        _stringFrom(userJson, const ['email', 'userEmail']),
      ]),
      problemItems: _parseProblems(json),
      attachments: _parseAttachments(json, detailsJson),
      oldProblemPrice: _toInt(
        problemChange['oldProblemPrice'] ??
            problemChange['oldProblemTotal'] ??
            problemChange['previousProblemPrice'] ??
            json['oldProblemPrice'] ??
            json['oldProblemTotal'] ??
            json['previousProblemPrice'],
      ),
      newProblemPrice: _toInt(
        problemChange['newProblemPrice'] ??
            problemChange['newProblemTotal'] ??
            problemChange['currentProblemPrice'] ??
            json['newProblemPrice'] ??
            json['newProblemTotal'] ??
            json['currentProblemPrice'],
      ),
      problemAdjustmentAmount: _toInt(
        problemChange['problemAdjustmentAmount'] ??
            problemChange['adjustmentAmount'] ??
            problemChange['adjustedAmount'] ??
            json['problemAdjustmentAmount'] ??
            json['adjustmentAmount'] ??
            json['adjustedAmount'],
      ),
      problemAdditionalAmount: _toInt(
        problemChange['problemAdditionalAmount'] ??
            problemChange['additionalAmount'] ??
            problemChange['extraAmount'] ??
            json['problemAdditionalAmount'] ??
            json['additionalAmount'] ??
            json['extraAmount'],
      ),
      changedProblemName:
          problemChange['changedProblemName']?.toString() ??
          problemChange['newProblemName']?.toString() ??
          json['changedProblemName']?.toString() ??
          json['newProblemName']?.toString() ??
          '',
      paymentType: _stringFrom(json, const ['paymentType', 'payment_type']),
      paymentStatus: _stringFrom(json, const [
        'paymentStatus',
        'payment_status',
      ]),
    );
  }

  TechnicianEnquiryModel copyWith({
    String? customerName,
    String? customerMobile,
    String? customerEmail,
    List<TechnicianAttachmentItem>? attachments,
    int? oldProblemPrice,
    int? newProblemPrice,
    int? problemAdjustmentAmount,
    int? problemAdditionalAmount,
    String? changedProblemName,
    String? paymentType,
    String? paymentStatus,
  }) {
    return TechnicianEnquiryModel(
      id: id,
      userId: userId,
      categoryId: categoryId,
      subCategoryId: subCategoryId,
      brandId: brandId,
      categoryName: categoryName,
      subCategoryName: subCategoryName,
      brandName: brandName,
      dateTimeSlot: dateTimeSlot,
      address: address,
      state: state,
      serviceFee: serviceFee,
      tax: tax,
      totalPrice: totalPrice,
      status: status,
      workConfirmation: workConfirmation,
      technicianStatus: technicianStatus,
      details: details,
      createdAt: createdAt,
      customerName: customerName ?? this.customerName,
      customerMobile: customerMobile ?? this.customerMobile,
      customerEmail: customerEmail ?? this.customerEmail,
      problemItems: problemItems,
      attachments: attachments ?? this.attachments,
      oldProblemPrice: oldProblemPrice ?? this.oldProblemPrice,
      newProblemPrice: newProblemPrice ?? this.newProblemPrice,
      problemAdjustmentAmount:
          problemAdjustmentAmount ?? this.problemAdjustmentAmount,
      problemAdditionalAmount:
          problemAdditionalAmount ?? this.problemAdditionalAmount,
      changedProblemName: changedProblemName ?? this.changedProblemName,
      paymentType: paymentType ?? this.paymentType,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }

  String get bookingCode => id.isEmpty ? 'SB-NEW' : 'SB-${id.padLeft(6, '0')}';

  String get serviceTitle {
    final parts = [
      categoryName,
      subCategoryName,
      brandName,
    ].where((value) => value.trim().isNotEmpty).toList();
    return parts.isEmpty ? 'Service enquiry' : parts.join(' / ');
  }

  String get statusLabel {
    final normalized = status.trim().toLowerCase();
    final tech = technicianStatus.trim().toLowerCase();
    if (normalized.isEmpty || normalized == '0' || normalized == 'pending') {
      return 'New';
    }
    if (tech == '7' || tech == 'reallocated') return 'Reallocated';
    if (normalized == '5' ||
        normalized == 'expired' ||
        normalized == 'rejected' ||
        normalized == 'cancelled' ||
        normalized == 'canceled') {
      return 'Expired';
    }
    if (tech == '3' || tech == 'inspection') return 'Inspection';
    if (tech == '2' || tech == 'arrived') return 'Arrived';
    if (tech == '1' || tech == 'on the way' || tech == 'on_the_way') {
      return 'On The Way';
    }
    if (tech == '4' || tech == 'job card' || tech == 'job_card') {
      return 'Job Card';
    }
    if (tech == '5' || tech == 'job started' || tech == 'job_started') {
      return 'Job Started';
    }
    if (tech == '6' || tech == 'job completed' || tech == 'job_completed') {
      return 'Job Completed';
    }
    if (normalized == '1' ||
        normalized == 'accepted' ||
        normalized == 'confirmed') {
      return 'Accepted';
    }
    if (normalized == '2' ||
        normalized == 'starting' ||
        normalized == 'start' ||
        normalized == 'started') {
      return 'Starting';
    }
    if (normalized == '3' ||
        normalized == 'in-progress' ||
        normalized == 'in_progress' ||
        normalized == 'inprogress' ||
        normalized == 'active' ||
        normalized == 'ongoing') {
      return 'In-progress';
    }
    if (normalized == '4' ||
        normalized == 'completed' ||
        normalized == 'done') {
      return 'Completed';
    }
    return status;
  }

  int get amount => totalPrice > 0 ? totalPrice : serviceFee + tax;

  String get problemDescription {
    final detailsJson = _jsonMap(details);
    final value = _stringFrom(detailsJson, const [
      'problemDescription',
      'description',
      'note',
      'details',
    ]);
    if (value.isNotEmpty) return value;
    return details.trim();
  }

  String get problemSummary {
    final names = problemItems
        .map((problem) => problem.name)
        .where((name) => name.trim().isNotEmpty)
        .toList();
    return names.isEmpty ? 'Problem details not available' : names.join(', ');
  }

  int get problemFee =>
      problemItems.fold<int>(0, (sum, problem) => sum + problem.price);

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static Map<String, dynamic> _jsonMap(String value) {
    if (value.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(value);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  static List<TechnicianProblemItem> _parseProblems(Map<String, dynamic> json) {
    final source = _firstValue(json, const [
      'problemDetails',
      'enquiryProblemDetails',
      'enquiryProblems',
      'problems',
      'problem',
    ]);
    final list = _asList(source);
    return list
        .whereType<Map>()
        .map((item) => TechnicianProblemItem.fromJson(Map.from(item)))
        .where((problem) => problem.id.isNotEmpty || problem.name.isNotEmpty)
        .toList();
  }

  static List<TechnicianAttachmentItem> _parseAttachments(
    Map<String, dynamic> json,
    Map<String, dynamic> detailsJson,
  ) {
    final list = <TechnicianAttachmentItem>[];

    void add(dynamic source, {String? type}) {
      final url = source?.toString().trim() ?? '';
      if (url.isEmpty || url.toLowerCase() == 'null') return;
      final normalizedType = type?.trim().isNotEmpty == true
          ? type!.trim()
          : (_looksVideo(url) ? 'video' : 'image');
      list.add(TechnicianAttachmentItem(url: url, type: normalizedType));
    }

    for (final key in const [
      'document',
      'document1',
      'document2',
      'document3',
      'documentUrl',
      'attachment',
      'attachmentUrl',
      'attachment1',
      'attachment2',
      'file',
      'filePath',
      'path',
      'url',
      'file1',
      'file2',
      'image',
      'image1',
      'image2',
      'video',
      'video1',
      'video2',
      'media',
      'mediaUrl',
    ]) {
      final value = _firstString([
        _stringFrom(json, [key]),
        _stringFrom(detailsJson, [key]),
      ]);
      if (value.isNotEmpty) {
        add(
          value,
          type: _firstString([
            _stringFrom(json, ['${key}Type']),
            _stringFrom(detailsJson, ['${key}Type']),
          ]),
        );
      }
    }

    for (final key in const [
      'attachments',
      'enquriesAttachment',
      'enquiriesAttachment',
      'enquiryAttachments',
      'enquiryAttachment',
      'documents',
      'files',
      'media',
    ]) {
      _collectAttachmentValue(json[key], add);
      _collectAttachmentValue(detailsJson[key], add);
    }

    final seen = <String>{};
    return list.where((item) => seen.add(item.url)).toList();
  }

  static void _collectAttachmentValue(
    dynamic value,
    void Function(dynamic source, {String? type}) add,
  ) {
    if (value == null) return;
    if (value is List) {
      for (final item in value) {
        _collectAttachmentValue(item, add);
      }
      return;
    }
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      add(
        map['document'] ??
            map['document1'] ??
            map['file'] ??
            map['filePath'] ??
            map['url'] ??
            map['path'] ??
            map['attachment'] ??
            map['attachmentUrl'] ??
            map['documentUrl'] ??
            map['image'] ??
            map['video'] ??
            map['media'] ??
            map['mediaUrl'],
        type:
            map['type']?.toString() ??
            map['fileType']?.toString() ??
            map['documentType']?.toString() ??
            map['document1Type']?.toString(),
      );
      return;
    }
    final text = value.toString().trim();
    if (text.startsWith('[') || text.startsWith('{')) {
      try {
        _collectAttachmentValue(jsonDecode(text), add);
        return;
      } catch (_) {}
    }
    add(text);
  }

  static List<dynamic> _asList(dynamic value) {
    if (value is List) return value;
    if (value is Map) return [value];
    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) return decoded;
        if (decoded is Map) return [decoded];
      } catch (_) {}
    }
    return const [];
  }
}

dynamic _firstValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key) && json[key] != null) return json[key];
  }
  return null;
}

String _stringFrom(Map<String, dynamic> json, List<String> keys) {
  final value = _firstValue(json, keys);
  return value?.toString().trim() ?? '';
}

String _firstString(List<String> values) {
  for (final value in values) {
    if (value.trim().isNotEmpty && value.trim().toLowerCase() != 'null') {
      return value.trim();
    }
  }
  return '';
}

Map<String, dynamic> _firstMap(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String && value.trim().startsWith('{')) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
  }
  return const {};
}

bool _looksVideo(String value) {
  final text = value.toLowerCase();
  return text.startsWith('data:video') ||
      text.endsWith('.mp4') ||
      text.endsWith('.mov') ||
      text.endsWith('.avi') ||
      text.endsWith('.mkv') ||
      text.contains('/video/');
}

String _fileName(String value) {
  if (value.startsWith('data:')) return _looksVideo(value) ? 'Video' : 'Photo';
  final clean = value.split('?').first.split('/').last.trim();
  return clean.isEmpty ? 'Attachment' : clean;
}
