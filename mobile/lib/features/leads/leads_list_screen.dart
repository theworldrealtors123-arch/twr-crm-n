import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/lead.dart';
import '../../models/user.dart';
import '../../routes/app_router.dart';
import '../../services/lead_service.dart';
import '../../shared/widgets/state_views.dart';
import '../../theme/app_colors.dart';
import '../auth/auth_provider.dart';
import '../dashboard/dashboard_provider.dart' show ViewState;
import 'leads_provider.dart';
import 'widgets/lead_card.dart';
import 'widgets/lead_filter_sheet.dart';

class LeadsListScreen extends StatefulWidget {
  const LeadsListScreen({super.key});

  @override
  State<LeadsListScreen> createState() => _LeadsListScreenState();
}

class _LeadsListScreenState extends State<LeadsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeadsProvider>().refresh();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      context.read<LeadsProvider>().loadMore();
    }
  }

  Future<void> _openFilters() async {
    final LeadsProvider leads = context.read<LeadsProvider>();
    final AppUser? user = context.read<AuthProvider>().user;
    List<AppUser> agents = <AppUser>[];
    if (user != null && user.canAssignLeads) {
      try {
        agents = await leads.agents();
      } catch (_) {
        agents = <AppUser>[];
      }
    }
    if (!mounted) {
      return;
    }
    final LeadFilters? result = await showLeadFilterSheet(
      context,
      current: leads.filters,
      agents: agents,
      canFilterByAgent: user?.canAssignLeads ?? false,
    );
    if (result != null) {
      leads.applyFilters(result);
    }
  }

  Future<void> _openLead(Lead lead) async {
    final bool? changed = await Navigator.of(context).pushNamed<bool>(
      AppRoutes.leadDetails,
      arguments: lead.id,
    );
    if (changed == true && mounted) {
      context.read<LeadsProvider>().refresh();
    }
  }

  Future<void> _createLead() async {
    final bool? created =
        await Navigator.of(context).pushNamed<bool>(AppRoutes.leadForm);
    if (created == true && mounted) {
      context.read<LeadsProvider>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final LeadsProvider leads = context.watch<LeadsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leads'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: leads.refresh,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('create_lead_fab'),
        onPressed: _createLead,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('NEW LEAD'),
      ),
      body: Column(
        children: <Widget>[
          _SearchBar(
            controller: _searchController,
            filterCount: leads.filters.activeCount,
            onChanged: leads.onSearchChanged,
            onFilterPressed: _openFilters,
            onClear: () {
              _searchController.clear();
              leads.onSearchChanged('');
            },
          ),
          if (!leads.filters.isEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: TextButton.icon(
                  onPressed: leads.clearFilters,
                  icon: const Icon(Icons.close, size: 16),
                  label: Text('Clear ${leads.filters.activeCount} filter(s)'),
                ),
              ),
            ),
          Expanded(child: _buildBody(leads)),
        ],
      ),
    );
  }

  Widget _buildBody(LeadsProvider leads) {
    if (leads.state == ViewState.loading && leads.isEmpty) {
      return const LoadingView(message: 'Loading leads');
    }
    if (leads.state == ViewState.error && leads.isEmpty) {
      return ErrorView(
        message: leads.errorMessage ?? 'Something went wrong.',
        onRetry: leads.refresh,
      );
    }
    if (leads.isEmpty) {
      final bool filtering =
          leads.search.trim().isNotEmpty || !leads.filters.isEmpty;
      return EmptyView(
        title: filtering ? 'No leads match your search' : 'No leads yet',
        message: filtering
            ? 'Try a different search term or clear your filters.'
            : 'Create your first lead to start building the pipeline.',
        icon: filtering ? Icons.search_off : Icons.people_outline,
        actionLabel: filtering ? null : 'CREATE LEAD',
        onAction: filtering ? null : _createLead,
      );
    }

    return RefreshIndicator(
      onRefresh: leads.refresh,
      color: AppColors.primary,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: leads.leads.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          if (index == leads.leads.length) {
            if (leads.isLoadingMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  'Showing ${leads.leads.length} of ${leads.total} leads',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12.5),
                ),
              ),
            );
          }
          final Lead lead = leads.leads[index];
          return LeadCard(lead: lead, onTap: () => _openLead(lead));
        },
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.filterCount,
    required this.onChanged,
    required this.onFilterPressed,
    required this.onClear,
  });

  final TextEditingController controller;
  final int filterCount;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterPressed;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              key: const Key('lead_search_field'),
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search name, phone or email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(icon: const Icon(Icons.close), onPressed: onClear),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  key: const Key('lead_filter_button'),
                  onPressed: onFilterPressed,
                  icon: const Icon(Icons.tune, color: AppColors.white),
                ),
              ),
              if (filterCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$filterCount',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
