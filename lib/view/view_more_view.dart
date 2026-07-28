import 'package:flutter/material.dart';
import 'package:sahubyte_vendor/model/response/technician_enquiry_model.dart';
import 'package:sahubyte_vendor/view/app_ui.dart';
import 'package:sahubyte_vendor/view/final_job_card_view.dart';
import 'package:sahubyte_vendor/view/job_card_view.dart';
import 'package:sahubyte_vendor/view/workflow_forms_view.dart';
import 'package:sahubyte_vendor/view_model/technician_view_model.dart';

class ViewMoreView extends StatefulWidget {
  const ViewMoreView({
    super.key,
    required this.booking,
    required this.technicianId,
  });

  final TechnicianEnquiryModel booking;
  final String technicianId;

  @override
  State<ViewMoreView> createState() => _ViewMoreViewState();
}

class _ViewMoreViewState extends State<ViewMoreView> {
  final _viewModel = TechnicianViewModel();
  bool _isUpdatingStatus = false;
  late TechnicianEnquiryModel _booking;

  TechnicianEnquiryModel get booking => _booking;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final labelWidth = (constraints.maxWidth * .32).clamp(78.0, 118.0);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: labelWidth,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value.trim().isEmpty ? 'Not available' : value,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _timelineStep(
    bool done,
    String title,
    String subtitle, {
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(
                done
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: done ? AppColors.success : AppColors.muted,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color get _statusColor {
    if (booking.statusLabel == 'Expired') return Colors.redAccent;
    if (booking.statusLabel == 'Reallocated') return const Color(0xFFEC4899);
    if (booking.statusLabel == 'Job Completed') return const Color(0xFF7C3AED);
    if (booking.statusLabel == 'Job Started') return const Color(0xFF14B8A6);
    if (booking.statusLabel == 'Job Card') return const Color(0xFF64748B);
    if (booking.statusLabel == 'Inspection') return const Color(0xFFF59E0B);
    if (booking.statusLabel == 'Arrived') return const Color(0xFF8B5CF6);
    if (booking.statusLabel == 'On The Way') return const Color(0xFF0EA5E9);
    if (booking.statusLabel == 'Accepted') return AppColors.success;
    return AppColors.primary;
  }

  Future<void> _updateTechnicianStatus(String status) async {
    final currentStatus = int.tryParse(booking.technicianStatus) ?? 0;
    final nextStatus = int.tryParse(status) ?? currentStatus;
    final isReallocateAction = nextStatus == 7;
    final canReallocate =
        currentStatus >= 1 &&
        currentStatus < 5 &&
        booking.statusLabel != 'Job Completed' &&
        booking.statusLabel != 'Completed';
    if (nextStatus == 4) {
      _openCreateJobCard();
      return;
    }
    if (nextStatus == 3) {
      await _openInspectionForm();
      return;
    }
    if (isReallocateAction && !canReallocate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reallocation is available only before work starts.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (isReallocateAction) {
      await _openReallocationForm();
      return;
    }
    if (nextStatus <= currentStatus) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This status is already updated.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!isReallocateAction && nextStatus != currentStatus + 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete the previous step first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!isReallocateAction && nextStatus >= 5 && !_isWorkConfirmed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Customer approval is pending. You can start work after approval.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (nextStatus == 6 && !_isFinalPaymentPaid) {
      final message = _isCashPayment
          ? 'Cash payment is pending. Mark cash as received before completing the job.'
          : _isOnlinePayment
          ? 'Online payment is pending. Complete the job after gateway confirmation.'
          : 'Customer must select and complete the final payment before job completion.';
      _showMessage(message);
      return;
    }
    setState(() => _isUpdatingStatus = true);
    try {
      final response = await _viewModel.updateTechnicianStatus(
        enquiryId: booking.id,
        technicianId: widget.technicianId,
        status: status,
      );
      if (!response.isSuccess) throw Exception(response.displayMessage);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.displayMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, 'techStatus:$status');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            professionalErrorMessage(
              e,
              fallback: 'Status could not be updated. Please try again.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  Future<void> _openInspectionForm() async {
    final currentStatus = int.tryParse(booking.technicianStatus) ?? 0;
    if (currentStatus != 2) {
      _showMessage('Please mark the technician as arrived first.');
      return;
    }
    final images = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            InspectionImagesView(bookingCode: booking.bookingCode),
      ),
    );
    if (!mounted || images == null || images.isEmpty) return;
    setState(() => _isUpdatingStatus = true);
    try {
      final upload = await _viewModel.saveInspection(
        enquiryId: booking.id,
        imagesBase64: images,
      );
      if (!upload.isSuccess) throw Exception(upload.displayMessage);
      final statusResponse = await _viewModel.updateTechnicianStatus(
        enquiryId: booking.id,
        technicianId: widget.technicianId,
        status: '3',
      );
      if (!statusResponse.isSuccess) {
        throw Exception(statusResponse.displayMessage);
      }
      if (!mounted) return;
      _showMessage('Inspection submitted successfully.');
      Navigator.pop(context, 'techStatus:3');
    } catch (e) {
      if (!mounted) return;
      _showMessage(
        professionalErrorMessage(
          e,
          fallback: 'Inspection could not be submitted. Please try again.',
        ),
      );
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  Future<void> _openReallocationForm() async {
    final currentStatus = int.tryParse(booking.technicianStatus) ?? 0;
    final canReallocate =
        currentStatus >= 1 &&
        currentStatus < 5 &&
        booking.statusLabel != 'Job Completed' &&
        booking.statusLabel != 'Completed';
    if (!canReallocate) {
      _showMessage('Reallocation is available only before work starts.');
      return;
    }
    final note = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ReallocationNoteView(bookingCode: booking.bookingCode),
      ),
    );
    if (!mounted || note == null || note.trim().isEmpty) return;
    setState(() => _isUpdatingStatus = true);
    try {
      final saved = await _viewModel.saveReallocationNote(
        enquiryId: booking.id,
        note: note,
      );
      if (!saved.isSuccess) throw Exception(saved.displayMessage);
      final statusResponse = await _viewModel.updateTechnicianStatus(
        enquiryId: booking.id,
        technicianId: widget.technicianId,
        status: '7',
        reallocatedNote: note,
      );
      if (!statusResponse.isSuccess) {
        throw Exception(statusResponse.displayMessage);
      }
      if (!mounted) return;
      _showMessage('Booking reallocated successfully.');
      Navigator.pop(context, 'techStatus:7');
    } catch (e) {
      if (!mounted) return;
      _showMessage(
        professionalErrorMessage(
          e,
          fallback: 'Reallocation could not be submitted. Please try again.',
        ),
      );
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  bool get _isWorkConfirmed {
    final value = booking.workConfirmation.trim().toLowerCase();
    return value == '1' || value == 'true' || value == 'yes';
  }

  bool get _isFinalPaymentPaid =>
      booking.paymentStatus.trim().toLowerCase() == 'paid';

  bool get _isCashPayment => booking.paymentType.trim().toLowerCase() == 'cash';

  bool get _isOnlinePayment =>
      booking.paymentType.trim().toLowerCase() == 'online';

  Future<void> _markCashReceived() async {
    if (_isUpdatingStatus || !_isCashPayment || _isFinalPaymentPaid) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm cash received'),
        content: Text(
          'Confirm only after receiving Rs. ${booking.totalPrice} from the customer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.verified_outlined),
            label: const Text('Mark as paid'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isUpdatingStatus = true);
    try {
      final response = await _viewModel.updateFinalPaymentStatus(
        enquiryId: booking.id,
        paymentType: 'cash',
        paymentStatus: 'paid',
      );
      if (!response.isSuccess) throw Exception(response.displayMessage);
      if (!mounted) return;
      setState(() {
        _booking = booking.copyWith(paymentType: 'cash', paymentStatus: 'paid');
      });
      _showMessage('Cash payment confirmed. The job can now be completed.');
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        professionalErrorMessage(
          error,
          fallback: 'Cash payment could not be confirmed. Please try again.',
        ),
      );
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  Future<void> _refreshBooking() async {
    try {
      final bookings = await _viewModel.getAssignedEnquiries(
        technicianId: widget.technicianId,
        enquiryStatus: '',
        technicianStatus: '',
        page: 1,
        limit: 100,
      );
      final matches = bookings.where((item) => item.id == booking.id);
      if (!mounted || matches.isEmpty) return;
      setState(() => _booking = matches.first);
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        professionalErrorMessage(
          error,
          fallback: 'Booking progress could not be refreshed.',
        ),
      );
    }
  }

  void _openCreateJobCard() {
    final currentStatus = int.tryParse(booking.technicianStatus) ?? 0;
    if (currentStatus < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please complete the inspection before creating a job card.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FinalJobCardView(
          booking: booking,
          technicianId: widget.technicianId,
        ),
      ),
    );
  }

  Widget _statusAction(String code, String label, IconData icon) {
    final currentStatus = int.tryParse(booking.technicianStatus) ?? 0;
    final actionStatus = int.tryParse(code) ?? currentStatus;
    final isReallocateAction = actionStatus == 7;
    final isJobCardAction = actionStatus == 4;
    final selected = actionStatus <= currentStatus;
    final nextAllowed = actionStatus == currentStatus + 1;
    final canReallocate =
        currentStatus >= 1 &&
        currentStatus < 5 &&
        booking.statusLabel != 'Job Completed' &&
        booking.statusLabel != 'Completed';
    final blocked = isReallocateAction
        ? !canReallocate
        : isJobCardAction
        ? currentStatus < 3
        : (!selected && !nextAllowed);
    final canTapJobCard = isJobCardAction && currentStatus >= 3;
    return Expanded(
      child: OutlinedButton.icon(
        onPressed:
            _isUpdatingStatus || (!canTapJobCard && (selected || blocked))
            ? null
            : () => _updateTechnicianStatus(code),
        icon: Icon(icon, size: 17),
        label: Text(label, overflow: TextOverflow.ellipsis),
        style: OutlinedButton.styleFrom(
          foregroundColor: selected
              ? AppColors.success
              : blocked
              ? AppColors.muted
              : AppColors.primary,
          backgroundColor: selected
              ? AppColors.success.withValues(alpha: .10)
              : blocked
              ? const Color(0xFFF3F6FA)
              : Colors.white,
          side: BorderSide(
            color: selected
                ? AppColors.success.withValues(alpha: .35)
                : blocked
                ? AppColors.border.withValues(alpha: .55)
                : AppColors.border,
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slot = booking.dateTimeSlot.isEmpty
        ? booking.createdAt
        : booking.dateTimeSlot;
    return AppScaffold(
      title: 'Booking Progress',
      backgroundColor: AppColors.page,
      body: RefreshIndicator(
        onRefresh: _refreshBooking,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: appPadding,
          children: [
            AppCard(
              child: Row(
                children: [
                  Container(
                    height: 62,
                    width: 62,
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.home_repair_service_outlined,
                      color: _statusColor,
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.serviceTitle,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          slot,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  StatusPill(
                    label: booking.statusLabel,
                    color: _statusColor,
                    icon: Icons.sync_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SectionTitle('Client Details'),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Text(
                          _initials(booking.customerName),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          booking.customerName.isEmpty
                              ? 'Customer #${booking.userId}'
                              : booking.customerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _detailRow('Phone', booking.customerMobile),
                  _detailRow('Email', booking.customerEmail),
                  _detailRow('Address', booking.address),
                  _detailRow('State', booking.state),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SectionTitle('Job Details'),
            AppCard(
              child: Column(
                children: [
                  _detailRow('Enquiry ID', booking.bookingCode),
                  _detailRow('Job Card', 'JC-${booking.id.padLeft(6, '0')}'),
                  _detailRow('Service', booking.serviceTitle),
                  _detailRow('Issue', booking.problemSummary),
                  _detailRow('Slot', slot),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => JobCardView(booking: booking),
                          ),
                        );
                      },
                      icon: const Icon(Icons.assignment_outlined),
                      label: const Text('Open Job Card'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SectionTitle('Problem Note'),
            AppCard(
              child: Text(
                booking.problemDescription.isEmpty
                    ? booking.problemSummary
                    : booking.problemDescription,
                style: const TextStyle(height: 1.45, color: AppColors.text),
              ),
            ),
            const SizedBox(height: 18),
            const SectionTitle('Track Order Status'),
            AppCard(
              child: Column(
                children: [
                  _timelineStep(
                    true,
                    'Request received',
                    'Enquiry ${booking.bookingCode} was created successfully.',
                  ),
                  _timelineStep(
                    booking.statusLabel != 'New',
                    'Technician response',
                    booking.statusLabel == 'New'
                        ? 'Waiting for technician action.'
                        : 'Current status: ${booking.statusLabel}.',
                  ),
                  _timelineStep(
                    booking.statusLabel == 'Accepted' ||
                        booking.statusLabel == 'On The Way' ||
                        booking.statusLabel == 'Arrived' ||
                        booking.statusLabel == 'Inspection' ||
                        booking.statusLabel == 'Job Card' ||
                        booking.statusLabel == 'Job Started' ||
                        booking.statusLabel == 'Job Completed',
                    'Visit scheduled',
                    slot.isEmpty ? 'Slot not available.' : slot,
                  ),
                  _timelineStep(
                    booking.statusLabel == 'On The Way' ||
                        booking.statusLabel == 'Arrived' ||
                        booking.statusLabel == 'Inspection' ||
                        booking.statusLabel == 'Job Card' ||
                        booking.statusLabel == 'Job Started' ||
                        booking.statusLabel == 'Job Completed',
                    'Work started',
                    booking.statusLabel == 'New' ||
                            booking.statusLabel == 'Accepted'
                        ? 'Technician has not started yet.'
                        : 'Technician workflow is active.',
                  ),
                  _timelineStep(
                    booking.statusLabel == 'Job Completed',
                    'Job completed',
                    booking.statusLabel == 'Job Completed'
                        ? 'Completion marked from server.'
                        : 'Completion confirmation pending.',
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SectionTitle('Technician Status'),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Update complete technician workflow.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _statusAction(
                        '0',
                        'Assigned',
                        Icons.assignment_turned_in,
                      ),
                      const SizedBox(width: 8),
                      _statusAction('1', 'On Way', Icons.delivery_dining),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _statusAction('2', 'Arrived', Icons.location_on_outlined),
                      const SizedBox(width: 8),
                      _statusAction('3', 'Inspection', Icons.search_rounded),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _statusAction('4', 'Job Card', Icons.assignment_outlined),
                      const SizedBox(width: 8),
                      _statusAction(
                        '5',
                        'Started',
                        Icons.build_circle_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _statusAction('6', 'Completed', Icons.verified_outlined),
                      const SizedBox(width: 8),
                      _statusAction(
                        '7',
                        'Reallocated',
                        Icons.sync_problem_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SectionTitle('Payment'),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('Service Fee', 'Rs. ${booking.serviceFee}'),
                  if (booking.problemFee > 0)
                    _detailRow('Problem Fee', 'Rs. ${booking.problemFee}'),
                  _detailRow('Tax', 'Rs. ${booking.tax}'),
                  _detailRow('Final Payable', 'Rs. ${booking.totalPrice}'),
                  const Divider(height: 24),
                  _detailRow(
                    'Payment Method',
                    booking.paymentType.trim().isEmpty
                        ? 'Not selected'
                        : booking.paymentType.trim().toUpperCase(),
                  ),
                  _detailRow(
                    'Payment Status',
                    _isFinalPaymentPaid ? 'Paid' : 'Pending',
                  ),
                  if (_isCashPayment && !_isFinalPaymentPaid) ...[
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isUpdatingStatus ? null : _markCashReceived,
                        icon: const Icon(Icons.payments_outlined),
                        label: Text(
                          _isUpdatingStatus
                              ? 'Confirming payment...'
                              : 'Mark Cash Received',
                        ),
                      ),
                    ),
                  ],
                  if (_isOnlinePayment && !_isFinalPaymentPaid)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Waiting for online gateway confirmation.',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'CU';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
