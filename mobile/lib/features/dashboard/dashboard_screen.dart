import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../models/dashboard_stats.dart';
import '../../models/enums.dart';
import '../../shared/widgets/state_views.dart';
import '../../shared/widgets/app_card.dart';
import '../../theme/app_colors.dart';
import '../auth/auth_provider.dart';
import 'dashboard_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.onSeeAllLeads});

  final VoidCallback? onSeeAllLeads;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final DashboardProvider dashboard = context.watch<DashboardProvider>();
    final AuthProvider auth = context.watch<AuthProvider>();
    final String firstName = auth.user?.firstName ?? '';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: dashboard.load,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: _Header(
                  greeting: Formatters.greeting(DateTime.now()),
                  name: firstName,
                  role: auth.user?.role ?? '',
                  initials: auth.user?.initials ?? '',
                ),
              ),
              if (dashboard.state == ViewState.loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: LoadingView(message: 'Loading your pipeline'),
                )
              else if (dashboard.state == ViewState.error)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorView(
                    message: dashboard.errorMessage ?? 'Something went wrong.',
                    onRetry: dashboard.load,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(<Widget>[
                      _StatGrid(stats: dashboard.stats),
                      const SizedBox(height: 20),
                      _PipelineCard(
                        stats: dashboard.stats,
                        onSeeAll: widget.onSeeAllLeads,
                      ),
                    ]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.greeting,
    required this.name,
    required this.role,
    required this.initials,
  });

  final String greeting;
  final String name;
  final String role;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 34),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '$greeting,',
                  style: const TextStyle(color: AppColors.goldLight, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  name.isEmpty ? 'Welcome' : name,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  humanizeEnum(role),
                  style: const TextStyle(color: AppColors.goldLight, fontSize: 12.5),
                ),
              ],
            ),
          ),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.alpha(AppColors.white, 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 1.4),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final List<_StatData> items = <_StatData>[
      _StatData('TOTAL LEADS', stats.totalLeads, Icons.groups_outlined, AppColors.primary),
      _StatData('NEW LEADS', stats.newLeads, Icons.fiber_new_outlined, AppColors.royalBlue),
      _StatData('HOT LEADS', stats.hotLeads, Icons.local_fire_department_outlined, AppColors.hot),
      _StatData('FOLLOW-UPS', stats.followUps, Icons.event_available_outlined, AppColors.gold),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = (constraints.maxWidth - 14) / 2;
        return Transform.translate(
          offset: const Offset(0, -18),
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: items
                .map((_StatData item) => SizedBox(
                      width: width,
                      child: _StatCard(data: item),
                    ))
                .toList(),
          ),
        );
      },
    );
  }
}

class _StatData {
  const _StatData(this.label, this.value, this.icon, this.color);

  final String label;
  final int value;
  final IconData icon;
  final Color color;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatData data;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.alpha(data.color, 0.10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(data.icon, color: data.color, size: 20),
            ),
            const SizedBox(height: 14),
            Text(
              '${data.value}',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              data.label,
              style: const TextStyle(
                fontSize: 11,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

class _PipelineCard extends StatelessWidget {
  const _PipelineCard({required this.stats, this.onSeeAll});

  final DashboardStats stats;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, int>> entries = stats.byStatus.entries.toList()
      ..sort((MapEntry<String, int> a, MapEntry<String, int> b) =>
          b.value.compareTo(a.value));

    return SectionCard(
      title: 'Pipeline by status',
      trailing: onSeeAll == null
          ? null
          : TextButton(onPressed: onSeeAll, child: const Text('See all')),
      child: entries.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No leads yet. Create your first lead from the Leads tab.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : Column(
              children: entries.map((MapEntry<String, int> entry) {
                final double fraction =
                    stats.totalLeads == 0 ? 0 : entry.value / stats.totalLeads;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            humanizeEnum(entry.key),
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${entry.value}',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: fraction,
                          minHeight: 6,
                          backgroundColor: AppColors.lightGrey,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}
