import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:twr_crm/core/errors/api_exception.dart';
import 'package:twr_crm/features/auth/auth_provider.dart';
import 'package:twr_crm/features/auth/login_screen.dart';
import 'package:twr_crm/theme/app_theme.dart';

import 'fakes.dart';

Widget wrapLogin(AuthProvider auth) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: auth,
    child: MaterialApp(theme: AppTheme.light, home: const LoginScreen()),
  );
}

void main() {
  group('Login screen', () {
    testWidgets('renders the TWR branding and the login form', (WidgetTester tester) async {
      final AuthProvider auth = AuthProvider(authService: FakeAuthService());
      await tester.pumpWidget(wrapLogin(auth));

      expect(find.text('TWR REAL ESTATE'), findsOneWidget);
      expect(find.text('TWR CRM'), findsOneWidget);
      expect(find.byKey(const Key('login_email_field')), findsOneWidget);
      expect(find.byKey(const Key('login_password_field')), findsOneWidget);
      expect(find.text('LOGIN'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
    });

    testWidgets('shows validation errors for an empty form', (WidgetTester tester) async {
      final FakeAuthService service = FakeAuthService();
      await tester.pumpWidget(wrapLogin(AuthProvider(authService: service)));

      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(service.loginCalls, 0, reason: 'invalid form must not call the API');
    });

    testWidgets('rejects a malformed email and a short password',
        (WidgetTester tester) async {
      final FakeAuthService service = FakeAuthService();
      await tester.pumpWidget(wrapLogin(AuthProvider(authService: service)));

      await tester.enterText(find.byKey(const Key('login_email_field')), 'not-an-email');
      await tester.enterText(find.byKey(const Key('login_password_field')), 'short');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();

      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(find.text('Password must be at least 8 characters'), findsOneWidget);
      expect(service.loginCalls, 0);
    });

    testWidgets('submits valid credentials to the auth service',
        (WidgetTester tester) async {
      final FakeAuthService service = FakeAuthService(user: testManager);
      final AuthProvider auth = AuthProvider(authService: service);
      await tester.pumpWidget(wrapLogin(auth));

      await tester.enterText(
          find.byKey(const Key('login_email_field')), 'manager@twrrealestate.ae');
      await tester.enterText(find.byKey(const Key('login_password_field')), 'Twr@12345');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      expect(service.loginCalls, 1);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.user?.email, 'manager@twrrealestate.ae');
    });

    testWidgets('surfaces the server error message on a failed login',
        (WidgetTester tester) async {
      final FakeAuthService service = FakeAuthService(
        failWith: ApiException('Invalid email or password', statusCode: 401),
      );
      await tester.pumpWidget(wrapLogin(AuthProvider(authService: service)));

      await tester.enterText(
          find.byKey(const Key('login_email_field')), 'manager@twrrealestate.ae');
      await tester.enterText(find.byKey(const Key('login_password_field')), 'WrongPass1');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login_error')), findsOneWidget);
      expect(find.text('Invalid email or password'), findsOneWidget);
    });
  });

  group('Authentication state', () {
    test('starts in the unknown state', () {
      final AuthProvider auth = AuthProvider(authService: FakeAuthService());
      expect(auth.status, AuthStatus.unknown);
      expect(auth.isAuthenticated, isFalse);
    });

    test('bootstrap without a stored token lands on unauthenticated', () async {
      final AuthProvider auth =
          AuthProvider(authService: FakeAuthService(storedSession: false));
      await auth.bootstrap();
      expect(auth.status, AuthStatus.unauthenticated);
      expect(auth.user, isNull);
    });

    test('bootstrap with a valid stored token restores the session', () async {
      final AuthProvider auth = AuthProvider(
        authService: FakeAuthService(user: testAgent, storedSession: true),
      );
      await auth.bootstrap();
      expect(auth.status, AuthStatus.authenticated);
      expect(auth.user?.role, 'AGENT');
    });

    test('bootstrap with a rejected token falls back to unauthenticated', () async {
      final AuthProvider auth = AuthProvider(
        authService: FakeAuthService(
          storedSession: true,
          failWith: ApiException('Unauthorized', statusCode: 401),
        ),
      );
      await auth.bootstrap();
      expect(auth.status, AuthStatus.unauthenticated);
    });

    test('logout clears the user and the session', () async {
      final FakeAuthService service =
          FakeAuthService(user: testManager, storedSession: true);
      final AuthProvider auth = AuthProvider(authService: service);
      await auth.bootstrap();
      await auth.logout();

      expect(service.logoutCalls, 1);
      expect(auth.user, isNull);
      expect(auth.status, AuthStatus.unauthenticated);
    });

    test('an expired refresh drops the session', () async {
      final AuthProvider auth = AuthProvider(
        authService: FakeAuthService(user: testManager, storedSession: true),
      );
      await auth.bootstrap();
      auth.onSessionExpired();

      expect(auth.isAuthenticated, isFalse);
      expect(auth.errorMessage, contains('session has expired'));
    });

    test('role helpers gate the assignment UI', () {
      expect(testManager.canAssignLeads, isTrue);
      expect(testAgent.canAssignLeads, isFalse);
      expect(testAgent.canDeleteLeads, isFalse);
      expect(testAgent.hasPermission('lead.view.own'), isTrue);
      expect(testAgent.hasPermission('lead.view.all'), isFalse);
    });
  });
}
