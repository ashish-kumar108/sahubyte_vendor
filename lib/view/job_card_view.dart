import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sahubyte_vendor/model/response/technician_enquiry_model.dart';
import 'package:sahubyte_vendor/view/app_ui.dart';
import 'package:sahubyte_vendor/view/final_job_card_view.dart';
import 'package:sahubyte_vendor/view_model/technician_view_model.dart';
import 'package:sahubyte_vendor/view_model/user_view_model.dart';
import 'package:url_launcher/url_launcher.dart';

class JobCardView extends StatefulWidget {
  const JobCardView({super.key, required this.booking});

  final TechnicianEnquiryModel booking;

  @override
  State<JobCardView> createState() => _JobCardViewState();
}

class _JobCardViewState extends State<JobCardView> {
  final _noteController = TextEditingController();
  final _userViewModel = UserViewModel();
  final _technicianViewModel = TechnicianViewModel();

  late String _category;
  late String _brand;
  late String _issue;
  late String _note;
  bool _isLoadingEditData = true;
  bool _isLoadingJobCard = true;
  Map<String, dynamic>? _createdJobCard;
  List<String> _categoryOptions = const [];
  List<String> _brandOptions = const [];
  List<String> _issueOptions = const [];

  @override
  void initState() {
    super.initState();
    final booking = widget.booking;
    _category = booking.categoryName.isEmpty ? 'Service' : booking.categoryName;
    _brand = booking.brandName.isEmpty ? 'Not specified' : booking.brandName;
    _issue = booking.problemSummary;
    _note = booking.problemDescription.isEmpty
        ? booking.problemSummary
        : booking.problemDescription;
    _noteController.text = _note;
    _loadEditDropdownData();
    _loadCreatedJobCard();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _userViewModel.dispose();
    _technicianViewModel.dispose();
    super.dispose();
  }

