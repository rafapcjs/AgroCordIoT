import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../presentation/screens/dashboard_screen.dart';
import '../pages/dashboard_user_page.dart';

class NavigationHelper {
  /// Navega al dashboard correspondiente según el rol del usuario
  static void navigateToDashboard(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.currentUser?.role ?? '';
    final accessToken = authProvider.accessToken ?? '';

    // Eliminar todas las rutas anteriores y navegar al dashboard correcto
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) {
          if (userRole == 'admin') {
            return DashboardScreen(accessToken: accessToken);
          } else {
            return DashboardUserPage(accessToken: accessToken);
          }
        },
      ),
      (route) => false, // Elimina todas las rutas anteriores
    );
  }

  /// Retorna el widget del dashboard correcto según el rol
  static Widget getDashboardForRole(String role, String accessToken) {
    if (role == 'admin') {
      return DashboardScreen(accessToken: accessToken);
    } else {
      return DashboardUserPage(accessToken: accessToken);
    }
  }
}
