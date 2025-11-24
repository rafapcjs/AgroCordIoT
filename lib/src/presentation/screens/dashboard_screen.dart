import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import 'users_management_screen.dart';
import 'plants_management_screen.dart';
import 'sensor_dashboard_screen.dart';
import 'internal_report_screen.dart';
import 'monthly_report_screen.dart';
import 'login_screen.dart';
import '../../pages/weekly_report_page.dart';
import '../widgets/user_info_widget.dart';
import '../../providers/auth_provider.dart';

class DashboardScreen extends StatelessWidget {
  final String accessToken;

  const DashboardScreen({super.key, required this.accessToken});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(
          'Panel administrativo',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        actions: [
          UserInfoWidget(
            accessToken: accessToken,
            onLogout: () async {
              // Ejecutar logout
              await Provider.of<AuthProvider>(context, listen: false).logout();
              
              // Navegar al login reemplazando toda la pila
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con información del usuario
            ThemedCard(
              gradient: AppTheme.surfaceGradient,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.dashboard_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Panel de Control',
                          style: context.textTheme.displaySmall?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Gestiona tu sistema IoT desde aquí',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: AppTheme.secondaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Grid de funcionalidades
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
                children: [
                  _buildModernCard(
                    context,
                    'Gestión de Usuarios',
                    'Administra permisos y accesos',
                    Icons.people_outline,
                    AppTheme.primaryGradient,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UsersManagementScreen(
                            accessToken: accessToken,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildModernCard(
                    context,
                    'Plantas y Alertas',
                    'Gestiona plantas y configura notificaciones',
                    Icons.local_florist,
                    const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlantsManagementScreen(
                            accessToken: accessToken,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildModernCard(
                    context,
                    'Sensores en Tiempo Real',
                    'Monitorea datos de sensores IoT',
                    Icons.sensors,
                    AppTheme.accentGradient,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SensorDashboardScreen(
                            accessToken: accessToken,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildModernCard(
                    context,
                    'Reporte del Mes',
                    'Análisis mensual completo',
                    Icons.analytics_outlined,
                    const LinearGradient(
                      colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MonthlyReportScreen(
                            accessToken: accessToken,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildModernCard(
                    context,
                    'Reporte del Día',
                    'Datos por día y monitor',
                    Icons.assessment_outlined,
                    const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InternalReportScreen(
                            accessToken: accessToken,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildModernCard(
                    context,
                    'Reporte de la Semana',
                    'Análisis semanal detallado',
                    Icons.calendar_view_week,
                    const LinearGradient(
                      colors: [Color(0xFF8BC34A), Color(0xFF689F38)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WeeklyReportPage(
                            accessToken: accessToken,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método moderno para crear cards
  Widget _buildModernCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Gradient gradient,
    VoidCallback onTap,
  ) {
    return ThemedCard(
      gradient: gradient,
      onTap: onTap,
      shadow: AppTheme.mediumShadow,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 10,
            ),
          ),
        ],
      ),
    );
  }
}
