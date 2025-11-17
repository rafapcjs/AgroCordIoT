import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../presentation/widgets/user_info_widget.dart';
import '../providers/auth_provider.dart';

class DashboardUserPage extends StatelessWidget {
  final String accessToken;

  const DashboardUserPage({super.key, required this.accessToken});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[700]!, Colors.green[500]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        actions: [
          UserInfoWidget(
            accessToken: accessToken,
            onLogout: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.95,
          children: [
            _buildDashboardCard(
              context: context,
              title: 'Sensores en Tiempo',
              subtitle: 'Monitorea datos de',
              icon: Icons.sensors,
              gradientColors: [const Color(0xFFFF9800), const Color(0xFFFF6F00)],
              onTap: () {
                Navigator.of(context).pushNamed(
                  '/sensors/dashboard',
                  arguments: {'accessToken': accessToken},
                );
              },
            ),
            _buildDashboardCard(
              context: context,
              title: 'Reporte Mensual',
              subtitle: 'Analiza datos mensuales',
              icon: Icons.bar_chart,
              gradientColors: [const Color(0xFF7E57C2), const Color(0xFF5E35B1)],
              onTap: () {
                Navigator.of(context).pushNamed(
                  '/reports/monthly',
                  arguments: {'accessToken': accessToken},
                );
              },
            ),
            _buildDashboardCard(
              context: context,
              title: 'Reporte Diario',
              subtitle: 'Analiza sensores internos y',
              icon: Icons.bar_chart_outlined,
              gradientColors: [const Color(0xFFEC407A), const Color(0xFFD81B60)],
              onTap: () {
                Navigator.of(context).pushNamed(
                  '/reports/internal',
                  arguments: {
                    'accessToken': accessToken,
                    'deviceId': 'ESP32_1',
                  },
                );
              },
            ),
            _buildDashboardCard(
              context: context,
              title: 'Reporte Semanal',
              subtitle: 'Análisis de 7 días por',
              icon: Icons.calendar_view_week,
              gradientColors: [const Color(0xFF26A69A), const Color(0xFF00897B)],
              onTap: () {
                Navigator.of(context).pushNamed(
                  '/reports/weekly',
                  arguments: {'accessToken': accessToken},
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors[1].withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              // Title and subtitle
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Arrow button
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
