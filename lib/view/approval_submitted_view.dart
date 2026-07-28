import 'package:flutter/material.dart';
import 'package:sahubyte_vendor/model/response/technician_enquiry_model.dart';
import 'package:sahubyte_vendor/view/app_ui.dart';
import 'package:sahubyte_vendor/view/home_view.dart';

class ApprovalSubmittedView extends StatelessWidget {
  const ApprovalSubmittedView({
    super.key,
    required this.totalAmount,
    required this.solutionCount,
    this.booking,
  });

  final int totalAmount;
  final int solutionCount;
  final TechnicianEnquiryModel? booking;

  @override
  Widget build(BuildContext context) {
    final bookingId = booking?.id.trim() ?? '';
    final jobCard = bookingId.isNotEmpty
        ? 'JC-${bookingId.padLeft(6, '0')}'
        : booking?.bookingCode.trim().isNotEmpty == true
        ? booking!.bookingCode
        : 'JC-PENDING';
    final customer = booking?.customerName.trim().isNotEmpty == true
        ? booking!.customerName.trim()
        : booking?.userId.trim().isNotEmpty == true
        ? 'Customer #${booking!.userId.trim()}'
        : 'Customer';
    final service = booking?.serviceTitle.trim().isNotEmpty == true
        ? booking!.serviceTitle.trim()
        : 'Service enquiry';

    return AppScaffold(
      title: 'Approval Submitted',
      backgroundColor: AppColors.page,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: AppColors.text),
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeView()),
            (route) => false,
          );
        },
      ),
      body: ListView(
        padding: appPadding,
        children: [
          AppCard(
            color: const Color(0xFFF8FBFF),
            child: Column(
              children: [
                Container(
                  height: 86,
                  width: 86,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE7F8EF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.task_alt_rounded,
                    color: AppColors.success,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Sent for customer approval',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The customer will review the recommended solution and estimate. You can continue once approval is received.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionTitle('Approval Summary'),
          AppCard(
            child: Column(
              children: [
                _SummaryRow(label: 'Job Card', value: jobCard),
                _SummaryRow(label: 'Customer', value: customer),
                _SummaryRow(label: 'Service', value: service),
                _SummaryRow(
                  label: 'Solutions',
                  value: '$solutionCount selected',
                ),
                _SummaryRow(label: 'Estimated Total', value: '₹ $totalAmount'),
                const Divider(height: 24),
                const Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: AppColors.warning),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Status: Waiting for customer approval',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionTitle('Next Steps'),
          const AppCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.notifications_active_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text('Customer gets approval request'),
                  subtitle: Text(
                    'Estimate and solution list are shared for confirmation.',
                  ),
                ),
                Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.assignment_turned_in_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text('Continue after approval'),
                  subtitle: Text(
                    'Approved jobs can move to service completion.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Back to Dashboard',
            icon: Icons.home_outlined,
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeView()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
