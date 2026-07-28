import 'package:flutter/material.dart';
import 'package:sahubyte_vendor/model/response/technician_enquiry_model.dart';
import 'package:sahubyte_vendor/view/app_ui.dart';
import 'package:sahubyte_vendor/view/job_card_view.dart';
import 'package:sahubyte_vendor/view_model/technician_view_model.dart';

class BookingDetailsView extends StatefulWidget {
  const BookingDetailsView({
    super.key,
    required this.booking,
    required this.technicianId,
  });

  final TechnicianEnquiryModel booking;
  final String technicianId;

  @override
  State<BookingDetailsView> createState() => _BookingDetailsViewState();
}

class _BookingDetailsViewState extends State<BookingDetailsView> {
  final _viewModel = TechnicianViewModel();
  bool _isAccepting = false;
  late TechnicianEnquiryModel _booking;

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

  Future<void> _acceptBooking() async {
    final enquiryId = _booking.id.trim();
    final technicianId = widget.technicianId.trim();
    if (enquiryId.isEmpty || technicianId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing enquiry or technician ID.')),
      );
      return;
    }
    setState(() => _isAccepting = true);
    try {
      final response = await _viewModel.assignTechnician(
        enquiryId: enquiryId,
        technicianId: technicianId,
      );
      if (!response.isSuccess) throw Exception(response.displayMessage);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.displayMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, 'accepted');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            professionalErrorMessage(
              e,
              fallback: 'Booking could not be accepted. Please try again.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  Future<void> _refreshBooking() async {
    try {
      final bookings = await _viewModel.getTechnicianEnquiries(
        technicianId: widget.technicianId,
        page: 1,
        limit: 100,
      );
      final matches = bookings.where((item) => item.id == _booking.id);
      if (!mounted || matches.isEmpty) return;
      setState(() => _booking = matches.first);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            professionalErrorMessage(
              error,
              fallback: 'Booking could not be refreshed. Please try again.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _quickInfo(IconData icon, String label, String value, Color tint) {
    return Expanded(
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: tint.withValues(alpha: 0.24), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: tint.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.84),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: tint, size: 19),
            ),
            const Spacer(),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value.isEmpty ? 'Not set' : value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 15,
                height: 1.15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slotInfo(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.20),
          width: 1.4,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Appointment slot',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value.isEmpty ? 'Not set' : value,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    height: 1.28,
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

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not available' : value,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 15,
                height: 1.35,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _billRow(String label, int value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isTotal ? AppColors.text : AppColors.muted,
                fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
          Text(
            'Rs. $value',
            style: TextStyle(
              fontSize: isTotal ? 19 : 14,
              fontWeight: FontWeight.w900,
              color: isTotal ? AppColors.primaryDark : AppColors.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _attachmentTile(TechnicianAttachmentItem attachment, int index) {
    final isVideo = attachment.isVideo;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: (isVideo ? AppColors.accent : AppColors.primary)
                  .withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              isVideo
                  ? Icons.play_circle_outline_rounded
                  : Icons.image_outlined,
              color: isVideo ? AppColors.accent : AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isVideo ? 'Video ${index + 1}' : 'Photo ${index + 1}',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  attachment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.attach_file_rounded, color: AppColors.muted),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;
    return AppScaffold(
      title: 'Booking Details',
      backgroundColor: AppColors.page,
      body: RefreshIndicator(
        onRefresh: _refreshBooking,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: appPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.surface, Color(0xFFFFF7EF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Color(0xFFFFD8BA), width: 1.4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7A3E12).withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 58,
                          width: 58,
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.business_center_outlined,
                            size: 32,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.serviceTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                booking.problemSummary,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    StatusPill(
                      label: booking.statusLabel,
                      color: AppColors.accent,
                      icon: Icons.schedule_outlined,
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFC8D2E1)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.confirmation_number_outlined,
                          color: AppColors.accent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Booking ID: ${booking.bookingCode}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  _slotInfo(booking.dateTimeSlot),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _quickInfo(
                        Icons.map_outlined,
                        'State',
                        booking.state,
                        AppColors.accent,
                      ),
                      const SizedBox(width: 12),
                      _quickInfo(
                        Icons.payments_outlined,
                        'Amount',
                        'Rs. ${booking.amount}',
                        AppColors.success,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const SectionTitle('Customer Details'),
              AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Column(
                  children: [
                    _infoRow(
                      Icons.person_outline_rounded,
                      'Name',
                      booking.customerName.isEmpty
                          ? 'Customer'
                          : booking.customerName,
                    ),
                    const Divider(height: 1),
                    _infoRow(
                      Icons.call_outlined,
                      'Phone',
                      booking.customerMobile.isEmpty
                          ? 'Not available'
                          : booking.customerMobile,
                    ),
                    const Divider(height: 1),
                    _infoRow(
                      Icons.location_on_outlined,
                      'Address',
                      booking.address.isEmpty
                          ? 'Address not available'
                          : booking.address,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const SectionTitle('Problem Note'),
              AppCard(
                color: const Color(0xFFFFFCF7),
                child: Text(
                  booking.problemDescription.isEmpty
                      ? booking.problemSummary
                      : booking.problemDescription,
                  style: const TextStyle(height: 1.45, color: AppColors.text),
                ),
              ),
              if (booking.attachments.isNotEmpty) ...[
                const SizedBox(height: 22),
                const SectionTitle('Customer Attachments'),
                AppCard(
                  child: Column(
                    children: [
                      for (var i = 0; i < booking.attachments.length; i++)
                        _attachmentTile(booking.attachments[i], i),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 22),
              const SectionTitle('Bill Summary'),
              AppCard(
                child: Column(
                  children: [
                    _billRow('Service fee', booking.serviceFee),
                    if (booking.problemFee > 0)
                      _billRow('Problem fee', booking.problemFee),
                    _billRow('Tax', booking.tax),
                    const Divider(height: 24),
                    _billRow('Total', booking.amount, isTotal: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AppCard(
                color: AppColors.primarySoft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Ready to take this booking?',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Review the customer, appointment and billing details before accepting.',
                      style: TextStyle(
                        color: AppColors.muted,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: _isAccepting ? 'Accepting...' : 'Accept Booking',
                      icon: Icons.task_alt_rounded,
                      onPressed: _isAccepting ? null : _acceptBooking,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Open Job Card',
                icon: Icons.assignment_outlined,
                color: AppColors.primary,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JobCardView(booking: booking),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
