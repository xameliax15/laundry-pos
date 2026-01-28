import 'package:flutter/material.dart';
import '../pages/login_page.dart';
import '../pages/kasir/kasir_dashboard.dart';
import '../pages/kasir/kasir_riwayat.dart';
import '../pages/kurir/kurir_dashboard.dart';
import '../pages/kurir/kurir_riwayat.dart';
import '../pages/owner/owner_dashboard.dart';
import '../services/auth_service.dart';
import 'constants.dart';

class AppRoutes {
  static const String login = '/login';
  static const String kasirDashboard = '/kasir';
  static const String kasirRiwayat = '/kasir/riwayat';
  static const String kurirDashboard = '/kurir';
  static const String kurirRiwayat = '/kurir/riwayat';
  static const String ownerDashboard = '/owner';

  static const String initialRoute = login;

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginPage(),
      kasirDashboard: (context) => _buildRouteWithAuth(
        context,
        const KasirDashboard(),
        AppConstants.roleKasir,
      ),
      kasirRiwayat: (context) => _buildRouteWithAuth(
        context,
        const KasirRiwayat(),
        AppConstants.roleKasir,
      ),
      kurirDashboard: (context) => _buildRouteWithAuth(
        context,
        const KurirDashboard(),
        AppConstants.roleKurir,
      ),
      kurirRiwayat: (context) => _buildRouteWithAuth(
        context,
        const KurirRiwayat(),
        AppConstants.roleKurir,
      ),
      ownerDashboard: (context) => _buildRouteWithAuth(
        context,
        const OwnerDashboard(),
        AppConstants.roleOwner,
      ),
    };
  }

  // Route guard untuk check authentication dan role
  static Widget _buildRouteWithAuth(
    BuildContext context,
    Widget page,
    String requiredRole,
  ) {
    final authService = AuthService();

    // Check if user is logged in
    if (!authService.isLoggedIn()) {
      // Redirect to login if not logged in
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(login);
      });
      return const LoginPage();
    }

    // Check if user has required role
    final userRole = authService.getUserRole();
    if (userRole != requiredRole) {
      // Redirect to appropriate dashboard based on user role
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _redirectToRoleDashboard(context, userRole);
      });
      return const LoginPage();
    }

    return page;
  }

  // Redirect ke dashboard sesuai role
  static void _redirectToRoleDashboard(BuildContext context, String? role) {
    switch (role) {
      case AppConstants.roleOwner:
        Navigator.of(context).pushReplacementNamed(ownerDashboard);
        break;
      case AppConstants.roleKasir:
        Navigator.of(context).pushReplacementNamed(kasirDashboard);
        break;
      case AppConstants.roleKurir:
        Navigator.of(context).pushReplacementNamed(kurirDashboard);
        break;
      default:
        Navigator.of(context).pushReplacementNamed(login);
    }
  }

  // Navigate ke dashboard sesuai role setelah login
  static void navigateToRoleDashboard(BuildContext context, String role) {
    String route;
    switch (role) {
      case AppConstants.roleOwner:
        route = ownerDashboard;
        break;
      case AppConstants.roleKasir:
        route = kasirDashboard;
        break;
      case AppConstants.roleKurir:
        route = kurirDashboard;
        break;
      default:
        route = login;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      route,
      (route) => false,
    );
  }

  // Logout dan redirect ke login
  static Future<void> logout(BuildContext context) async {
    final authService = AuthService();
    await authService.logout();
    Navigator.of(context).pushNamedAndRemoveUntil(
      login,
      (route) => false,
    );
  }
}
