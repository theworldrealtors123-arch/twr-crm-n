import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:twr_crm/core/errors/api_exception.dart';
import 'package:twr_crm/core/utils/formatters.dart';
import 'package:twr_crm/core/utils/validators.dart';
import 'package:twr_crm/features/auth/auth_provider.dart';
import 'package:twr_crm/features/dashboard/dashboard_provider.dart';
import 'package:twr_crm/features/leads/lead_detail_provider.dart';
import 'package:twr_crm/features/leads/lead_form_screen.dart';
import 'package:twr_crm/features/leads/leads_list_screen.dart';
import 'package:twr_crm/features/leads/leads_provider.dart';
import 'package:twr_crm/features/leads/widgets/lead_card.dart';
import 'package:twr_crm/models/lead.dart';
import 'package:twr_crm/models/user.dart';
import 'package:twr_crm/services/lead_service.dart';
import 'package:twr_crm/theme/app_theme.dart';

import 'fakes.dart';

Widget wrapLeadsList({
  required FakeLeadService leadService,
  required AuthProvider auth,
}) {
  return MultiProvider(
    providers: [
      Provider<LeadService>.value(value: leadService),
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider<LeadsProvider>(
        create: (_) => LeadsProvider(leadService: leadService),
      ),
    ],
    child: MaterialApp(theme: AppTheme.light, home: const LeadsListScreen()),
  );
}

Widget wrapLeadForm({
  required FakeLeadService leadService,
  required AuthProvider auth,
  Lead? lead,
}) {
  return MultiProvider(
    providers: [
      Provider<LeadService>.value(value: leadService),
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
    ],
    child: MaterialApp(theme: AppTheme.light, home: LeadFormScreen(lead: lead)),
  );
}

Future<AuthProvider> authedAs(AppUser user) async {
  final AuthProvider auth =
      AuthProvider(authService: FakeAuthService(user: user, storedSession: true));
  await auth.bootstrap();
  return auth;
}