  Future<void> _loadCreatedJobCard() async {
    setState(() => _isLoadingJobCard = true);
    try {
      final jobCard = await _technicianViewModel.getJobCard(
        enquiryId: widget.booking.id,
      );
      if (!mounted) return;
      setState(() {
        _createdJobCard = _hasCreatedJobCard(jobCard) ? jobCard : null;
        _isLoadingJobCard = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingJobCard = false);
    }
  }

  bool _hasCreatedJobCard(Map<String, dynamic>? jobCard) {
    if (jobCard == null || jobCard.isEmpty) return false;
    final id = _firstJobValue(jobCard, const [
      'id',
      'jobCardId',
      'job_card_id',
      'enquiryId',
    ]);
    final details = _SavedJobCardSummaryCard.detailsFrom(jobCard);
    final parts = _SavedJobCardSummaryCard.partsFrom(jobCard);
    return id.isNotEmpty || details.isNotEmpty || parts.isNotEmpty;
  }

  Future<void> _loadEditDropdownData() async {
    setState(() => _isLoadingEditData = true);
    try {
      final responses = await Future.wait([
        _userViewModel.getData(tableName: 'category'),
        _userViewModel.getData(tableName: 'brand'),
        _userViewModel.getData(tableName: 'problem'),
      ]);
      if (!mounted) return;
      setState(() {
        _categoryOptions = _uniqueOptions([
          _category,
          ...responses[0].rows.map(
            (row) => _rowValue(row, const ['categoryName', 'name']),
          ),
        ]);
        _brandOptions = _uniqueOptions([
          _brand,
          ...responses[1].rows.map(
            (row) => _rowValue(row, const ['brandName', 'name']),
          ),
        ]);
        _issueOptions = _uniqueOptions([
          _issue,
          widget.booking.problemSummary,
          ...widget.booking.problemItems.map((item) => item.name),
          ...responses[2].rows.map(
            (row) => _rowValue(row, const [
              'problemName',
              'name',
              'title',
              'problem',
            ]),
          ),
        ]);
        _isLoadingEditData = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _categoryOptions = _uniqueOptions([_category]);
        _brandOptions = _uniqueOptions([_brand]);
        _issueOptions = _uniqueOptions([
          _issue,
          widget.booking.problemSummary,
          ...widget.booking.problemItems.map((item) => item.name),
        ]);
        _isLoadingEditData = false;
      });
    }
  }

  Future<void> _refreshJobCard() async {
    try {
      await Future.wait([_loadCreatedJobCard(), _loadEditDropdownData()]);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            professionalErrorMessage(
              error,
              fallback: 'Job card could not be refreshed. Please try again.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ignore: unused_element
  void _openEditSheet() {
    var category = _category;
    var brand = _brand;
    var issue = _issue;
    _noteController.text = _note;
    final categoryOptions = _uniqueOptions([_category, ..._categoryOptions]);
    final brandOptions = _uniqueOptions([_brand, ..._brandOptions]);
    final issueOptions = _uniqueOptions([_issue, ..._issueOptions]);

    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => StatefulBuilder(
          builder: (context, pageSetState) => AppScaffold(
            title: 'Edit Job Card',
            backgroundColor: AppColors.page,
            body: SafeArea(
              top: false,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primaryDark,
                                  Color(0xFF3D5A80),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF17233B,
                                  ).withValues(alpha: 0.16),
                                  blurRadius: 22,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      height: 54,
                                      width: 54,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.14,
                                          ),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.edit_note_rounded,
                                        color: Color(0xFFFFC58B),
                                        size: 30,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Refine job card',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${widget.booking.bookingCode} • ${widget.booking.statusLabel}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Color(0xCCFFFFFF),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _editSummaryChip(
                                      Icons.home_repair_service_outlined,
                                      widget.booking.serviceTitle,
                                    ),
                                    _editSummaryChip(
                                      Icons.payments_outlined,
                                      'Rs. ${widget.booking.amount}',
                                    ),
                                    _editSummaryChip(
                                      Icons.schedule_rounded,
                                      widget.booking.dateTimeSlot.isEmpty
                                          ? widget.booking.createdAt
                                          : widget.booking.dateTimeSlot,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (_isLoadingEditData) ...[
                            const AppCard(
                              padding: EdgeInsets.all(14),
                              child: SkeletonInlineLoader(labelWidth: 160),
                            ),
                            const SizedBox(height: 16),
                          ],
                          AppCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _editSectionTitle(
                                  'Service classification',
                                  'Choose corrected service data from master records.',
                                ),
                                const SizedBox(height: 14),
                                _editDropdown(
                                  value: category,
                                  label: 'Category',
                                  icon: Icons.category_outlined,
                                  items: categoryOptions,
                                  onChanged: (value) =>
                                      pageSetState(() => category = value),
                                ),
                                const SizedBox(height: 12),
                                _editDropdown(
                                  value: brand,
                                  label: 'Brand',
                                  icon: Icons.devices_outlined,
                                  items: brandOptions,
                                  onChanged: (value) =>
                                      pageSetState(() => brand = value),
                                ),
                                const SizedBox(height: 12),
                                _editDropdown(
                                  value: issue,
                                  label: 'Issue type',
                                  icon: Icons.report_problem_outlined,
                                  items: issueOptions,
                                  onChanged: (value) =>
                                      pageSetState(() => issue = value),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          AppCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _editSectionTitle(
                                  'Technician observation',
                                  'Add concise notes for the job card workflow.',
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller: _noteController,
                                  maxLines: 6,
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(
                                      Icons.notes_outlined,
                                    ),
                                    labelText: 'Problem description',
                                    alignLabelWithHint: true,
                                    filled: true,
                                    fillColor: AppColors.page,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: const BorderSide(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: const BorderSide(
                                        color: AppColors.accent,
                                        width: 1.3,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: _editSaveButton(
                      label: 'Save Changes',
                      icon: Icons.save_outlined,
                      onPressed: () {
                        setState(() {
                          _category = category.trim().isEmpty
                              ? _category
                              : category.trim();
                          _brand = brand.trim().isEmpty ? _brand : brand.trim();
                          _issue = issue.trim().isEmpty ? _issue : issue.trim();
                          final text = _noteController.text.trim();
                          if (text.isNotEmpty) _note = text;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _editSummaryChip(IconData icon, String label) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 245),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFFFC58B), size: 15),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label.isEmpty ? 'Not available' : label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editSectionTitle(String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.tune_rounded,
            color: AppColors.accent,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11.5,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _editSaveButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 19),
        label: Text(label, overflow: TextOverflow.ellipsis),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  List<String> _uniqueOptions(Iterable<String> values) {
    final seen = <String>{};
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty && value.toLowerCase() != 'null')
        .where((value) => seen.add(value.toLowerCase()))
        .toList();
  }

  String _rowValue(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'null') return value;
    }
    return '';
  }

  String _firstJobValue(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'null') return value;
    }
    return '';
  }

  Widget _editDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    final normalizedItems = _uniqueOptions([value, ...items]);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3264).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        initialValue: normalizedItems.contains(value) ? value : null,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.accent),
          labelText: label,
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.3),
          ),
        ),
        items: normalizedItems
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            )
            .toList(),
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      ),
    );
  }

  Widget _detailCard({
    required IconData icon,
    required String label,
    required String value,
    required Color tint,
  }) {
    return Container(
      height: 86,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tint.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3264).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: tint, size: 20),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.isEmpty ? 'Not available' : value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _attachmentCard() {
    final attachments = widget.booking.attachments;
    if (attachments.isEmpty) {
      return Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primarySoft,
              child: Icon(Icons.hide_image_outlined, color: AppColors.primary),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No customer attachment found in this enquiry.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final item = attachments.first;
    final type = item.type.isEmpty ? 'Attachment' : item.type;
    return GestureDetector(
      onTap: () => _openAttachment(item),
      child: Container(
        height: 68,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _attachmentPreview(item),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    attachments.length > 1
                        ? '$type • ${attachments.length} files'
                        : '$type • Tap to open',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              item.isVideo
                  ? Icons.play_circle_fill_rounded
                  : Icons.open_in_full_rounded,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _jobActionButton({
    required String label,
    required IconData icon,
    required bool filled,
    required VoidCallback? onPressed,
  }) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    );
    final textStyle = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w900,
    );
    if (filled) {
      return SizedBox(
        height: 50,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label, overflow: TextOverflow.ellipsis),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            textStyle: textStyle,
            shape: shape,
          ),
        ),
      );
    }
    return SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label, overflow: TextOverflow.ellipsis),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: AppColors.primary.withValues(alpha: 0.06),
          side: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.34),
            width: 1.4,
          ),
          textStyle: textStyle,
          shape: shape,
        ),
      ),
    );
  }

  Future<void> _openAttachment(TechnicianAttachmentItem item) async {
    final resolvedUrl = _resolveAttachmentUrl(item.url);
    if (!item.isVideo &&
        (resolvedUrl.startsWith('data:image') ||
            resolvedUrl.startsWith('http'))) {
      _showImagePreview(resolvedUrl, item.name);
      return;
    }
    if (item.isVideo) {
      await _openVideoAttachment(resolvedUrl);
      return;
    }
    await _launchAttachmentUrl(resolvedUrl);
  }

  Future<void> _openVideoAttachment(String url) async {
    try {
      if (url.startsWith('data:video')) {
        final commaIndex = url.indexOf(',');
        if (commaIndex == -1) {
          throw const FormatException('Invalid video data.');
        }
        final bytes = base64Decode(url.substring(commaIndex + 1));
        final file = await _writeVideoBytes(
          bytes,
          _videoExtensionFromData(url),
        );
        final result = await OpenFilex.open(file.path);
        if (result.type != ResultType.done) {
          _showAttachmentError('Unable to open video.');
        }
        return;
      }

      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme) {
        _showAttachmentError('Attachment URL is not valid.');
        return;
      }
      final response = await http
          .get(uri, headers: const {'User-Agent': 'Mozilla/5.0'})
          .timeout(const Duration(seconds: 30));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Video download failed.');
      }
      final file = await _writeVideoBytes(
        response.bodyBytes,
        _videoExtensionFromPath(uri.path),
      );
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        _showAttachmentError('Unable to open video.');
      }
    } catch (_) {
      _showAttachmentError('Unable to open video.');
    }
  }

  Future<File> _writeVideoBytes(List<int> bytes, String extension) async {
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/sahubyte_vendor_video_${DateTime.now().millisecondsSinceEpoch}.$extension',
    );
    return file.writeAsBytes(bytes, flush: true);
  }

  String _videoExtensionFromData(String url) {
    final header = url.split(',').first.toLowerCase().replaceAll('data:', '');
    if (header.contains('webm')) return 'webm';
    if (header.contains('quicktime') || header.contains('mov')) return 'mov';
    if (header.contains('m4v')) return 'm4v';
    return 'mp4';
  }

  String _videoExtensionFromPath(String path) {
    final value = path.toLowerCase();
    if (value.endsWith('.webm')) return 'webm';
    if (value.endsWith('.mov')) return 'mov';
    if (value.endsWith('.m4v')) return 'm4v';
    return 'mp4';
  }

  Future<void> _launchAttachmentUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      _showAttachmentError('Attachment URL is not valid.');
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) _showAttachmentError('Unable to open attachment.');
  }

  void _showImagePreview(String url, String title) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (context) {
        final image = url.startsWith('data:image')
            ? Image.memory(
                base64Decode(url.split(',').last),
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white,
                  size: 52,
                ),
              )
            : Image.network(
                url,
                fit: BoxFit.contain,
                headers: const {'User-Agent': 'Mozilla/5.0'},
                errorBuilder: (_, _, _) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white,
                  size: 52,
                ),
              );
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: InteractiveViewer(
                    minScale: 0.7,
                    maxScale: 4,
                    child: Center(child: image),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAttachmentError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _attachmentPreview(TechnicianAttachmentItem item) {
    final resolvedUrl = _resolveAttachmentUrl(item.url);
    final borderRadius = BorderRadius.circular(8);
    final placeholder = Container(
      height: 58,
      width: 58,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: borderRadius,
      ),
      child: Icon(
        item.isVideo ? Icons.play_circle_outline_rounded : Icons.image_outlined,
        color: AppColors.muted,
      ),
    );

    if (item.isVideo) return placeholder;
    if (resolvedUrl.startsWith('data:image')) {
      try {
        final data = resolvedUrl.split(',').last;
        return ClipRRect(
          borderRadius: borderRadius,
          child: Image.memory(
            base64Decode(data),
            height: 58,
            width: 58,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => placeholder,
          ),
        );
      } catch (_) {
        return placeholder;
      }
    }
    if (resolvedUrl.startsWith('http')) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Image.network(
          resolvedUrl,
          height: 58,
          width: 58,
          fit: BoxFit.cover,
          headers: const {'User-Agent': 'Mozilla/5.0'},
          errorBuilder: (_, _, _) => placeholder,
        ),
      );
    }
    return placeholder;
  }

  String _resolveAttachmentUrl(String raw) {
    final value = raw.trim();
    if (value.isEmpty ||
        value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('data:')) {
      return value;
    }
    final normalized = value
        .replaceAll('\\', '/')
        .replaceFirst(RegExp(r'^/+'), '');
    if (normalized.startsWith('public/')) {
      return 'https://techcanopusdemo.com/sahubyte/$normalized';
    }
    if (normalized.startsWith('uploads/enquiries/')) {
      return 'https://techcanopusdemo.com/sahubyte/$normalized';
    }
    if (normalized.startsWith('uploads/')) {
      return 'https://techcanopusdemo.com/sahubyte/public/$normalized';
    }
    return 'https://techcanopusdemo.com/sahubyte/public/uploads/$normalized';
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final canCreateJobCard = booking.statusLabel == 'Job Card';
    final createdJobCard = _createdJobCard;
    final canOpenJobCard = canCreateJobCard || createdJobCard != null;
    return AppScaffold(
      title: 'Job Card',
      backgroundColor: AppColors.page,
      actions: const [],
      body: RefreshIndicator(
        onRefresh: _refreshJobCard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.surface, AppColors.primarySoft],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A3264).withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.assignment_outlined,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Technician job card',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'JC-${booking.id.padLeft(6, '0')}',
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        StatusPill(
                          label: booking.statusLabel,
                          color: AppColors.warning,
                          icon: Icons.schedule_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${booking.bookingCode} | ${booking.dateTimeSlot.isEmpty ? booking.createdAt : booking.dateTimeSlot}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 12.5,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _detailCard(
                      icon: Icons.person_outline,
                      label: 'Customer',
                      value: booking.customerName.isEmpty
                          ? 'Customer #${booking.userId}'
                          : booking.customerName,
                      tint: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _detailCard(
                      icon: Icons.category_outlined,
                      label: 'Category',
                      value: _category,
                      tint: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _detailCard(
                      icon: Icons.devices_outlined,
                      label: 'Brand',
                      value: _brand,
                      tint: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _detailCard(
                      icon: Icons.report_problem_outlined,
                      label: 'Reported Issue',
                      value: _issue,
                      tint: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Problem Description',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(
                  minHeight: 72,
                  maxHeight: 150,
                ),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  _note.isEmpty ? 'Problem description not available.' : _note,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    height: 1.35,
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Customer Attachment',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              _attachmentCard(),
              const SizedBox(height: 10),
              if (_isLoadingJobCard) ...[
                const AppCard(
                  padding: EdgeInsets.all(14),
                  child: SkeletonInlineLoader(labelWidth: 190),
                ),
                const SizedBox(height: 10),
              ] else if (createdJobCard != null) ...[
                _SavedJobCardSummaryCard(jobCard: createdJobCard),
                const SizedBox(height: 10),
              ],
              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: _jobActionButton(
                    label: createdJobCard == null
                        ? 'Create / Edit Job Card'
                        : 'View / Edit Job Card',
                    icon: Icons.edit_note_rounded,
                    filled: true,
                    onPressed: canOpenJobCard
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    FinalJobCardView(booking: booking),
                              ),
                            );
                          }
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedJobCardSummaryCard extends StatelessWidget {
  const _SavedJobCardSummaryCard({required this.jobCard});

  final Map<String, dynamic> jobCard;

  static List<Map<String, dynamic>> partsFrom(Map<String, dynamic> jobCard) {
    final source = jobCard['parts'] ?? jobCard['part'] ?? jobCard['items'];
    dynamic parsed = source;
    if (source is String && source.trim().isNotEmpty) {
      try {
        parsed = jsonDecode(source);
      } catch (_) {}
    }
    if (parsed is! List) return const [];
    return parsed
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) => _first(item, const ['partName', 'name']).isNotEmpty)
        .toList();
  }

  static Map<String, dynamic> detailsJson(Map<String, dynamic> jobCard) {
    final raw =
        jobCard['details']?.toString().trim() ??
        jobCard['description']?.toString().trim() ??
        '';
    if (raw.isEmpty) return const {};
    try {
      final parsed = jsonDecode(raw);
      if (parsed is Map) return Map<String, dynamic>.from(parsed);
    } catch (_) {}
    return const {};
  }

  static String detailsFrom(Map<String, dynamic> jobCard) {
    final parsed = detailsJson(jobCard);
    final note =
        parsed['technicianObservation'] ??
        parsed['technicianNote'] ??
        parsed['observation'] ??
        parsed['problemDescription'] ??
        parsed['details'] ??
        parsed['description'];
    if (note != null && note.toString().trim().isNotEmpty) {
      return note.toString().trim();
    }
    final fallback = jobCard['details'] ?? jobCard['description'];
    return fallback?.toString().trim() ?? '';
  }

  static List<String> selectedIssuesFrom(Map<String, dynamic> jobCard) {
    final details = detailsJson(jobCard);
    final source = details['selectedIssues'] ?? details['issues'];
    if (source is! List) return const [];
    return source
        .map((item) => _cleanIssueName(item.toString()))
        .where((item) => item.isNotEmpty && item.toLowerCase() != 'null')
        .toList();
  }

  static Map<String, dynamic> problemChangeFrom(Map<String, dynamic> jobCard) {
    final details = detailsJson(jobCard);
    final detailChange = details['problemChange'];
    if (detailChange is Map) return Map<String, dynamic>.from(detailChange);

    final raw =
        jobCard['problemChangeDetails'] ??
        details['problemChangeDetails'] ??
        jobCard['problemChange'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final parsed = jsonDecode(raw);
        if (parsed is Map) return Map<String, dynamic>.from(parsed);
      } catch (_) {}
    }
    return const {};
  }

  static String _first(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'null') return value;
    }
    return '';
  }

  static String _cleanIssueName(String value) {
    return value
        .replaceFirst(RegExp(r'^Initial\s+Complaint\s*:\s*'), '')
        .trim();
  }

  static int _price(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    final text = raw?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '';
    return double.tryParse(text)?.round() ?? 0;
  }

  static bool _bool(dynamic raw) {
    final value = raw?.toString().trim().toLowerCase() ?? '';
    return value == 'true' || value == '1' || value == 'yes';
  }

  static int partsTotalFrom(Map<String, dynamic> jobCard) {
    return partsFrom(jobCard).fold<int>(
      0,
      (sum, item) => sum + _price(item['price'] ?? item['amount']),
    );
  }

  int get _approvalEstimate {
    final details = detailsJson(jobCard);
    final change = problemChangeFrom(jobCard);
    final problemCharge = _price(
      details['problemCharge'] ??
          details['newProblemPrice'] ??
          change['newProblemPrice'] ??
          change['currentProblemPrice'],
    );
    if (problemCharge > 0) {
      return partsTotalFrom(jobCard) + problemCharge;
    }
    final directTotal = _price(
      details['approvalEstimate'] ??
          details['estimateTotal'] ??
          jobCard['totalPrice'] ??
          jobCard['total'] ??
          jobCard['amount'],
    );
    if (directTotal > 0) return directTotal;
    return partsTotalFrom(jobCard) + problemCharge;
  }

  @override
  Widget build(BuildContext context) {
    final parts = partsFrom(jobCard);
    final note = detailsFrom(jobCard);
    final details = detailsJson(jobCard);
    final issues = selectedIssuesFrom(jobCard);
    final change = problemChangeFrom(jobCard);
    final changedProblem = _first(change, const [
      'changedProblemName',
      'newProblemName',
      'problemName',
    ]);
    final issueChanged =
        _bool(details['issueChanged']) || changedProblem.isNotEmpty;
    final currentProblemPrice = _price(
      details['problemCharge'] ??
          details['newProblemPrice'] ??
          change['newProblemPrice'] ??
          change['newProblemTotal'] ??
          change['currentProblemPrice'],
    );

    return AppCard(
      color: const Color(0xFFFFFBF7),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.fact_check_outlined,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saved job card',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Parts, note and updated diagnosis from vendor.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoBox(
              icon: Icons.sticky_note_2_outlined,
              title: 'Technician note',
              child: Text(
                note,
                style: const TextStyle(
                  color: AppColors.text,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          if (issueChanged) ...[
            const SizedBox(height: 10),
            _InfoBox(
              icon: Icons.tips_and_updates_outlined,
              title: 'Updated problem',
              tint: AppColors.warning,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (issues.isNotEmpty)
                    ...issues.map(
                      (issue) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '• ',
                              style: TextStyle(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                issue,
                                style: const TextStyle(
                                  color: AppColors.text,
                                  height: 1.25,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (changedProblem.isNotEmpty)
                    Text(
                      changedProblem,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          const Text(
            'Parts & estimate',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          if (parts.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'No parts are required for this job card.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            ...parts.map((part) {
              final name = _first(part, const ['partName', 'name']);
              final price = _price(part['price'] ?? part['amount']);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 34,
                        width: 34,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: AppColors.success,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rs. $price',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const Divider(height: 18),
          _moneyRow('Parts total', partsTotalFrom(jobCard)),
          _moneyRow('Current problem charge', currentProblemPrice),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Approval estimate',
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                'Rs. $_approvalEstimate',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _moneyRow(String label, int value) {
    if (value <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            'Rs. $value',
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.icon,
    required this.title,
    required this.child,
    this.tint = AppColors.primary,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: tint.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: tint, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
