import 'package:flutter/foundation.dart';

import '../../core/errors/api_exception.dart';
import '../../models/lead.dart';
import '../../services/lead_service.dart';
import '../dashboard/dashboard_provider.dart' show ViewState;

class LeadDetailProvider extends ChangeNotifier {
  LeadDetailProvider({required LeadService leadService, required this.leadId})
      : _leadService = leadService;

  final LeadService _leadService;
  final String leadId;

  ViewState _state = ViewState.idle;
  Lead? _lead;
  List<LeadNote> _notes = <LeadNote>[];
  List<LeadActivity> _activities = <LeadActivity>[];
  String? _errorMessage;
  bool _busy = false;

  ViewState get state => _state;
  Lead? get lead => _lead;
  List<LeadNote> get notes => List<LeadNote>.unmodifiable(_notes);
  List<LeadActivity> get activities => List<LeadActivity>.unmodifiable(_activities);
  String? get errorMessage => _errorMessage;
  bool get isBusy => _busy;

  Future<void> load() async {
    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
        _leadService.fetchLead(leadId),
        _leadService.fetchNotes(leadId),
        _leadService.fetchActivities(leadId),
      ]);
      _lead = results[0] as Lead;
      _notes = results[1] as List<LeadNote>;
      _activities = results[2] as List<LeadActivity>;
      _state = ViewState.ready;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _state = ViewState.error;
    } catch (_) {
      _errorMessage = 'Unable to connect. Please try again.';
      _state = ViewState.error;
    }
    notifyListeners();
  }

  Future<String?> changeStatus(String status) async {
    return _mutate(() => _leadService.changeStatus(leadId, status));
  }

  Future<String?> assignAgent(String agentId) async {
    return _mutate(() => _leadService.assignAgent(leadId, agentId));
  }

  Future<String?> addNote(String note) async {
    return _mutate(() async {
      await _leadService.addNote(leadId, note);
      return _leadService.fetchLead(leadId);
    });
  }

  /// Runs a mutation, then reloads notes and the timeline so the UI always
  /// reflects what the database actually stored.
  Future<String?> _mutate(Future<Lead> Function() action) async {
    _busy = true;
    notifyListeners();
    try {
      _lead = await action();
      _notes = await _leadService.fetchNotes(leadId);
      _activities = await _leadService.fetchActivities(leadId);
      return null;
    } on ApiException catch (error) {
      return error.message;
    } catch (_) {
      return 'Unable to connect. Please try again.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
