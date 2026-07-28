import 'package:flutter/material.dart';
import 'package:sahubyte_vendor/model/response/technician_enquiry_model.dart';
import 'package:sahubyte_vendor/view/app_ui.dart';

class WithdrawalHistoryView extends StatefulWidget {
  const WithdrawalHistoryView({
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

  @override
  State<WithdrawalHistoryView> createState() => _WithdrawalHistoryViewState();
}

class _WithdrawalHistoryViewState extends State<WithdrawalHistoryView> {
  late final TextEditingController _nameController;
  late final TextEditingController _mobileController;
  final _accountController = TextEditingController();
  final _ifscController = TextEditingController();
  late final TextEditingController _amountController;

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
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.vendorName);
    _mobileController = TextEditingController(text: widget.vendorMobile);
    _amountController = TextEditingController(
      text: widget.totalEarnings > 0 ? widget.totalEarnings.toString() : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _accountController.dispose();
    _ifscController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _showWithdrawalRequestModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 16,
          left: 20,
          right: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Withdrawal Request',
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
              const SizedBox(height: 12),
              _field('Name', _nameController, Icons.person_outline),
              _field('Mobile Number', _mobileController, Icons.phone_outlined),
              _field(
                'Account Number',
                _accountController,
                Icons.account_balance_outlined,
              ),
              _field('IFSC Code', _ifscController, Icons.tag_outlined),
              _field(
                'Amount',
                _amountController,
                Icons.currency_rupee_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Reset',
                      icon: Icons.refresh_rounded,
                      onPressed: () {
                        _accountController.clear();
                        _ifscController.clear();
                        _amountController.text = widget.totalEarnings > 0
                            ? widget.totalEarnings.toString()
                            : '';
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Submit',
                      icon: Icons.send_outlined,
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Withdrawal request API is not connected yet.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Withdrawal Requests',
      backgroundColor: AppColors.page,
      body: ListView(
        padding: appPadding,
        children: [
          WalletBalanceCard(
            amount: _money(widget.totalEarnings),
            trailing: IconButton(
              onPressed: _showWithdrawalRequestModal,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.16),
              ),
              tooltip: 'New request',
            ),
          ),
          const SizedBox(height: 22),
          const SectionTitle('Request History'),
          const AppCard(
            child: EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No withdrawal requests yet',
              message:
                  'Submitted withdrawal requests will appear here after backend support is added.',
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            color: AppColors.primarySoft,
            child: Row(
              children: [
                const Icon(Icons.task_alt_rounded, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${widget.completedBookings.length} completed jobs available for payout review.',
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
