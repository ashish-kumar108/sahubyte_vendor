import 'package:flutter/material.dart';
import 'package:sahubyte_vendor/model/response/technician_enquiry_model.dart';
import 'package:sahubyte_vendor/view/app_ui.dart';

class CashCollectionView extends StatelessWidget {
  const CashCollectionView({
    super.key,
    this.completedBookings = const [],
    this.totalEarnings = 0,
  });

  final List<TechnicianEnquiryModel> completedBookings;
  final int totalEarnings;

  String _money(int value) {
    final negative = value < 0;
    final digits = value.abs().toString();
    if (digits.length <= 3) return 'Rs. ${negative ? '-' : ''}$digits';
    final tail = digits.substring(digits.length - 3);
    var head = digits.substring(0, digits.length - 3);
    final groups = <String>[];
    while (head.length > 2) {
      groups.insert(0, head.substring(head.length - 2));
      head = head.substring(0, head.length - 2);
    }
    if (head.isNotEmpty) groups.insert(0, head);
    return 'Rs. ${negative ? '-' : ''}${groups.join(',')},$tail';
  }

  @override
  Widget build(BuildContext context) {
    final recent = completedBookings.isEmpty ? null : completedBookings.first;
    return AppScaffold(
      title: 'Cash Collection',
      backgroundColor: AppColors.page,
      body: ListView(
        padding: appPadding,
        children: [
          WalletBalanceCard(amount: _money(totalEarnings)),
          const SizedBox(height: 22),
          const SectionTitle('Recent Cash Entry'),
          if (recent == null)
            const AppCard(
              child: EmptyState(
                icon: Icons.payments_outlined,
                title: 'No cash entries yet',
                message:
                    'Completed cash collections will appear here automatically.',
              ),
            )
          else
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Job ID: ${recent.bookingCode}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const StatusPill(
                        label: 'Paid',
                        color: AppColors.success,
                        icon: Icons.check_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  _CashRow(label: 'Amount', value: _money(recent.amount)),
                  _CashRow(
                    label: 'Date',
                    value: recent.createdAt.isEmpty ? '-' : recent.createdAt,
                  ),
                  const _CashRow(
                    label: 'Payment Mode',
                    value: 'Cash on Delivery',
                  ),
                  const _CashRow(
                    label: 'Message',
                    value: 'Collected from customer after service completion.',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CashRow extends StatelessWidget {
  const _CashRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
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
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
