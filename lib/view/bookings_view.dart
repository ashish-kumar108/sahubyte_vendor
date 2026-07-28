import 'package:flutter/material.dart';
import 'package:sahubyte_vendor/model/response/technician_enquiry_model.dart';
import 'package:sahubyte_vendor/view/app_ui.dart';
import 'package:sahubyte_vendor/view/booking_details_view.dart';
import 'package:sahubyte_vendor/view/job_card_view.dart';
import 'package:sahubyte_vendor/view/view_more_view.dart';
import 'package:sahubyte_vendor/view_model/technician_view_model.dart';

class BookingsView extends StatefulWidget {
  const BookingsView({
    super.key,
    required this.technicianId,
    required this.state,
    required this.refreshToken,
    this.onBack,
  });

  final String technicianId;
  final String state;
  final int refreshToken;
  final VoidCallback? onBack;

  @override
  State<BookingsView> createState() => _BookingsViewState();
}

class _BookingsViewState extends State<BookingsView> {
  final _viewModel = TechnicianViewModel();
  final _scrollController = ScrollController();
  String _selectedTab = 'All';
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _page = 1;
  static const int _limit = 10;
  List<TechnicianEnquiryModel> _bookings = [];

  final List<_TabMeta> _statusOptions = const [
    _TabMeta('New', Icons.inbox_outlined, AppColors.accent),
    _TabMeta('Accepted', Icons.task_alt_outlined, AppColors.success),
    _TabMeta('On The Way', Icons.delivery_dining_outlined, Color(0xFF0EA5E9)),
    _TabMeta('Arrived', Icons.location_on_outlined, Color(0xFF8B5CF6)),
    _TabMeta('Inspection', Icons.search_rounded, Color(0xFFF59E0B)),
    _TabMeta('Job Card', Icons.assignment_outlined, Color(0xFF64748B)),
    _TabMeta('Job Started', Icons.build_circle_outlined, Color(0xFF14B8A6)),
    _TabMeta('Job Completed', Icons.verified_outlined, Color(0xFF7C3AED)),
    _TabMeta('Reallocated', Icons.sync_problem_outlined, Color(0xFFEC4899)),
    _TabMeta('Expired', Icons.timer_off_outlined, Colors.redAccent),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadBookings();
  }

