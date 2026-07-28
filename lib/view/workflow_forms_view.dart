import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sahubyte_vendor/view/app_ui.dart';

class ReallocationNoteView extends StatefulWidget {
  const ReallocationNoteView({super.key, required this.bookingCode});

  final String bookingCode;

  @override
  State<ReallocationNoteView> createState() => _ReallocationNoteViewState();
}

class _ReallocationNoteViewState extends State<ReallocationNoteView> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(context, _noteController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Reallocate Booking',
      backgroundColor: AppColors.page,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: appPadding,
          children: [
            AppCard(
              child: Row(
                children: [
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEC4899).withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.sync_problem_rounded,
                      color: Color(0xFFEC4899),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reason for reallocation',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.bookingCode,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SectionTitle('Vendor Note'),
            AppCard(
              child: TextFormField(
                controller: _noteController,
                minLines: 5,
                maxLines: 8,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText:
                      'Explain why this booking should be assigned to another technician...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final note = value?.trim() ?? '';
                  if (note.isEmpty) return 'Please enter a reallocation note.';
                  if (note.length < 10) {
                    return 'Please provide a little more detail.';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Save Note & Reallocate'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InspectionImagesView extends StatefulWidget {
  const InspectionImagesView({super.key, required this.bookingCode});

  final String bookingCode;

  @override
  State<InspectionImagesView> createState() => _InspectionImagesViewState();
}

class _InspectionImagesViewState extends State<InspectionImagesView> {
  final _picker = ImagePicker();
  final List<Uint8List?> _images = List<Uint8List?>.filled(4, null);
  bool _isPicking = false;

  int get _imageCount => _images.whereType<Uint8List>().length;

  Future<void> _pickImage(int index, ImageSource source) async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 72,
        maxWidth: 1400,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() => _images[index] = bytes);
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _showSourcePicker(int index) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add inspection photo',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take photo'),
                subtitle: const Text('Open camera for a new inspection photo'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(index, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                subtitle: const Text('Select an existing photo'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(index, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    final selected = _images.whereType<Uint8List>().toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one inspection image.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      selected.map((bytes) => base64Encode(bytes)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Service Inspection',
      backgroundColor: AppColors.page,
      body: ListView(
        padding: appPadding,
        children: [
          AppCard(
            child: Row(
              children: [
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: .11),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.fact_check_outlined,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Document the inspection',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.bookingCode} · $_imageCount of 4 photos added',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionTitle('Inspection Photos'),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.sizeOf(context).width < 350 ? 1 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: MediaQuery.sizeOf(context).width < 350
                  ? 1.55
                  : .92,
            ),
            itemBuilder: (context, index) {
              final image = _images[index];
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: _isPicking ? null : () => _showSourcePicker(index),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: image == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                height: 48,
                                width: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: .09,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.add_a_photo_outlined,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Photo ${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'Camera or gallery',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          )
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(image, fit: BoxFit.cover),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton.filled(
                                  tooltip: 'Remove photo',
                                  onPressed: () =>
                                      setState(() => _images[index] = null),
                                  icon: const Icon(Icons.close_rounded),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.black54,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _isPicking ? null : _submit,
              icon: const Icon(Icons.cloud_upload_outlined),
              label: Text(
                _imageCount == 0
                    ? 'Add Inspection Photos'
                    : 'Submit $_imageCount Inspection Photo${_imageCount == 1 ? '' : 's'}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
