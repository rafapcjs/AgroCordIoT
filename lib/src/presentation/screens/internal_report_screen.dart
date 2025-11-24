import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/models/daily_report_model.dart';
import '../../data/services/daily_report_service.dart';
import '../../services/pdf_service.dart';
import '../widgets/navigation/report_navigation_drawer.dart';
import '../widgets/buttonsPdf/buttons_pdf.dart';
import '../../utils/navigation_helper.dart';

class InternalReportScreen extends StatefulWidget {
  final String accessToken;
  final String initialDeviceId;

  const InternalReportScreen({
    super.key,
    required this.accessToken,
    this.initialDeviceId = 'ESP32_1',
  });

  @override
  State<InternalReportScreen> createState() => _InternalReportScreenState();
}

class _InternalReportScreenState extends State<InternalReportScreen> {
  DailyReportModel? dailyReport;
  bool isLoading = true;
  DateTime selectedDate = DateTime.now();
  List<DailyReportModel?> reportHistory = [];
  int currentHistoryIndex = -1;
  late String selectedDevice;
  static const List<String> devices = ['ESP32_1', 'ESP32_2'];
  static const Map<String, String> deviceLabels = {
    'ESP32_1': 'Monitor Interno',
    'ESP32_2': 'Monitor Externo',
  };

  String get selectedDeviceLabel => deviceLabels[selectedDevice] ?? selectedDevice;

  @override
  void initState() {
    super.initState();
    selectedDevice = deviceLabels.containsKey(widget.initialDeviceId)
        ? widget.initialDeviceId
        : 'ESP32_1';
    _loadDailyReport();
    _scheduleReports();
  }

