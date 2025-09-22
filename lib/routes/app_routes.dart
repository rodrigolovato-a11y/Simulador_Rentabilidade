// lib/routes/app_routes.dart
import 'package:flutter/widgets.dart';

import '../presentation/consent_screen/consent_screen.dart';
import '../presentation/export_results_screen/export_results_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/password_reset_screen/password_reset_screen.dart';
import '../presentation/registration_screen/registration_screen.dart';
import '../presentation/settings_screen/settings_screen.dart';
import '../presentation/simulation_dashboard/simulation_dashboard.dart';

class AppRoutes {
  // Defina as constantes das rotas em um só lugar
  static const String consent = '/consent-screen';
  static const String initial = consent; // inicial = consent
  static const String login = '/login-screen';
  static const String registration = '/registration-screen';
  static const String passwordReset = '/password-reset-screen';
  static const String simulationDashboard = '/simulation-dashboard';
  static const String settings = '/settings-screen';
  static const String exportResults = '/export-results-screen';

  // Mapa de rotas
  static final Map<String, WidgetBuilder> routes = {
    consent: (context) => const ConsentScreen(),            // ✅ aponta para ConsentScreen
    login: (context) => LoginScreen(),
    registration: (context) => RegistrationScreen(),
    passwordReset: (context) => PasswordResetScreen(),
    simulationDashboard: (context) => SimulationDashboard(),
    settings: (context) => SettingsScreen(),
    exportResults: (context) => const ExportResultsScreen(),
  };
}
