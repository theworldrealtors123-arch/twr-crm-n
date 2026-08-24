import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:twr_crm/features/auth/auth_provider.dart';
import 'package:twr_crm/features/dashboard/dashboard_provider.dart';
import 'package:twr_crm/features/leads/leads_provider.dart';
import 'package:twr_crm/features/shell/main_shell.dart';
import 'package:twr_crm/models/lead.dart';
import 'package:twr_crm/routes/app_router.dart';
import 'package:twr_crm/services/lead_service.dart';
import 'package:twr_crm/theme/app_theme.dart';

import 'fakes.dart';

void main() {
  Future<Widget> buildShell(FakeLeadService leadService) async {
    final AuthProvider auth = AuthProvider(
      authService: FakeAuthService(user: testManager, storedSession: true),
    );
    await auth.bootstrap();

    return MultiProvider(
      providers: [
        Provider<LeadService>.value(value: leadService),
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<DashboardProvider>(
          create: (_) => DashboardProvider(dashboardService: FakeDashboardService()),
        ),
        ChangeNotifierProvider<LeadsProvider>(
          create: (_) => LeadsProvider(leadService: leadService),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const MainShell(),
        onGenerateRoute: AppRouter.generate,
      ),
    );
  }

  group('Navigation', () {
    testWidgets('bottom navigation exposes Home, Leads and Profile',
        (WidgetTester tester) async {
      await tester.pumpWidget(await buildShell(FakeLeadService()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('main_bottom_nav')), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Leads'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('opens the dashboard first with live statistics',
        (WidgetTester tester) async {
      await tester.pumpWidget(await buildShell(FakeLeadService()));
      await tester.pumpAndSettle();

      expect(find.text('TOTAL LEADS'), findsOneWidget);
      expect(find.text('125'), findsOneWidget);
      expect(find.text('NEW LEADS'), findsOneWidget);
      expect(find.text('HOT LEADS'), findsOneWidget);
      expect(find.text('FOLLOW-UPS'), findsOneWidget);
      expect(find.textContaining('Good'), findsOneWidget);
      expect(find.text('Khalid'), findsOneWidget);
    });

    testWidgets('switches to the Leads tab and back to Home',
        (WidgetTester tester) async {
      final FakeLeadService service =
          FakeLeadService(leads: <Lead>[buildLead(agent: testAgent)]);
      await tester.pumpWidget(await buildShell(service));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Leads'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('lead_search_field')), findsOneWidget);
      expect(find.byKey(const Key('create_lead_fab')), findsOneWidget);
      expect(find.text('Ahmed Khan'), findsOneWidget);

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('TOTAL LEADS'), findsOneWidget);
    });

    testWidgets('shows the signed-in user on the Profile tab',
        (WidgetTester tester) async {
      await tester.pumpWidget(await buildShell(FakeLeadService()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(find.text('Khalid Rahman'), findsOneWidget);
      expect(find.text('manager@twrrealestate.ae'), findsOneWidget);
      expect(find.byKey(const Key('logout_button')), findsOneWidget);
    });
  });
}
