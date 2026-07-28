import 'package:flutter/material.dart';
import 'package:sahubyte_vendor/model/response/technician_enquiry_model.dart';
import 'package:sahubyte_vendor/view/app_ui.dart';

class SettlementHistoryView extends StatelessWidget {
  const SettlementHistoryView({
    super.key,
    this.completedBookings = const [],
    this.totalEarnings = 0,
  });

  final List<TechnicianEnquiryModel> completedBookings;
  final int totalEarnings;

  String _money(int value) {
    final digits = value.abs().toString();
    if (digits.length <= 3) return 'Rs. ${value < 0 ? '-' : ''}$digits';
    final tail = digits.substring(digits.length - 3);
    var head = digits.substring(0, digits.length - 3);
    final groups = <String>[];
    while (head.length > 2) {
      groups.insert(0, head.substring(head.length - 2));
      head = head.substring(0, head.length - 2);
    }
    if (head.isNotEmpty) groups.insert(0, head);
    return 'Rs. ${value < 0 ? '-' : ''}${groups.join(',')},$tail';
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Settlement History',
      backgroundColor: AppColors.page,
      body: ListView(
        padding: appPadding,
        children: [
          WalletBalanceCard(amount: _money(totalEarnings)),
          const SizedBox(height: 22),
          const SectionTitle('Settlement Summary'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Pending settlement',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    StatusPill(
                      label: completedBookings.isEmpty ? 'No jobs' : 'Pending',
                      color: completedBookings.isEmpty
                          ? AppColors.muted
                          : AppColors.warning,
                      icon: completedBookings.isEmpty
                          ? Icons.info_outline_rounded
                          : Icons.schedule_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  completedBookings.isEmpty
                      ? 'Completed payouts will appear here once jobs are finished.'
                      : '${completedBookings.length} completed jobs are available for settlement review.',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (completedBookings.isEmpty)
            const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No settlement history found',
              message:
                  'Your approved settlement records will be listed here once processed.',
            )
          else
            ...completedBookings
                .take(10)
                .map(
                  (booking) => AppCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.bookingCode,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                booking.createdAt.isEmpty
                                    ? booking.serviceTitle
                                    : booking.createdAt,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _money(booking.amount),
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w900,
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
}
