import 'package:flutter/material.dart';

import '../../../models/enums.dart';
import '../../../models/user.dart';
import '../../../services/lead_service.dart';
import '../../../theme/app_colors.dart';

/// Bottom sheet returning the chosen [LeadFilters], or null when dismissed.
Future<LeadFilters?> showLeadFilterSheet(
  BuildContext context, {
  required LeadFilters current,
  required List<AppUser> agents,
  required bool canFilterByAgent,
}) {
  return showModalBottomSheet<LeadFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (BuildContext context) => _LeadFilterSheet(
      current: current,
      agents: agents,
      canFilterByAgent: canFilterByAgent,
    ),
  );
}

class _LeadFilterSheet extends StatefulWidget {
  const _LeadFilterSheet({
    required this.current,
    required this.agents,
    required this.canFilterByAgent,
  });

  final LeadFilters current;
  final List<AppUser> agents;
  final bool canFilterByAgent;

  @override
  State<_LeadFilterSheet> createState() => _LeadFilterSheetState();
}

class _LeadFilterSheetState extends State<_LeadFilterSheet> {
  String? _status;
  String? _priority;
  String? _source;
  String? _propertyType;
  String? _agentId;

  @override
  void initState() {
    super.initState();
    _status = widget.current.status;
    _priority = widget.current.priority;
    _source = widget.current.source;
    _propertyType = widget.current.propertyType;
    _agentId = widget.current.assignedAgentId;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: <Widget>[
                    const Text(
                      'Filter leads',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setState(() {
                        _status = null;
                        _priority = null;
                        _source = null;
                        _propertyType = null;
                        _agentId = null;
                      }),
                      child: const Text('Clear all'),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _FilterGroup(
                        label: 'Status',
                        options: LeadStatus.all,
                        selected: _status,
                        onSelected: (String? value) => setState(() => _status = value),
                      ),
                      _FilterGroup(
                        label: 'Priority',
                        options: LeadPriority.all,
                        selected: _priority,
                        onSelected: (String? value) => setState(() => _priority = value),
                      ),
                      _FilterGroup(
                        label: 'Source',
                        options: LeadSource.all,
                        selected: _source,
                        onSelected: (String? value) => setState(() => _source = value),
                      ),
                      _FilterGroup(
                        label: 'Property type',
                        options: PropertyType.all,
                        selected: _propertyType,
                        onSelected: (String? value) =>
                            setState(() => _propertyType = value),
                      ),
                      if (widget.canFilterByAgent && widget.agents.isNotEmpty)
                        _FilterGroup(
                          label: 'Assigned agent',
                          options: widget.agents.map((AppUser a) => a.id).toList(),
                          labelBuilder: (String id) => widget.agents
                              .firstWhere((AppUser a) => a.id == id)
                              .fullName,
                          selected: _agentId,
                          onSelected: (String? value) => setState(() => _agentId = value),
                        ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(
                    LeadFilters(
                      status: _status,
                      priority: _priority,
                      source: _source,
                      propertyType: _propertyType,
                      assignedAgentId: _agentId,
                    ),
                  ),
                  child: const Text('APPLY FILTERS'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterGroup extends StatelessWidget {
  const _FilterGroup({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.labelBuilder,
  });

  final String label;
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final String Function(String value)? labelBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 10),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((String option) {
            final bool isSelected = option == selected;
            return ChoiceChip(
              label: Text(
                labelBuilder != null ? labelBuilder!(option) : humanizeEnum(option),
              ),
              selected: isSelected,
              onSelected: (bool value) => onSelected(value ? option : null),
              backgroundColor: AppColors.lightGrey,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.white : AppColors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.border),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}
