import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/auth/login_screen.dart';
import '../features/leads/lead_detail_provider.dart';
import '../features/leads/lead_details_screen.dart';
import '../features/leads/lead_form_screen.dart';
import '../features/shell/main_shell.dart';
import '../features/splash/splash_screen.dart';
import '../models/lead.dart';
import '../services/lead_service.dart';

class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String leadDetails = '/leads/details';
  static const String leadForm = '/leads/form';
}

class AppRouter {
  const AppRouter._();

  static Route<dynamic> generate(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute<void>(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );

      case AppRoutes.login:
        return MaterialPageRoute<void>(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );

      case AppRoutes.home:
        return MaterialPageRoute<void>(
          builder: (_) => const MainShell(),
          settings: settings,
        );

      case AppRoutes.leadDetails:
        final String leadId = settings.arguments as String;
        return MaterialPageRoute<bool>(
          builder: (BuildContext context) => ChangeNotifierProvider<LeadDetailProvider>(
            create: (BuildContext context) => LeadDetailProvider(
              leadService: context.read<LeadService>(),
              leadId: leadId,
            ),
            child: LeadDetailsScreen(leadId: leadId),
          ),
          settings: settings,
        );

      case AppRoutes.leadForm:
        final Lead? lead = settings.arguments as Lead?;
        return MaterialPageRoute<bool>(
          builder: (_) => LeadFormScreen(lead: lead),
          settings: settings,
        );

      default:
        return MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Not found')),
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
