import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/formatters.dart';
import '../../models/enums.dart';
import '../../models/lead.dart';
import '../../models/user.dart';
import '../../routes/app_router.dart';
import '../../services/lead_service.dart';
import '../../shared/widgets/state_views.dart';
import '../../theme/app_colors.dart';
import '../auth/auth_provider.dart';
import '../dashboard/dashboard_provider.dart' show ViewState;
import 'lead_detail_provider.dart';
import 'widgets/activity_timeline.dart';
import 'widgets/lead_action_sheets.dart';
import 'widgets/lead_chips.dart';

class LeadDetailsScreen extends StatefulWidget {
  const LeadDetailsScreen({super.key, required this.leadId});

  final String leadId;

  @override
  State<LeadDetailsScreen> createState() => _LeadDetailsScreenState();
}

class _LeadDetailsScreenState extends State<LeadDetailsScreen> {
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeadDetailProvider>().load();
    });
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.danger : AppColors.success,
      ),
    );
  }

  Future<void> _launch(Uri uri, String failureMessage) async {
    try {
      final bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        _toast(failureMessage, error: true);
      }
    } catch (_) {
      if (mounted) {
        _toast(failureMessage, error: true);
      }
    }
  }

  Future<void> _changeStatus(Lead lead) async {
    final String? status = await showStatusPicker(context, current: lead.status);
    if (status == null || !mounted) {
      return;
    }
    final String? error =
        await context.read<LeadDetailProvider>().changeStatus(status);
    if (!mounted) {
      return;
    }
    if (error == null) {
      _changed = true;
      _toast('Status changed to ${humanizeEnum(status)}');
    } else {
      _toast(error, error: true);
    }
  }

  Future<void> _assignAgent(Lead lead) async {
    List<AppUser> agents = <AppUser>[];
    try {
      agents = await context.read<LeadService>().fetchAgents();
    } catch (_) {
      if (mounted) {
        _toast('Could not load the agent list.', error: true);
      }
      return;
    }
    if (!mounted) {
      return;
    }
    final String? agentId = await showAgentPicker(
      context,
      agents: agents,
      currentAgentId: lead.assignedAgentId,
    );
    if (agentId == null || !mounted) {
      return;
    }
    final String? error =
        await context.read<LeadDetailProvider>().assignAgent(agentId);
    if (!mounted) {
      return;
    }
    if (error == null) {
      _changed = true;
      _toast('Lead assigned successfully');
    } else {
      _toast(error, error: true);
    }
  }

  Future<void> _addNote() async {
    final String? note = await showAddNoteSheet(context);
    if (note == null || !mounted) {
      return;
    }
    final String? error = await context.read<LeadDetailProvider>().addNote(note);
    if (!mounted) {
      return;
    }
    if (error == null) {
      _changed = true;
      _toast('Note added');
    } else {
      _toast(error, error: true);
    }
  }

  Future<void> _edit(Lead lead) async {
    final bool? saved = await Navigator.of(context)
        .pushNamed<bool>(AppRoutes.leadForm, arguments: lead);
    if (saved == true && mounted) {
      _changed = true;
      await context.read<LeadDetailProvider>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final LeadDetailProvider provider = context.watch<LeadDetailProvider>();
    final AppUser? user = context.watch<AuthProvider>().user;
    final Lead? lead = provider.lead;

    return Scaffold(
        appBar: AppBar(
          title: const Text('Lead Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_changed),
          ),
          actions: <Widget>[
            if (lead != null)
              IconButton(
                tooltip: 'Edit lead',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _edit(lead),
              ),
          ],
        ),
        body: _buildBody(provider, lead, user),
        floatingActionButton: lead == null
            ? null
            : FloatingActionButton.extended(
                onPressed: provider.isBusy ? null : _addNote,
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                icon: const Icon(Icons.note_add_outlined),
                label: const Text('ADD NOTE'),
              ),
    );
  }

  Widget _buildBody(LeadDetailProvider provider, Lead? lead, AppUser? user) {
    if (provider.state == ViewState.loading || provider.state == ViewState.idle) {
      return const LoadingView();
    }
    if (provider.state == ViewState.error || lead == null) {
      return ErrorView(
        message: provider.errorMessage ?? 'This lead could not be loaded.',
        onRetry: provider.load,
      );
    }

    return RefreshIndicator(
      onRefresh: provider.load,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: <Widget>[
          _HeaderCard(
            lead: lead,
            onCall: () => _launch(
              Uri(scheme: 'tel', path: lead.phone),
              'No dialer app available on this device.',
            ),
            onWhatsApp: () => _launch(
              Uri.parse(
                'https://wa.me/${(lead.whatsapp ?? lead.phone).replaceAll(RegExp(r'[^0-9]'), '')}',
              ),
              'WhatsApp is not available on this device.',
            ),
            onChangeStatus: () => _changeStatus(lead),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Customer information',
            child: Column(
              children: <Widget>[
                LabelValueRow(label: 'Phone', value: lead.phone),
                LabelValueRow(label: 'WhatsApp', value: lead.whatsapp ?? '-'),
                LabelValueRow(label: 'Email', value: lead.email ?? '-'),
                LabelValueRow(label: 'Created', value: Formatters.date(lead.createdAt)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Requirement',
            child: Column(
              children: <Widget>[
                LabelValueRow(
                  label: 'Property',
                  value: Formatters.requirement(
                    propertyType: lead.propertyType,
                    bedrooms: lead.bedrooms,
                  ),
                ),
                LabelValueRow(
                  label: 'Budget',
                  value: Formatters.budgetRange(lead.budgetMin, lead.budgetMax),
                ),
                LabelValueRow(label: 'Location', value: lead.preferredLocation ?? '-'),
                LabelValueRow(label: 'Purpose', value: humanizeEnum(lead.purpose)),
                LabelValueRow(label: 'Project', value: lead.projectName ?? '-'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Pipeline',
            trailing: (user?.canAssignLeads ?? false)
                ? TextButton(
                    onPressed: provider.isBusy ? null : () => _assignAgent(lead),
                    child: Text(
                      lead.assignedAgentId == null ? 'Assign' : 'Reassign',
                    ),
                  )
                : null,
            child: Column(
              children: <Widget>[
                LabelValueRow(label: 'Source', value: humanizeEnum(lead.source)),
                LabelValueRow(label: 'Campaign', value: lead.campaign ?? '-'),
                LabelValueRow(label: 'Lead score', value: '${lead.leadScore}'),
                LabelValueRow(
                  label: 'Assigned agent',
                  value: lead.assignedAgent?.fullName ?? 'Unassigned',
                ),
                LabelValueRow(
                  label: 'Last contacted',
                  value: Formatters.date(lead.lastContactedAt),
                ),
                LabelValueRow(
                  label: 'Next follow-up',
                  value: Formatters.date(lead.nextFollowupAt),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Notes (${provider.notes.length})',
            child: provider.notes.isEmpty
                ? const Text(
                    'No notes yet. Use ADD NOTE to record a conversation.',
                    style: TextStyle(color: AppColors.textSecondary),
                  )
                : Column(
                    children: provider.notes
                        .map((LeadNote note) => _NoteTile(note: note))
                        .toList(),
                  ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Activity timeline',
            child: ActivityTimeline(activities: provider.activities),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.lead,
    required this.onCall,
    required this.onWhatsApp,
    required this.onChangeStatus,
  });

  final Lead lead;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback onChangeStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            lead.fullName,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            lead.phone,
            style: const TextStyle(color: AppColors.goldLight, fontSize: 14),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              InkWell(
                onTap: onChangeStatus,
                borderRadius: BorderRadius.circular(20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    StatusChip(status: lead.status),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, color: AppColors.white, size: 20),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              PriorityChip(priority: lead.priority),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.call, size: 18),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.white,
                    side: const BorderSide(color: AppColors.gold),
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  label: const Text('CALL'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onWhatsApp,
                  icon: const Icon(Icons.chat_outlined, size: 18),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(46),
                  ),
                  label: const Text('WHATSAPP'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.note});

  final LeadNote note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            note.note,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            '${note.user?.fullName ?? 'Unknown'} - ${Formatters.timestamp(note.createdAt)}',
            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
