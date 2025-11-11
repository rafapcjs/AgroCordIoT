import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../data/models/sensor_data_model.dart';
import '../../data/services/sensor_service.dart';
import '../widgets/navigation/report_navigation_drawer.dart';

class SensorDashboardScreen extends StatefulWidget {
  final String accessToken;

  const SensorDashboardScreen({
    super.key,
    required this.accessToken,
  });

  @override
  State<SensorDashboardScreen> createState() => _SensorDashboardScreenState();
}

class _SensorDashboardScreenState extends State<SensorDashboardScreen> {
  final SensorService _sensorService = SensorService();
  final List<String> _deviceIds = ['ESP32_1', 'ESP32_2'];

  Map<String, List<SensorData>> _devicesData = {};
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadSensorData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Inicia la actualización automática cada 5 minutos
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _loadSensorData();
    });
  }

  /// Carga los datos de los sensores
  Future<void> _loadSensorData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _sensorService.getMultipleDevicesData(
        _deviceIds,
        widget.accessToken,
      );

      setState(() {
        _devicesData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar datos: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: ReportNavigationDrawer(
        selectedLabel: 'Panel de Sensores',
        items: [
          ReportNavigationItem(
            icon: Icons.sensors,
            label: 'Panel de Sensores',
            onTap: () {
              // Ya estamos en esta pantalla
            },
          ),
          ReportNavigationItem(
            icon: Icons.assessment_outlined,
            label: 'Reporte diario',
            onTap: () {
              Navigator.of(context).pushReplacementNamed(
                '/reports/internal',
                arguments: {
                  'accessToken': widget.accessToken,
                  'deviceId': 'ESP32_1',
                },
              );
            },
          ),
          ReportNavigationItem(
            icon: Icons.calendar_month_outlined,
            label: 'Reporte mensual',
            onTap: () {
              Navigator.of(context).pushReplacementNamed(
                '/reports/monthly',
                arguments: {'accessToken': widget.accessToken},
              );
            },
          ),
          ReportNavigationItem(
            icon: Icons.dashboard_outlined,
            label: 'Volver al panel',
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      appBar: AppBar(
        title: const Text(
          'Panel de Sensores IoT',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: 'Menú de navegación',
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSensorData,
            tooltip: 'Actualizar datos',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSensorData,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _devicesData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Cargando datos de sensores...',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null && _devicesData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadSensorData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Información de actualización
          _buildUpdateInfo(),
          const SizedBox(height: 16),

          // Cards de dispositivos
          ..._deviceIds.map((deviceId) => _buildDeviceCard(deviceId)),
        ],
      ),
    );
  }

  Widget _buildUpdateInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.info.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: AppTheme.info,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Los datos se actualizan automáticamente cada 5 minutos',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.info.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(String deviceId) {
    final sensorData = _devicesData[deviceId] ?? [];
    final displayName = deviceId == 'ESP32_1'
        ? 'Ambiente Interno'
        : 'Ambiente Externo';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del dispositivo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: deviceId == 'ESP32_1'
                    ? AppTheme.primaryGradient
                    : AppTheme.secondaryGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.router,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          deviceId,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (sensorData.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Activo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Contenido de sensores
            Padding(
              padding: const EdgeInsets.all(16),
              child: sensorData.isEmpty
                  ? _buildNoDataMessage()
                  : _buildSensorGrid(sensorData),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.cloud_off,
              size: 48,
              color: AppTheme.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'Sin datos disponibles',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'No se han recibido lecturas recientes',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textTertiary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorGrid(List<SensorData> sensorData) {
    final sensorTypes = [
      'temperature',
      'humidity',
      'solar_radiation',
      'soil_humidity',
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: sensorTypes.length,
      itemBuilder: (context, index) {
        final sensorType = sensorTypes[index];
        final sensor = _sensorService.getSensorByType(sensorData, sensorType);
        return _buildSensorTile(sensorType, sensor);
      },
    );
  }

  Widget _buildSensorTile(String sensorType, SensorData? sensor) {
    final config = _getSensorConfig(sensorType);
    final hasData = sensor != null && sensor.hasData;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: config.color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: config.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    config.icon,
                    color: config.color,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    config.name,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (hasData) ...[
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  '${sensor.value.toStringAsFixed(1)}${sensor.unit}',
                  key: ValueKey(sensor.value),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: config.color,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatTimestamp(sensor.timestamp),
                style: const TextStyle(
                  fontSize: 8,
                  color: AppTheme.textTertiary,
                ),
              ),
            ] else ...[
              Text(
                'Sin datos',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textTertiary.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'No disponible',
                style: TextStyle(
                  fontSize: 8,
                  color: AppTheme.textTertiary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  SensorConfig _getSensorConfig(String sensorType) {
    switch (sensorType) {
      case 'temperature':
        return SensorConfig(
          name: 'Temperatura',
          icon: Icons.thermostat,
          color: AppTheme.error,
        );
      case 'humidity':
        return SensorConfig(
          name: 'Humedad',
          icon: Icons.water_drop,
          color: AppTheme.info,
        );
      case 'solar_radiation':
        return SensorConfig(
          name: 'Radiación Solar',
          icon: Icons.wb_sunny,
          color: AppTheme.warning,
        );
      case 'soil_humidity':
        return SensorConfig(
          name: 'Humedad Suelo',
          icon: Icons.grass,
          color: AppTheme.success,
        );
      default:
        return SensorConfig(
          name: sensorType,
          icon: Icons.sensors,
          color: AppTheme.textSecondary,
        );
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Hace unos segundos';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} hrs';
    } else {
      return DateFormat('dd/MM HH:mm').format(timestamp);
    }
  }
}

class SensorConfig {
  final String name;
  final IconData icon;
  final Color color;

  SensorConfig({
    required this.name,
    required this.icon,
    required this.color,
  });
}