  Future<void> _loadDailyReport() async {
    setState(() {
      isLoading = true;
    });

    try {
      final report = await DailyReportService.getDailyReport(
        accessToken: widget.accessToken,
        deviceId: selectedDevice,
        date: selectedDate,
      );

      setState(() {
        dailyReport = report;
        isLoading = false;
        _addToHistory(report);
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading daily report: $e');
    }
  }

  void _onDeviceChanged(String? deviceId) {
    if (deviceId == null || deviceId == selectedDevice) return;

    setState(() {
      selectedDevice = deviceId;
      dailyReport = null;
      reportHistory.clear();
      currentHistoryIndex = -1;
    });

    _loadDailyReport();
  }

  Widget _buildDeviceSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.surfaceDark),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: DropdownButton<String>(
        value: selectedDevice,
        onChanged: _onDeviceChanged,
        underline: const SizedBox(),
        isExpanded: true,
        items: devices.map((String device) {
          return DropdownMenuItem<String>(
            value: device,
            child: Text(
              deviceLabels[device] ?? device,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: ReportNavigationDrawer(
        selectedLabel: 'Reporte diario',
        items: [
          ReportNavigationItem(
            icon: Icons.sensors,
            label: 'Panel de Sensores',
            onTap: () {
              Navigator.of(context).pushReplacementNamed(
                '/sensors/dashboard',
                arguments: {'accessToken': widget.accessToken},
              );
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
                  'deviceId': selectedDevice,
                },
              );
            },
          ),
          ReportNavigationItem(
            icon: Icons.calendar_view_week,
            label: 'Reporte semanal',
            onTap: () {
              Navigator.of(context).pushReplacementNamed(
                '/reports/weekly',
                arguments: {
                  'accessToken': widget.accessToken,
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
                arguments: {
                  'accessToken': widget.accessToken,
                },
              );
            },
          ),
          ReportNavigationItem(
            icon: Icons.dashboard_outlined,
            label: 'Volver al panel',
            onTap: () {
              NavigationHelper.navigateToDashboard(context);
            },
          ),
        ],
      ),
      appBar: AppBar(
        title: const Text(
          'Reporte Diario',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: 'Menú de reportes',
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Volver',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDailyReport,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with device selection
            ThemedCard(
              gradient: AppTheme.surfaceGradient,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.assessment_outlined,
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
                              'Reporte Diario',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            GestureDetector(
                              onTap: _selectDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.primaryBlue),
                                  borderRadius: BorderRadius.circular(8),
                                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: AppTheme.primaryBlue,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatSelectedDate(),
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.primaryBlue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      color: AppTheme.primaryBlue,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Device Selection
                  Text(
                    'Seleccionar Dispositivo:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDeviceSelector(),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Estadísticas principales
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (dailyReport != null) ...[
              _buildStatsSection(),
              const SizedBox(height: 20),
              _buildEnhancedSummary(),
              const SizedBox(height: 20),
              // Botón de descarga PDF
              if (dailyReport != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: SimplePdfButton(
                    dailyReport: dailyReport,
                    text: 'Descargar PDF ($selectedDeviceLabel)',
                    icon: Icons.picture_as_pdf,
                    color: Colors.red[700],
                  ),
                ),
              // Gráficos y métricas
              _buildChartsSection(),
            ] else
              _buildErrorSection(),
          ],
        ),
      ),
    );
  }


  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen Estadístico ($selectedDeviceLabel)',
          style: context.textTheme.headlineSmall?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Temperatura Promedio',
                '${dailyReport?.temperature.tpro.toStringAsFixed(1) ?? '--'}°C',
                Icons.thermostat,
                const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)]),
                'Hoy',
                null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Temp. Máxima',
                '${dailyReport?.temperature.tmax.toStringAsFixed(1) ?? '--'}°C',
                Icons.trending_up,
                const LinearGradient(colors: [Color(0xFFFF5722), Color(0xFFFF7043)]),
                'Máx',
                true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Temp. Mínima',
                '${dailyReport?.temperature.tmin.toStringAsFixed(1) ?? '--'}°C',
                Icons.trending_down,
                const LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF42A5F5)]),
                'Mín',
                false,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Humedad Promedio',
                '${dailyReport?.humidity.hpro.toStringAsFixed(1) ?? '--'}%',
                Icons.water_drop,
                const LinearGradient(colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)]),
                'Ambiente',
                null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Radiación Total',
                '${dailyReport?.radiation.radTot.toStringAsFixed(0) ?? '--'} W/m²',
                Icons.wb_sunny,
                const LinearGradient(colors: [Color(0xFFFFD93D), Color(0xFFFF8C42)]),
                'Total',
                null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Radiación Máxima',
                '${dailyReport?.radiation.radMax.toStringAsFixed(0) ?? '--'} W/m²',
                Icons.brightness_high,
                const LinearGradient(colors: [Color(0xFFFFC107), Color(0xFFFFB300)]),
                'Pico',
                true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Gradient gradient,
    String change,
    bool? isPositive,
  ) {
    return ThemedCard(
      gradient: gradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isPositive != null) ...[
                          Icon(
                            isPositive == true ? Icons.trending_up : Icons.trending_down,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          change,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSummary() {
    return ThemedCard(
      gradient: AppTheme.surfaceGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Resumen Detallado de Datos Ambientales ($selectedDeviceLabel)',
                  style: context.textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryBlue.withValues(alpha: 0.1),
                  AppTheme.primaryBlue.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryBlue.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                _buildSummaryRow(
                  'Temperatura',
                  'Promedio: ${dailyReport?.temperature.tpro.toStringAsFixed(1)}°C',
                  'Rango: ${dailyReport?.temperature.tmin.toStringAsFixed(1)}°C - ${dailyReport?.temperature.tmax.toStringAsFixed(1)}°C',
                  Icons.thermostat,
                  const Color(0xFFFF6B6B),
                ),
                const Divider(color: AppTheme.textSecondary, height: 24),
                _buildSummaryRow(
                  'Humedad Relativa',
                  'Promedio: ${dailyReport?.humidity.hpro.toStringAsFixed(1)}%',
                  'Condiciones ambientales óptimas',
                  Icons.water_drop,
                  const Color(0xFF4ECDC4),
                ),
                const Divider(color: AppTheme.textSecondary, height: 24),
                _buildSummaryRow(
                  'Radiación Solar',
                  'Promedio: ${dailyReport?.radiation.radPro.toStringAsFixed(0)} W/m²',
                  'Total: ${dailyReport?.radiation.radTot.toStringAsFixed(0)} W/m² | Máx: ${dailyReport?.radiation.radMax.toStringAsFixed(0)} W/m²',
                  Icons.wb_sunny,
                  const Color(0xFFFFD93D),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String title,
    String primaryValue,
    String secondaryInfo,
    IconData icon,
    Color iconColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                primaryValue,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                secondaryInfo,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Datos de Sensores por Hora ($selectedDeviceLabel)',
          style: context.textTheme.headlineSmall?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ThemedCard(
          gradient: AppTheme.surfaceGradient,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.table_chart, color: AppTheme.textSecondary),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      'Tabla de Datos Detallada',
                      style: context.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Información sobre las columnas
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.background.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.textSecondary.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Medidas por Hora',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildLegendItem('Temperatura', const Color(0xFFFF6B6B), '°C'),
                        _buildLegendItem('Humedad', const Color(0xFF4ECDC4), '%'),
                        _buildLegendItem('Radiación', const Color(0xFFFFD93D), 'W/m²'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Tabla de datos
              dailyReport != null && dailyReport!.rows.isNotEmpty
                  ? _buildSensorDataTable()
                  : Container(
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.primaryBlue.withValues(alpha: 0.1),
                            AppTheme.primaryBlue.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.table_chart,
                              color: AppTheme.textSecondary,
                              size: 48,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Sin datos disponibles',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSensorDataTable() {
    if (dailyReport == null || dailyReport!.rows.isEmpty) {
      return const SizedBox();
    }

    final data = dailyReport!.rows;
    
    // Crear array de 24 horas (0-23) con datos completos
    List<HourlyDataModel?> fullDayData = List.filled(24, null);
    for (var hourData in data) {
      if (hourData.hour >= 0 && hourData.hour < 24) {
        fullDayData[hourData.hour] = hourData;
      }
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.textSecondary.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header de la tabla
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1976D2), Color(0xFF2196F3)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Hora',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Temp (°C)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Humedad (%)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Radiación (W/m²)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // Cuerpo de la tabla con scroll
          SizedBox(
            height: 400, // Altura fija para el scroll
            child: SingleChildScrollView(
              child: Column(
                children: List.generate(24, (hour) {
                  final hourData = fullDayData[hour];
                  final isEvenRow = hour % 2 == 0;
                  final formattedHour = _formatHourLabel(hour);

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isEvenRow 
                          ? AppTheme.background.withOpacity(0.3) 
                          : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: AppTheme.textSecondary.withOpacity(0.1),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Hora
                        Expanded(
                          flex: 2,
                          child: Text(
                            formattedHour,
                            style: TextStyle(
                              color: hourData != null 
                                  ? AppTheme.textPrimary 
                                  : AppTheme.textSecondary,
                              fontWeight: hourData != null 
                                  ? FontWeight.w600 
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        // Temperatura
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            decoration: hourData != null
                                ? BoxDecoration(
                                    color: const Color(0xFFFF6B6B).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFFF6B6B).withOpacity(0.3),
                                    ),
                                  )
                                : null,
                            child: Text(
                              hourData != null
                                  ? '${hourData.temperatureAvg.toStringAsFixed(1)}'
                                  : '--',
                              style: TextStyle(
                                color: hourData != null
                                    ? const Color(0xFFFF6B6B)
                                    : AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        // Humedad
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            decoration: hourData != null
                                ? BoxDecoration(
                                    color: const Color(0xFF4ECDC4).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF4ECDC4).withOpacity(0.3),
                                    ),
                                  )
                                : null,
                            child: Text(
                              hourData != null
                                  ? '${hourData.humidityAvg.toStringAsFixed(1)}'
                                  : '--',
                              style: TextStyle(
                                color: hourData != null
                                    ? const Color(0xFF4ECDC4)
                                    : AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        // Radiación
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            decoration: hourData != null
                                ? BoxDecoration(
                                    color: const Color(0xFFFFD93D).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFFFD93D).withOpacity(0.3),
                                    ),
                                  )
                                : null,
                            child: Text(
                              hourData != null
                                  ? '${hourData.solarRadiationAvg.toStringAsFixed(0)}'
                                  : '--',
                              style: TextStyle(
                                color: hourData != null
                                    ? const Color(0xFFFFBF00)
                                    : AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatHourLabel(int hour) {
    if (hour == 0) return '12 am';
    if (hour < 12) return '$hour am';
    if (hour == 12) return '12 pm';
    return '${hour - 12} pm';
  }

  String _formatSelectedDate() {
    final months = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${selectedDate.day} de ${months[selectedDate.month]} ${selectedDate.year}';
  }

  Widget _buildLegendItem(String label, Color color, String unit) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$label ($unit)',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSection() {
    return ThemedCard(
      gradient: AppTheme.surfaceGradient,
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppTheme.textSecondary,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Error al cargar datos',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No se pudieron obtener los datos del servidor',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadDailyReport,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadPdf() async {
    if (dailyReport == null) return;

    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Generando PDF ($selectedDeviceLabel)...',
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Generar el PDF
      final file = await PdfService.generateReportPdf(dailyReport!);

      // Cerrar el diálogo de carga
      if (mounted) Navigator.of(context).pop();

      if (file != null && mounted) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'PDF $selectedDeviceLabel generado exitosamente',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Guardado en: ${file.path}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else if (mounted) {
        // Mostrar mensaje de error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error al generar el PDF. Verifica los permisos de almacenamiento.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      // Cerrar el diálogo de carga si está abierto
      if (mounted) Navigator.of(context).pop();
      
      // Mostrar mensaje de error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Error inesperado: $e',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          ),
        );
      }
      debugPrint('Error downloading PDF: $e');
    }
  }

  void _addToHistory(DailyReportModel? report) {
    if (currentHistoryIndex < reportHistory.length - 1) {
      reportHistory.removeRange(currentHistoryIndex + 1, reportHistory.length);
    }
    reportHistory.add(report);
    currentHistoryIndex = reportHistory.length - 1;
  }

  bool canUndo() {
    return currentHistoryIndex > 0;
  }

  void _undoLastAction() {
    if (canUndo()) {
      setState(() {
        currentHistoryIndex--;
        dailyReport = reportHistory[currentHistoryIndex];
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.undo, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'Acción deshecha',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: AppTheme.info,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppTheme.primaryBlue,
              brightness: Brightness.light,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _loadDailyReport();
    }
  }

  void _scheduleReports() {
    final now = DateTime.now();
    
    // Programar reporte para las 8 AM
    final morning = DateTime(now.year, now.month, now.day, 8, 0);
    if (morning.isAfter(now)) {
      final timeUntilMorning = morning.difference(now);
      Future.delayed(timeUntilMorning, () => _generateScheduledReport('8:00 AM'));
    }
    
    // Programar reporte para las 3 PM (15:00)
    final afternoon = DateTime(now.year, now.month, now.day, 15, 0);
    if (afternoon.isAfter(now)) {
      final timeUntilAfternoon = afternoon.difference(now);
      Future.delayed(timeUntilAfternoon, () => _generateScheduledReport('3:00 PM'));
    }
  }

  Future<void> _generateScheduledReport(String time) async {
    try {
      final report = await DailyReportService.getDailyReport(
        accessToken: widget.accessToken,
        deviceId: selectedDevice,
        date: DateTime.now(),
      );
      
      if (report != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.schedule, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Reporte $selectedDeviceLabel programado a las $time',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error al generar reporte $selectedDeviceLabel programado: $e',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}