  @override
  void didUpdateWidget(covariant BookingsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.technicianId != widget.technicianId ||
        oldWidget.refreshToken != widget.refreshToken) {
      _loadBookings();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  List<TechnicianEnquiryModel> get _filteredBookings {
    if (_selectedTab == 'All') return _bookings;
    if (_selectedTab == 'New') {
      return _bookings
          .where(
            (booking) =>
                booking.statusLabel == 'New' ||
                booking.statusLabel == 'Reallocated',
          )
          .toList();
    }
    return _bookings
        .where((booking) => booking.statusLabel == _selectedTab)
        .toList();
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _isLoading ||
        _isLoadingMore ||
        !_hasMore) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 220) {
      _loadNextPage();
    }
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _isLoadingMore = false;
      _error = null;
      _page = 1;
      _hasMore = true;
    });

    if (widget.technicianId.trim().isEmpty) {
      setState(() {
        _bookings = [];
        _hasMore = false;
        _isLoading = false;
        _error = 'Please complete technician profile first.';
      });
      return;
    }

    try {
      final bookings = await _fetchBookings(page: _page);
      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _hasMore = bookings.length == _limit;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _bookings = [];
        _hasMore = false;
        _isLoading = false;
        _error = professionalErrorMessage(
          error,
          fallback: 'Bookings could not be refreshed. Please try again.',
        );
      });
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _page + 1;
      final bookings = await _fetchBookings(page: nextPage);
      if (!mounted) return;
      final ids = _bookings.map((booking) => booking.id).toSet();
      setState(() {
        _page = nextPage;
        _bookings.addAll(bookings.where((booking) => ids.add(booking.id)));
        _hasMore = bookings.length == _limit;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  Future<List<TechnicianEnquiryModel>> _fetchBookings({required int page}) {
    if (_selectedTab == 'All') {
      return _fetchAllBookings(page: page);
    }

    if (_selectedTab == 'New') {
      return _viewModel.getTechnicianEnquiries(
        technicianId: widget.technicianId,
        page: page,
        limit: _limit,
      );
    }

    final status = _assignedStatusForTab(_selectedTab);
    return _viewModel.getAssignedEnquiries(
      technicianId: widget.technicianId,
      enquiryStatus: status.enquiryStatus,
      technicianStatus: status.technicianStatus,
      page: page,
      limit: _limit,
    );
  }

  Future<List<TechnicianEnquiryModel>> _fetchAllBookings({
    required int page,
  }) async {
    final results = <TechnicianEnquiryModel>[];

    final newBookings = await _viewModel.getTechnicianEnquiries(
      technicianId: widget.technicianId,
      page: page,
      limit: _limit,
    );
    results.addAll(newBookings);

    final assignedBookings = await _viewModel.getAssignedEnquiries(
      technicianId: widget.technicianId,
      enquiryStatus: '',
      technicianStatus: '',
      page: page,
      limit: 100,
    );
    results.addAll(assignedBookings);

    final seen = <String>{};
    final unique = <TechnicianEnquiryModel>[];
    for (final booking in results) {
      if (seen.add(booking.id)) unique.add(booking);
    }
    unique.sort((a, b) => b.id.compareTo(a.id));
    return unique;
  }

  _AssignedStatus _assignedStatusForTab(String tab) {
    switch (tab) {
      case 'Accepted':
        return const _AssignedStatus('1', '0');
      case 'On The Way':
        return const _AssignedStatus('1', '1');
      case 'Arrived':
        return const _AssignedStatus('1', '2');
      case 'Inspection':
        return const _AssignedStatus('1', '3');
      case 'Job Card':
        return const _AssignedStatus('1', '4');
      case 'Job Started':
        return const _AssignedStatus('1', '5');
      case 'Job Completed':
        return const _AssignedStatus('2', '6');
      case 'Reallocated':
        return const _AssignedStatus('5', '7');
      case 'Expired':
        return const _AssignedStatus('5', '0');
      default:
        return const _AssignedStatus('1', '0');
    }
  }

  Future<void> _openPrimaryAction(TechnicianEnquiryModel booking) async {
    final status = booking.statusLabel;
    final opensPendingFlow =
        _selectedTab == 'New' && (status == 'New' || status == 'Reallocated');
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            (!opensPendingFlow &&
                (status == 'Accepted' ||
                    status == 'On The Way' ||
                    status == 'Arrived' ||
                    status == 'Inspection' ||
                    status == 'Job Card' ||
                    status == 'Job Started' ||
                    status == 'Job Completed' ||
                    status == 'Reallocated' ||
                    status == 'Expired'))
            ? ViewMoreView(booking: booking, technicianId: widget.technicianId)
            : BookingDetailsView(
                booking: booking,
                technicianId: widget.technicianId,
              ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        if (result == 'accepted') {
          _selectedTab = 'Accepted';
        } else if (result == 'expired') {
          _selectedTab = 'Expired';
        } else if (result == 'techStatus:1') {
          _selectedTab = 'On The Way';
        } else if (result == 'techStatus:2') {
          _selectedTab = 'Arrived';
        } else if (result == 'techStatus:3') {
          _selectedTab = 'Inspection';
        } else if (result == 'techStatus:4') {
          _selectedTab = 'Job Card';
        } else if (result == 'techStatus:5') {
          _selectedTab = 'Job Started';
        } else if (result == 'techStatus:6') {
          _selectedTab = 'Job Completed';
        } else if (result == 'techStatus:7') {
          _selectedTab = 'Reallocated';
        }
      });
      _loadBookings();
    }
  }

  Widget _filterPanel() {
    final selectedMeta = _selectedTab == 'All'
        ? const _TabMeta(
            'All',
            Icons.dashboard_customize_outlined,
            AppColors.primary,
          )
        : _statusOptions.firstWhere(
            (item) => item.label == _selectedTab,
            orElse: () => _statusOptions.first,
          );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      color: AppColors.page,
      child: Row(
        children: [
          _allFilterButton(),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedTab == 'All'
                      ? selectedMeta.label
                      : _selectedTab,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  items: [
                    const DropdownMenuItem(
                      value: 'All',
                      child: _DropdownLabel(
                        icon: Icons.dashboard_customize_outlined,
                        label: 'All enquiries',
                        color: AppColors.primary,
                      ),
                    ),
                    ..._statusOptions.map(
                      (item) => DropdownMenuItem(
                        value: item.label,
                        child: _DropdownLabel(
                          icon: item.icon,
                          label: item.label,
                          color: item.color,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null || value == _selectedTab) return;
                    setState(() => _selectedTab = value);
                    _loadBookings();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _allFilterButton() {
    final selected = _selectedTab == 'All';
    return GestureDetector(
      onTap: () {
        if (selected) return;
        setState(() => _selectedTab = 'All');
        _loadBookings();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.dashboard_customize_outlined,
              size: 17,
              color: selected ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 7),
            Text(
              'All',
              style: TextStyle(
                color: selected ? Colors.white : AppColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(TechnicianEnquiryModel booking) {
    final status = booking.statusLabel;
    final statusColor = _colorForStatus(status);
    final statusIcon = _iconForStatus(status);
    return AppCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.home_repair_service_outlined,
                        color: statusColor,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.serviceTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Booking ID: ${booking.bookingCode}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusPill(
                      label: status,
                      color: statusColor,
                      icon: statusIcon,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _metaChip(
                      Icons.calendar_month_outlined,
                      booking.dateTimeSlot.isEmpty
                          ? booking.createdAt
                          : booking.dateTimeSlot,
                    ),
                    _metaChip(Icons.payments_outlined, 'Rs. ${booking.amount}'),
                    if (booking.state.isNotEmpty)
                      _metaChip(Icons.map_outlined, booking.state),
                  ],
                ),
                const SizedBox(height: 14),
                if (status == 'Expired')
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.18),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Expired: This enquiry is no longer active.',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 17,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          booking.address.isEmpty
                              ? 'Address not available'
                              : booking.address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact =
                        constraints.maxWidth < 320 && status != 'Expired';
                    final primary = _bookingActionButton(
                      label:
                          (status == 'Accepted' ||
                              status == 'On The Way' ||
                              status == 'Arrived' ||
                              status == 'Inspection' ||
                              status == 'Job Card' ||
                              status == 'Job Started' ||
                              status == 'Job Completed' ||
                              status == 'Reallocated' ||
                              status == 'Expired')
                          ? 'View Progress'
                          : 'View Details',
                      icon: Icons.visibility_outlined,
                      color: statusColor,
                      filled: true,
                      onPressed: () => _openPrimaryAction(booking),
                    );
                    final secondary = status == 'Expired'
                        ? null
                        : _bookingActionButton(
                            label: 'Job Card',
                            icon: Icons.assignment_outlined,
                            color: statusColor,
                            filled: false,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      JobCardView(booking: booking),
                                ),
                              );
                            },
                          );
                    if (compact) {
                      return Column(
                        children: [
                          SizedBox(width: double.infinity, child: primary),
                          const SizedBox(height: 8),
                          SizedBox(width: double.infinity, child: secondary!),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: primary),
                        if (secondary != null) ...[
                          const SizedBox(width: 10),
                          Expanded(child: secondary),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bookingActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool filled,
    required VoidCallback onPressed,
  }) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    );
    final textStyle = const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w900,
    );
    if (filled) {
      return SizedBox(
        height: 50,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 19),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, maxLines: 1),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
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
        icon: Icon(icon, size: 19),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, maxLines: 1),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          backgroundColor: color.withValues(alpha: 0.07),
          side: BorderSide(color: color.withValues(alpha: 0.40), width: 1.4),
          textStyle: textStyle,
          shape: shape,
        ),
      ),
    );
  }

  Color _colorForStatus(String status) {
    if (status == 'Expired') return Colors.redAccent;
    if (status == 'Reallocated') return const Color(0xFFEC4899);
    if (status == 'Job Completed') return const Color(0xFF7C3AED);
    if (status == 'Job Started') return const Color(0xFF14B8A6);
    if (status == 'Job Card') return const Color(0xFF64748B);
    if (status == 'Inspection') return const Color(0xFFF59E0B);
    if (status == 'Arrived') return const Color(0xFF8B5CF6);
    if (status == 'On The Way') return const Color(0xFF0EA5E9);
    if (status == 'Accepted') return AppColors.success;
    return AppColors.accent;
  }

  IconData _iconForStatus(String status) {
    if (status == 'Expired') return Icons.timer_off_outlined;
    if (status == 'Reallocated') return Icons.sync_problem_outlined;
    if (status == 'Job Completed') return Icons.verified_outlined;
    if (status == 'Job Started') return Icons.build_circle_outlined;
    if (status == 'Job Card') return Icons.assignment_outlined;
    if (status == 'Inspection') return Icons.search_rounded;
    if (status == 'Arrived') return Icons.location_on_outlined;
    if (status == 'On The Way') return Icons.delivery_dining_outlined;
    if (status == 'Accepted') return Icons.task_alt_outlined;
    return Icons.schedule_outlined;
  }

  Widget _refreshableEmptyState(String message) {
    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
          _EmptyState(message: message, onRetry: _loadBookings),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookings = _filteredBookings;
    return AppScaffold(
      title: 'Bookings',
      backgroundColor: AppColors.page,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: widget.onBack ?? () => Navigator.maybePop(context),
      ),
      body: Column(
        children: [
          _filterPanel(),
          Expanded(
            child: _isLoading
                ? const SkeletonCardList(
                    itemCount: 4,
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 110),
                  )
                : _error != null
                ? _refreshableEmptyState(_error!)
                : bookings.isEmpty
                ? _refreshableEmptyState(
                    _selectedTab == 'All'
                        ? 'No enquiries found for your selected services.'
                        : 'No $_selectedTab enquiries found for your selected services.',
                  )
                : RefreshIndicator(
                    onRefresh: _loadBookings,
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                      itemCount: bookings.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= bookings.length) {
                          return const _LoadingMore();
                        }
                        return _buildBookingCard(bookings[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: AppCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 42, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.35),
            ),
            const SizedBox(height: 14),
            SecondaryButton(
              label: 'Refresh',
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    ),
  );
}

class _LoadingMore extends StatelessWidget {
  const _LoadingMore();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: 16),
    child: Center(child: SkeletonInlineLoader(labelWidth: 132)),
  );
}

class _TabMeta {
  const _TabMeta(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

class _DropdownLabel extends StatelessWidget {
  const _DropdownLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 17, color: color),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ],
  );
}

class _AssignedStatus {
  const _AssignedStatus(this.enquiryStatus, this.technicianStatus);

  final String enquiryStatus;
  final String technicianStatus;
}
