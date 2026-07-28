import 'package:flutter/material.dart';
import 'package:sahubyte_vendor/model/response/problem_response.dart';
import 'package:sahubyte_vendor/view/app_ui.dart';
import 'package:sahubyte_vendor/view_model/technician_view_model.dart';

class ProblemListView extends StatefulWidget {
  const ProblemListView({
    super.key,
    this.problemIds = const ['1', '2', '3', '4'],
  });

  final List<String> problemIds;

  @override
  State<ProblemListView> createState() => _ProblemListViewState();
}

class _ProblemListViewState extends State<ProblemListView> {
  final _viewModel = TechnicianViewModel();
  final _searchController = TextEditingController();

  List<ProblemModel> _problems = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProblems();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProblems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _viewModel.getProblems(widget.problemIds);
      if (!mounted) return;
      if (!response.isSuccess) {
        setState(() {
          _error = response.message ?? 'Unable to load problems.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _problems = response.data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = professionalErrorMessage(
          e,
          fallback: 'Problems could not be refreshed. Please try again.',
        );
        _isLoading = false;
      });
    }
  }

  List<ProblemModel> get _filteredProblems {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _problems;
    return _problems
        .where((problem) => problem.problemName.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredProblems = _filteredProblems;

    return AppScaffold(
      title: 'All Problem List',
      backgroundColor: AppColors.page,
      actions: [
        IconButton(
          onPressed: _loadProblems,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh',
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _loadProblems,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: appPadding,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'All Problem List',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Add Problem API not provided yet.',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5A2A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search problem',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const SkeletonCardList(
                      itemCount: 4,
                      padding: EdgeInsets.zero,
                    )
                  else if (_error != null)
                    EmptyState(
                      icon: Icons.error_outline_rounded,
                      title: 'Could not load problems',
                      message: _error!,
                    )
                  else if (filteredProblems.isEmpty)
                    const EmptyState(
                      icon: Icons.list_alt_outlined,
                      title: 'No problems found',
                      message:
                          'Try another search keyword or refresh the list.',
                    )
                  else
                    ...List.generate(filteredProblems.length, (index) {
                      final problem = filteredProblems[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: index.isEven
                              ? const Color(0xFFFAFBFC)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 32,
                              child: Text(
                                problem.id,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                problem.problemName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Edit',
                              color: const Color(0xFFFF5A2A),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
