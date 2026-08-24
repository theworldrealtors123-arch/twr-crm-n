import '../core/network/api_client.dart';
import '../models/lead.dart';
import '../models/paginated.dart';
import '../models/user.dart';

class LeadFilters {
  const LeadFilters({
    this.status,
    this.priority,
    this.source,
    this.propertyType,
    this.assignedAgentId,
  });

  final String? status;
  final String? priority;
  final String? source;
  final String? propertyType;
  final String? assignedAgentId;

  bool get isEmpty =>
      status == null &&
      priority == null &&
      source == null &&
      propertyType == null &&
      assignedAgentId == null;

  int get activeCount => <String?>[
        status,
        priority,
        source,
        propertyType,
        assignedAgentId,
      ].where((String? value) => value != null).length;

  LeadFilters copyWith({
    String? status,
    String? priority,
    String? source,
    String? propertyType,
    String? assignedAgentId,
    bool clear = false,
  }) {
    if (clear) {
      return const LeadFilters();
    }
    return LeadFilters(
      status: status ?? this.status,
      priority: priority ?? this.priority,
      source: source ?? this.source,
      propertyType: propertyType ?? this.propertyType,
      assignedAgentId: assignedAgentId ?? this.assignedAgentId,
    );
  }

  Map<String, dynamic> toQuery() {
    final Map<String, dynamic> query = <String, dynamic>{};
    if (status != null) query['status'] = status;
    if (priority != null) query['priority'] = priority;
    if (source != null) query['source'] = source;
    if (propertyType != null) query['propertyType'] = propertyType;
    if (assignedAgentId != null) query['assignedAgentId'] = assignedAgentId;
    return query;
  }
}

class LeadService {
  LeadService({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<Paginated<Lead>> fetchLeads({
    int page = 1,
    int limit = 20,
    String? search,
    LeadFilters filters = const LeadFilters(),
  }) async {
    final Map<String, dynamic> query = <String, dynamic>{
      'page': page,
      'limit': limit,
      ...filters.toQuery(),
    };
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    final dynamic data = await _client.get('/leads', queryParameters: query);
    return Paginated.fromJson<Lead>(
      Map<String, dynamic>.from(data as Map<dynamic, dynamic>),
      Lead.fromJson,
    );
  }

  Future<Lead> fetchLead(String id) async {
    final dynamic data = await _client.get('/leads/$id');
    return Lead.fromJson(Map<String, dynamic>.from(data as Map<dynamic, dynamic>));
  }

  Future<Lead> createLead(Map<String, dynamic> payload) async {
    final dynamic data = await _client.post('/leads', data: payload);
    return Lead.fromJson(Map<String, dynamic>.from(data as Map<dynamic, dynamic>));
  }

  Future<Lead> updateLead(String id, Map<String, dynamic> payload) async {
    final dynamic data = await _client.patch('/leads/$id', data: payload);
    return Lead.fromJson(Map<String, dynamic>.from(data as Map<dynamic, dynamic>));
  }

  Future<Lead> changeStatus(String id, String status, {String? note}) async {
    final Map<String, dynamic> payload = <String, dynamic>{'status': status};
    if (note != null && note.trim().isNotEmpty) {
      payload['note'] = note.trim();
    }
    final dynamic data = await _client.patch('/leads/$id/status', data: payload);
    return Lead.fromJson(Map<String, dynamic>.from(data as Map<dynamic, dynamic>));
  }

  Future<Lead> assignAgent(String id, String agentId) async {
    final dynamic data = await _client
        .patch('/leads/$id/assign', data: <String, dynamic>{'agentId': agentId});
    return Lead.fromJson(Map<String, dynamic>.from(data as Map<dynamic, dynamic>));
  }

  Future<List<LeadNote>> fetchNotes(String id) async {
    final dynamic data = await _client.get('/leads/$id/notes');
    return (data as List<dynamic>)
        .map((dynamic e) =>
            LeadNote.fromJson(Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
        .toList();
  }

  Future<LeadNote> addNote(String id, String note) async {
    final dynamic data =
        await _client.post('/leads/$id/notes', data: <String, dynamic>{'note': note});
    return LeadNote.fromJson(
        Map<String, dynamic>.from(data as Map<dynamic, dynamic>));
  }

  Future<List<LeadActivity>> fetchActivities(String id) async {
    final dynamic data = await _client.get('/leads/$id/activities');
    return (data as List<dynamic>)
        .map((dynamic e) => LeadActivity.fromJson(
            Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
        .toList();
  }

  Future<List<AppUser>> fetchAgents() async {
    final dynamic data = await _client.get('/users/agents');
    return (data as List<dynamic>)
        .map((dynamic e) =>
            AppUser.fromJson(Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
        .toList();
  }
}