void main() {
  group('Lead list', () {
    testWidgets('renders a card per lead with the key business fields',
        (WidgetTester tester) async {
      final FakeLeadService service = FakeLeadService(
        leads: <Lead>[
          buildLead(agent: testAgent),
          buildLead(id: 'lead-2', fullName: 'Priya Sharma', status: 'CONTACTED'),
        ],
      );
      await tester.pumpWidget(
        wrapLeadsList(leadService: service, auth: await authedAs(testManager)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LeadCard), findsNWidgets(2));
      expect(find.text('Ahmed Khan'), findsOneWidget);
      expect(find.text('Priya Sharma'), findsOneWidget);
      expect(find.text('2 Bedroom Apartment'), findsWidgets);
      expect(find.text('AED 1.3M - AED 1.6M'), findsWidgets);
      expect(find.text('HOT'), findsWidgets);
      expect(find.text('Assigned: Ali'), findsOneWidget);
      expect(find.text('Unassigned'), findsOneWidget);
    });

    testWidgets('shows the empty state when there are no leads',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapLeadsList(
          leadService: FakeLeadService(leads: <Lead>[]),
          auth: await authedAs(testManager),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No leads yet'), findsOneWidget);
      expect(find.byType(LeadCard), findsNothing);
    });

    testWidgets('shows an error state with a retry action',
        (WidgetTester tester) async {
      final FakeLeadService service = FakeLeadService(
        failWith: ApiException('Unable to connect. Please try again.'),
      );
      await tester.pumpWidget(
        wrapLeadsList(leadService: service, auth: await authedAs(testManager)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to connect. Please try again.'), findsOneWidget);
      expect(find.byKey(const Key('retry_button')), findsOneWidget);
    });

    testWidgets('search field is present and forwards the term to the service',
        (WidgetTester tester) async {
      final FakeLeadService service =
          FakeLeadService(leads: <Lead>[buildLead(), buildLead(id: 'lead-2', fullName: 'Priya Sharma')]);
      await tester.pumpWidget(
        wrapLeadsList(leadService: service, auth: await authedAs(testManager)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('lead_search_field')), 'ahmed');
      // Debounce window plus the request round-trip.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(service.lastSearch, 'ahmed');
      expect(find.text('Ahmed Khan'), findsOneWidget);
      expect(find.text('Priya Sharma'), findsNothing);
    });
  });

  group('Create lead validation', () {
    testWidgets('blocks submission when required fields are empty',
        (WidgetTester tester) async {
      final FakeLeadService service = FakeLeadService();
      await tester.pumpWidget(
        wrapLeadForm(leadService: service, auth: await authedAs(testManager)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('lead_submit_button')));
      await tester.pump();

      expect(find.text('Full name is required'), findsOneWidget);
      expect(find.text('Phone is required'), findsOneWidget);
      expect(service.lastCreatePayload, isNull);
    });

    testWidgets('rejects an invalid email and an invalid phone',
        (WidgetTester tester) async {
      final FakeLeadService service = FakeLeadService();
      await tester.pumpWidget(
        wrapLeadForm(leadService: service, auth: await authedAs(testManager)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('lead_full_name_field')), 'Test Customer');
      await tester.enterText(find.byKey(const Key('lead_phone_field')), 'abc');
      await tester.enterText(find.byKey(const Key('lead_email_field')), 'not-an-email');
      await tester.tap(find.byKey(const Key('lead_submit_button')));
      await tester.pump();

      expect(find.text('Enter a valid phone number'), findsOneWidget);
      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(service.lastCreatePayload, isNull);
    });

    testWidgets('submits a valid lead to the service', (WidgetTester tester) async {
      final FakeLeadService service = FakeLeadService();
      await tester.pumpWidget(
        wrapLeadForm(leadService: service, auth: await authedAs(testManager)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('lead_full_name_field')), 'Test Customer');
      await tester.enterText(find.byKey(const Key('lead_phone_field')), '+971509998888');
      await tester.enterText(find.byKey(const Key('lead_budget_min_field')), '1400000');
      await tester.enterText(find.byKey(const Key('lead_budget_max_field')), '1600000');
      await tester.tap(find.byKey(const Key('lead_submit_button')));
      await tester.pumpAndSettle();

      expect(service.lastCreatePayload, isNotNull);
      expect(service.lastCreatePayload!['fullName'], 'Test Customer');
      expect(service.lastCreatePayload!['phone'], '+971509998888');
      expect(service.lastCreatePayload!['budgetMin'], 1400000);
      expect(service.lastCreatePayload!['budgetMax'], 1600000);
    });

    testWidgets('blocks a max budget lower than the min budget',
        (WidgetTester tester) async {
      final FakeLeadService service = FakeLeadService();
      await tester.pumpWidget(
        wrapLeadForm(leadService: service, auth: await authedAs(testManager)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('lead_full_name_field')), 'Budget Test');
      await tester.enterText(find.byKey(const Key('lead_phone_field')), '+971509998888');
      await tester.enterText(find.byKey(const Key('lead_budget_min_field')), '2000000');
      await tester.enterText(find.byKey(const Key('lead_budget_max_field')), '1000000');
      await tester.tap(find.byKey(const Key('lead_submit_button')));
      await tester.pump();

      expect(find.byKey(const Key('lead_form_error')), findsOneWidget);
      expect(service.lastCreatePayload, isNull);
    });

    testWidgets('hides agent assignment from an agent', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapLeadForm(
          leadService: FakeLeadService(agents: <AppUser>[testAgent]),
          auth: await authedAs(testAgent),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ASSIGNMENT'), findsNothing);
    });
  });

  group('Lead detail provider', () {
    test('loads the lead, its notes and its timeline together', () async {
      final FakeLeadService service = FakeLeadService(leads: <Lead>[buildLead()]);
      final LeadDetailProvider provider =
          LeadDetailProvider(leadService: service, leadId: 'lead-1');

      await provider.load();

      expect(provider.state, ViewState.ready);
      expect(provider.lead?.fullName, 'Ahmed Khan');
      expect(provider.notes.length, 1);
      expect(provider.activities.length, 2);
    });

    test('reports a friendly message when the lead is not visible', () async {
      final FakeLeadService service = FakeLeadService(leads: <Lead>[]);
      final LeadDetailProvider provider =
          LeadDetailProvider(leadService: service, leadId: 'other-agent-lead');

      await provider.load();

      expect(provider.state, ViewState.error);
      expect(provider.errorMessage, 'Lead not found');
    });

    test('a status change is sent to the backend', () async {
      final FakeLeadService service = FakeLeadService(leads: <Lead>[buildLead()]);
      final LeadDetailProvider provider =
          LeadDetailProvider(leadService: service, leadId: 'lead-1');
      await provider.load();

      final String? error = await provider.changeStatus('CONTACTED');

      expect(error, isNull);
      expect(service.lastStatus, 'CONTACTED');
      expect(provider.lead?.status, 'CONTACTED');
    });

    test('an assignment is sent to the backend', () async {
      final FakeLeadService service = FakeLeadService(leads: <Lead>[buildLead()]);
      final LeadDetailProvider provider =
          LeadDetailProvider(leadService: service, leadId: 'lead-1');
      await provider.load();

      await provider.assignAgent(testAgent.id);

      expect(service.lastAssignedAgentId, testAgent.id);
    });

    test('a note is sent to the backend', () async {
      final FakeLeadService service = FakeLeadService(leads: <Lead>[buildLead()]);
      final LeadDetailProvider provider =
          LeadDetailProvider(leadService: service, leadId: 'lead-1');
      await provider.load();

      await provider.addNote('Customer called back.');

      expect(service.lastNote, 'Customer called back.');
    });
  });

  group('Dashboard provider', () {
    test('exposes the statistics returned by the API', () async {
      final DashboardProvider provider =
          DashboardProvider(dashboardService: FakeDashboardService());
      await provider.load();

      expect(provider.state, ViewState.ready);
      expect(provider.stats.totalLeads, 125);
      expect(provider.stats.newLeads, 15);
      expect(provider.stats.hotLeads, 28);
    });

    test('falls back to an error state when the API is unreachable', () async {
      final DashboardProvider provider = DashboardProvider(
        dashboardService: FakeDashboardService(
          failWith: ApiException('Unable to connect. Please try again.'),
        ),
      );
      await provider.load();

      expect(provider.state, ViewState.error);
      expect(provider.errorMessage, 'Unable to connect. Please try again.');
    });
  });

  group('Formatters and validators', () {
    test('formats AED budgets the way the sales team reads them', () {
      expect(Formatters.currency(1500000), 'AED 1.5M');
      expect(Formatters.currency(2000000), 'AED 2M');
      expect(Formatters.currency(850000), 'AED 850K');
      expect(Formatters.budgetRange(null, null), 'Budget not set');
      expect(Formatters.budgetRange(1300000, 1600000), 'AED 1.3M - AED 1.6M');
    });

    test('formats the requirement line', () {
      expect(
        Formatters.requirement(propertyType: 'APARTMENT', bedrooms: 2),
        '2 Bedroom Apartment',
      );
      expect(Formatters.requirement(), 'Requirement not set');
    });

    test('greets by time of day', () {
      expect(Formatters.greeting(DateTime(2026, 8, 24, 9)), 'Good Morning');
      expect(Formatters.greeting(DateTime(2026, 8, 24, 14)), 'Good Afternoon');
      expect(Formatters.greeting(DateTime(2026, 8, 24, 20)), 'Good Evening');
    });

    test('validators mirror the backend rules', () {
      expect(Validators.requiredField('', 'Full name'), 'Full name is required');
      expect(Validators.email('ahmed@example.com'), isNull);
      expect(Validators.email(''), isNull);
      expect(Validators.email('', required: true), 'Email is required');
      expect(Validators.phone('+971501234567'), isNull);
      expect(Validators.phone('abc'), 'Enter a valid phone number');
      expect(Validators.numeric('12abc', 'Budget'), 'Budget must be a number');
      expect(Validators.budgetRange('2000000', '1000000'), isNotNull);
      expect(Validators.budgetRange('1000000', '2000000'), isNull);
    });
  });
}
