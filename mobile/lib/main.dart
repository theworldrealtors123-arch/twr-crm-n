import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'features/auth/auth_provider.dart';
import 'features/dashboard/dashboard_provider.dart';
import 'features/leads/leads_provider.dart';
import 'routes/app_router.dart';
import 'services/auth_service.dart';
import 'services/dashboard_service.dart';
import 'services/lead_service.dart';
import 'services/secure_storage_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TwrCrmApp());
}

/// Root navigator key so the API client can force a return to Login when the
/// refresh token is no longer valid.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class TwrCrmApp extends StatefulWidget {
  const TwrCrmApp({super.key});

  @override
  State<TwrCrmApp> createState() => _TwrCrmAppState();
}

class _TwrCrmAppState extends State<TwrCrmApp> {
  late final SecureStorageService _storage;
  late final ApiClient _apiClient;
  late final AuthService _authService;
  late final LeadService _leadService;
  late final DashboardService _dashboardService;
  late final AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _storage = SecureStorageService();
    _apiClient = ApiClient(
      storage: _storage,
      onAuthenticationLost: _handleSessionExpired,
    );
    _authService = AuthService(client: _apiClient, storage: _storage);
    _leadService = LeadService(client: _apiClient);
    _dashboardService = DashboardService(client: _apiClient);
    _authProvider = AuthProvider(authService: _authService);
  }

  void _handleSessionExpired() {
    _authProvider.onSessionExpired();
    rootNavigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: _apiClient),
        Provider<AuthService>.value(value: _authService),
        Provider<LeadService>.value(value: _leadService),
        Provider<DashboardService>.value(value: _dashboardService),
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<DashboardProvider>(
          create: (_) => DashboardProvider(dashboardService: _dashboardService),
        ),
        ChangeNotifierProvider<LeadsProvider>(
          create: (_) => LeadsProvider(leadService: _leadService),
        ),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        navigatorKey: rootNavigatorKey,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRouter.generate,
      ),
    );
  }
}
