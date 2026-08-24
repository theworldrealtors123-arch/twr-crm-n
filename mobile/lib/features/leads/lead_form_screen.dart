import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/errors/api_exception.dart';
import '../../core/utils/validators.dart';
import '../../models/enums.dart';
import '../../models/lead.dart';
import '../../models/user.dart';
import '../../services/lead_service.dart';
import '../../theme/app_colors.dart';
import '../auth/auth_provider.dart';

/// Create (when [lead] is null) or edit an existing lead.
/// Pops with `true` when the database was successfully written.
class LeadFormScreen extends StatefulWidget {
  const LeadFormScreen({super.key, this.lead});

  final Lead? lead;

  bool get isEditing => lead != null;

  @override
  State<LeadFormScreen> createState() => _LeadFormScreenState();
}

class _LeadFormScreenState extends State<LeadFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullName;
  late final TextEditingController _phone;
  late final TextEditingController _whatsapp;
  late final TextEditingController _email;
  late final TextEditingController _bedrooms;
  late final TextEditingController _budgetMin;
  late final TextEditingController _budgetMax;
  late final TextEditingController _location;
  late final TextEditingController _campaign;
  late final TextEditingController _project;
  late final TextEditingController _leadScore;

  String? _propertyType;
  String? _purpose;
  String _source = 'MANUAL';
  String _status = LeadStatus.newLead;
  String _priority = LeadPriority.warm;
  String? _assignedAgentId;

  List<AppUser> _agents = <AppUser>[];
  bool _loadingAgents = false;
  bool _saving = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    final Lead? lead = widget.lead;
    _fullName = TextEditingController(text: lead?.fullName ?? '');
    _phone = TextEditingController(text: lead?.phone ?? '');
    _whatsapp = TextEditingController(text: lead?.whatsapp ?? '');
    _email = TextEditingController(text: lead?.email ?? '');
    _bedrooms = TextEditingController(text: lead?.bedrooms?.toString() ?? '');
    _budgetMin =
        TextEditingController(text: lead?.budgetMin?.toStringAsFixed(0) ?? '');
    _budgetMax =
        TextEditingController(text: lead?.budgetMax?.toStringAsFixed(0) ?? '');
    _location = TextEditingController(text: lead?.preferredLocation ?? '');
    _campaign = TextEditingController(text: lead?.campaign ?? '');
    _project = TextEditingController(text: lead?.projectName ?? '');
    _leadScore = TextEditingController(text: lead?.leadScore.toString() ?? '');

    _propertyType = lead?.propertyType;
    _purpose = lead?.purpose;
    _source = lead?.source ?? 'MANUAL';
    _status = lead?.status ?? LeadStatus.newLead;
    _priority = lead?.priority ?? LeadPriority.warm;
    _assignedAgentId = lead?.assignedAgentId;

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAgents());
  }

  @override
  void dispose() {
    for (final TextEditingController controller in <TextEditingController>[
      _fullName,
      _phone,
      _whatsapp,
      _email,
      _bedrooms,
      _budgetMin,
      _budgetMax,
      _location,
      _campaign,
      _project,
      _leadScore,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAgents() async {
    final AppUser? user = context.read<AuthProvider>().user;
    if (user == null || !user.canAssignLeads) {
      return;
    }
    setState(() => _loadingAgents = true);
    try {
      final List<AppUser> agents = await context.read<LeadService>().fetchAgents();
      if (mounted) {
        setState(() => _agents = agents);
      }
    } catch (_) {
      // Assignment simply stays unavailable if the list cannot be fetched.
    } finally {
      if (mounted) {
        setState(() => _loadingAgents = false);
      }
    }
  }

  Map<String, dynamic> _buildPayload() {
    String? text(TextEditingController controller) {
      final String value = controller.text.trim();
      return value.isEmpty ? null : value;
    }

    final Map<String, dynamic> payload = <String, dynamic>{
      'fullName': _fullName.text.trim(),
      'phone': _phone.text.trim(),
      'status': _status,
      'priority': _priority,
      'source': _source,
    };

    void put(String key, dynamic value) {
      if (value != null) {
        payload[key] = value;
      }
    }

    put('whatsapp', text(_whatsapp));
    put('email', text(_email));
    put('propertyType', _propertyType);
    put('purpose', _purpose);
    put('preferredLocation', text(_location));
    put('campaign', text(_campaign));
    put('projectName', text(_project));
    put('bedrooms', int.tryParse(_bedrooms.text.trim()));
    put('budgetMin', double.tryParse(_budgetMin.text.trim()));
    put('budgetMax', double.tryParse(_budgetMax.text.trim()));
    put('leadScore', int.tryParse(_leadScore.text.trim()));
    put('assignedAgentId', _assignedAgentId);

    return payload;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _formError = null);

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final String? budgetError =
        Validators.budgetRange(_budgetMin.text, _budgetMax.text);
    if (budgetError != null) {
      setState(() => _formError = budgetError);
      return;
    }

    setState(() => _saving = true);
    final LeadService service = context.read<LeadService>();

    try {
      if (widget.isEditing) {
        await service.updateLead(widget.lead!.id, _buildPayload());
      } else {
        await service.createLead(_buildPayload());
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            widget.isEditing
                ? 'Lead updated successfully'
                : 'Lead created successfully',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _formError = error.fieldErrors?.join('\n') ?? error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _formError = 'Unable to connect. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppUser? user = context.watch<AuthProvider>().user;
    final bool canAssign = user?.canAssignLeads ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit Lead' : 'Create Lead')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
            children: <Widget>[
              _sectionTitle('Customer information'),
              TextFormField(
                key: const Key('lead_full_name_field'),
                controller: _fullName,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Full name *'),
                validator: (String? value) =>
                    Validators.requiredField(value, 'Full name'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('lead_phone_field'),
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone *'),
                validator: (String? value) => Validators.phone(value),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _whatsapp,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'WhatsApp'),
                validator: (String? value) => Validators.phone(value, required: false),
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('lead_email_field'),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (String? value) => Validators.email(value),
              ),

              const SizedBox(height: 26),
              _sectionTitle('Requirement'),
              _dropdown(
                label: 'Property type',
                value: _propertyType,
                options: PropertyType.all,
                onChanged: (String? value) => setState(() => _propertyType = value),
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('lead_bedrooms_field'),
                controller: _bedrooms,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(labelText: 'Bedrooms'),
                validator: (String? value) => Validators.integer(value, 'Bedrooms'),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      key: const Key('lead_budget_min_field'),
                      controller: _budgetMin,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Min budget'),
                      validator: (String? value) =>
                          Validators.numeric(value, 'Minimum budget'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      key: const Key('lead_budget_max_field'),
                      controller: _budgetMax,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Max budget'),
                      validator: (String? value) =>
                          Validators.numeric(value, 'Maximum budget'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _location,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Preferred location'),
              ),
              const SizedBox(height: 14),
              _dropdown(
                label: 'Purpose',
                value: _purpose,
                options: LeadPurpose.all,
                onChanged: (String? value) => setState(() => _purpose = value),
              ),

              const SizedBox(height: 26),
              _sectionTitle('Pipeline'),
              _dropdown(
                label: 'Source',
                value: _source,
                options: LeadSource.all,
                allowEmpty: false,
                onChanged: (String? value) =>
                    setState(() => _source = value ?? 'MANUAL'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _campaign,
                decoration: const InputDecoration(labelText: 'Campaign'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _project,
                decoration: const InputDecoration(labelText: 'Project'),
              ),
              const SizedBox(height: 14),
              _dropdown(
                label: 'Status',
                value: _status,
                options: LeadStatus.all,
                allowEmpty: false,
                onChanged: (String? value) =>
                    setState(() => _status = value ?? LeadStatus.newLead),
              ),
              const SizedBox(height: 14),
              _dropdown(
                label: 'Priority',
                value: _priority,
                options: LeadPriority.all,
                allowEmpty: false,
                onChanged: (String? value) =>
                    setState(() => _priority = value ?? LeadPriority.warm),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _leadScore,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(labelText: 'Lead score (0-100)'),
                validator: (String? value) {
                  final String? error = Validators.integer(value, 'Lead score');
                  if (error != null) {
                    return error;
                  }
                  final int? score = int.tryParse(value?.trim() ?? '');
                  if (score != null && (score < 0 || score > 100)) {
                    return 'Lead score must be between 0 and 100';
                  }
                  return null;
                },
              ),

              if (canAssign) ...<Widget>[
                const SizedBox(height: 26),
                _sectionTitle('Assignment'),
                if (_loadingAgents)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: LinearProgressIndicator(minHeight: 3),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: _assignedAgentId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Assigned agent'),
                    items: <DropdownMenuItem<String>>[
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Unassigned'),
                      ),
                      ..._agents.map(
                        (AppUser agent) => DropdownMenuItem<String>(
                          value: agent.id,
                          child: Text(agent.fullName),
                        ),
                      ),
                    ],
                    onChanged: (String? value) =>
                        setState(() => _assignedAgentId = value),
                  ),
              ],

              if (_formError != null) ...<Widget>[
                const SizedBox(height: 20),
                Container(
                  key: const Key('lead_form_error'),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.alpha(AppColors.danger, 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formError!,
                    style: const TextStyle(color: AppColors.danger, fontSize: 13.5),
                  ),
                ),
              ],

              const SizedBox(height: 28),
              ElevatedButton(
                key: const Key('lead_submit_button'),
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2.4,
                        ),
                      )
                    : Text(widget.isEditing ? 'SAVE CHANGES' : 'CREATE LEAD'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    bool allowEmpty = true,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: <DropdownMenuItem<String>>[
        if (allowEmpty)
          const DropdownMenuItem<String>(value: null, child: Text('Not set')),
        ...options.map(
          (String option) => DropdownMenuItem<String>(
            value: option,
            child: Text(humanizeEnum(option)),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}
