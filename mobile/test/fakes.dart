import 'package:twr_crm/core/errors/api_exception.dart';
import 'package:twr_crm/models/dashboard_stats.dart';
import 'package:twr_crm/models/lead.dart';
import 'package:twr_crm/models/paginated.dart';
import 'package:twr_crm/models/user.dart';
import 'package:twr_crm/services/auth_service.dart';
import 'package:twr_crm/services/dashboard_service.dart';
import 'package:twr_crm/services/lead_service.dart';
import 'package:twr_crm/services/secure_storage_service.dart';

/// Test doubles. Nothing here touches the network or the keychain, so the
/// widget tests are deterministic and run offline.

final AppUser testManager = const AppUser(
  id: 'user-manager',
  firstName: 'Khalid',
  lastName: 'Rahman',
  email: 'manager@twrrealestate.ae',
  role: 'SALES_MANAGER',
  permissions: <String>['lead.view.team', 'lead.assign', 'dashboard.view'],
);

final AppUser testAgent = const AppUser(
  id: 'user-agent',
  firstName: 'Ali',
  lastName: 'Hassan',
  email: 'ali.agent@twrrealestate.ae',
  role: 'AGENT',
  permissions: <String>['lead.view.own', 'dashboard.view'],
);

Lead buildLead({
  String id = 'lead-1',
  String fullName = 'Ahmed Khan',
  String phone = '+971501110001',
  String status = 'NEW',
  String priority = 'HOT',
  int? bedrooms = 2,
  double? budgetMin = 1300000,
  double? budgetMax = 1600000,
  AppUser? agent,
}) {
  return Lead(
    id: id,
    fullName: fullName,
    phone: phone,
    status: status,
    priority: priority,
    source: 'META_ADS',
    createdAt: DateTime(2026, 8, 24, 10, 15),
    propertyType: 'APARTMENT',
    bedrooms: bedrooms,
    budgetMin: budgetMin,
    budgetMax: budgetMax,
    preferredLocation: 'Dubai Marina',
    assignedAgentId: agent?.id,
    assignedAgent: agent,
  );
}

class FakeSecureStorage implements SecureStorageService {
  String? accessToken;
  String? refreshToken;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
  }
}

class FakeAuthService implements AuthService {
  FakeAuthService({this.user, this.failWith, this.storedSession = false});

  AppUser? user;
  ApiException? failWith;
  bool storedSession;
  int loginCalls = 0;
  int logoutCalls = 0;

  @override
  Future<AppUser> login({required String email, required String password}) async {
    loginCalls++;
    if (failWith != null) {
      throw failWith!;
    }
    return user ?? testManager;
  }

  @override
  Future<AppUser> me() async {
    if (failWith != null) {
      throw failWith!;
    }
    return user ?? testManager;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    user = null;
    storedSession = false;
  }

  @override
  Future<bool> hasStoredSession() async => storedSession;
}

class FakeLeadService implements LeadService {
  FakeLeadService({
    List<Lead>? leads,
    this.agents = const <AppUser>[],
    this.failWith,
  }) : leads = leads ?? <Lead>[];

  List<Lead> leads;
  List<AppUser> agents;
  ApiException? failWith;

  Map<String, dynamic>? lastCreatePayload;
  Map<String, dynamic>? lastUpdatePayload;
  String? lastAssignedAgentId;
  String? lastStatus;
  String? lastNote;
  String? lastSearch;
  LeadFilters lastFilters = const LeadFilters();

  @override
  Future<Paginated<Lead>> fetchLeads({
    int page = 1,
    int limit = 20,
    String? search,
    LeadFilters filters = const LeadFilters(),
  }) async {
    if (failWith != null) {
      throw failWith!;
    }
    lastSearch = search;
    lastFilters = filters;

    List<Lead> result = leads;
    if (search != null && search.trim().isNotEmpty) {
      final String term = search.trim().toLowerCase();
      result = leads
          .where((Lead lead) =>
              lead.fullName.toLowerCase().contains(term) ||
              lead.phone.contains(term))
          .toList();
    }
    return Paginated<Lead>(
      items: result,
      page: page,
      limit: limit,
      total: result.length,
      totalPages: 1,
      hasNextPage: false,
    );
  }

  @override
  Future<Lead> fetchLead(String id) async {
    if (failWith != null) {
      throw failWith!;
    }
    return leads.firstWhere(
      (Lead lead) => lead.id == id,
      orElse: () => throw ApiException('Lead not found', statusCode: 404),
    );
  }

  @override
  Future<Lead> createLead(Map<String, dynamic> payload) async {
    if (failWith != null) {
      throw failWith!;
    }
    lastCreatePayload = payload;
    final Lead lead = buildLead(
      id: 'lead-created',
      fullName: payload['fullName'] as String,
      phone: payload['phone'] as String,
    );
    leads = <Lead>[lead, ...leads];
    return lead;
  }

  @override
  Future<Lead> updateLead(String id, Map<String, dynamic> payload) async {
    if (failWith != null) {
      throw failWith!;
    }
    lastUpdatePayload = payload;
    return fetchLead(id);
  }

  @override
  Future<Lead> changeStatus(String id, String status, {String? note}) async {
    lastStatus = status;
    final Lead current = await fetchLead(id);
    return buildLead(id: current.id, fullName: current.fullName, status: status);
  }

  @override
  Future<Lead> assignAgent(String id, String agentId) async {
    lastAssignedAgentId = agentId;
    return fetchLead(id);
  }

  @override
  Future<List<LeadNote>> fetchNotes(String id) async => <LeadNote>[
        LeadNote(
          id: 'note-1',
          note: 'Customer interested in 2BR in Dubai Marina.',
          createdAt: DateTime(2026, 8, 24, 10, 30),
          user: testAgent,
        ),
      ];

  @override
  Future<LeadNote> addNote(String id, String note) async {
    lastNote = note;
    return LeadNote(id: 'note-2', note: note, createdAt: DateTime.now());
  }

  @override
  Future<List<LeadActivity>> fetchActivities(String id) async => <LeadActivity>[
        LeadActivity(
          id: 'activity-1',
          type: 'LEAD_CREATED',
          description: 'Lead created by Khalid Rahman',
          createdAt: DateTime(2026, 8, 24, 10, 15),
          user: testManager,
        ),
        LeadActivity(
          id: 'activity-2',
          type: 'STATUS_CHANGED',
          description: 'Status changed from NEW to CONTACTED',
          createdAt: DateTime(2026, 8, 24, 10, 25),
          user: testAgent,
        ),
      ];

  @override
  Future<List<AppUser>> fetchAgents() async => agents;
}

class FakeDashboardService implements DashboardService {
  FakeDashboardService({this.stats, this.failWith});

  DashboardStats? stats;
  ApiException? failWith;

  @override
  Future<DashboardStats> fetchStats() async {
    if (failWith != null) {
      throw failWith!;
    }
    return stats ??
        const DashboardStats(
          totalLeads: 125,
          newLeads: 15,
          hotLeads: 28,
          followUps: 9,
          byStatus: <String, int>{'NEW': 15, 'CONTACTED': 40},
        );
  }
}
