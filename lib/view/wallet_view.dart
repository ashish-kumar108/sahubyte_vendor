import 'package:flutter/material.dart';
import 'package:sahubyte_vendor/model/response/technician_enquiry_model.dart';
import 'package:sahubyte_vendor/view/app_ui.dart';
import 'package:sahubyte_vendor/view/cash_collection_view.dart';
import 'package:sahubyte_vendor/view/settlement_history_view.dart';
import 'package:sahubyte_vendor/view/withdrawal_history_view.dart';

class WalletView extends StatelessWidget {
  const WalletView({
    super.key,
    this.completedBookings = const [],
    this.totalEarnings = 0,
    this.vendorName = '',
    this.vendorMobile = '',
  });

  final List<TechnicianEnquiryModel> completedBookings;
  final int totalEarnings;
  final String vendorName;
  final String vendorMobile;

  void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  String _money(int value) {
    final digits = value.toString();
    if (digits.length <= 3) return 'Rs. $digits';
    final tail = digits.substring(digits.length - 3);
    var head = digits.substring(0, digits.length - 3);
    final groups = <String>[];
    while (head.length > 2) {
      groups.insert(0, head.substring(head.length - 2));
      head = head.substring(0, head.length - 2);
    }
    if (head.isNotEmpty) groups.insert(0, head);
    return 'Rs. ${groups.join(',')},$tail';
  }

  Widget _summaryTile(String label, String value, IconData icon, Color tint) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tint.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: tint),
            const SizedBox(height: 14),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final average = completedBookings.isEmpty
        ? 0
        : totalEarnings ~/ completedBookings.length;
    return AppScaffold(
      title: 'My Wallet',
      backgroundColor: AppColors.page,
      body: ListView(
        padding: appPadding,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Recorded Earnings',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  _money(totalEarnings),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Calculated from completed service bookings',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _summaryTile(
                'Completed Jobs',
                '${completedBookings.length}',
                Icons.task_alt_outlined,
                AppColors.success,
              ),
              const SizedBox(width: 12),
              _summaryTile(
                'Average Job',
                _money(average),
                Icons.analytics_outlined,
                AppColors.accent,
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                _walletAction(
                  context,
                  icon: Icons.payments_outlined,
                  title: 'Cash Collection',
                  subtitle: 'Completed cash entries',
                  onTap: () => _open(
                    context,
                    CashCollectionView(
                      completedBookings: completedBookings,
                      totalEarnings: totalEarnings,
                    ),
                  ),
                ),
                const Divider(height: 1),
                _walletAction(
                  context,
                  icon: Icons.receipt_long_outlined,
                  title: 'Settlement History',
                  subtitle: 'Payout-ready completed jobs',
                  onTap: () => _open(
                    context,
                    SettlementHistoryView(
                      completedBookings: completedBookings,
                      totalEarnings: totalEarnings,
                    ),
                  ),
                ),
                const Divider(height: 1),
                _walletAction(
                  context,
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Withdrawal Requests',
                  subtitle: 'Request payout from available earnings',
                  onTap: () => _open(
                    context,
                    WithdrawalHistoryView(
                      completedBookings: completedBookings,
                      totalEarnings: totalEarnings,
                      vendorName: vendorName,
                      vendorMobile: vendorMobile,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionTitle('Completed Job Earnings'),
          if (completedBookings.isEmpty)
            const AppCard(
              child: EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No completed earnings yet',
                message: 'Completed jobs will appear here automatically.',
              ),
            )
          else
            ...completedBookings.map(
              (booking) => AppCard(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.greenSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.task_alt_rounded,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.serviceTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            booking.bookingCode,
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

  Widget _walletAction(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
