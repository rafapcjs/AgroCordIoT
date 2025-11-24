import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import '../models/report.dart';
import '../services/report_service.dart';
import '../services/pdf_service.dart';
import '../presentation/widgets/navigation/report_navigation_drawer.dart';
import '../core/theme.dart';
import '../utils/navigation_helper.dart';

class WeeklyReportPage extends StatefulWidget {
  final String accessToken;

  const WeeklyReportPage({super.key, required this.accessToken});

  @override
  State<WeeklyReportPage> createState() => _WeeklyReportPageState();
}

class _WeeklyReportPageState extends State<WeeklyReportPage> {
  String selectedDevice = "ESP32_1";
  WeeklyReport? report;
  bool isLoading = false;
  String? errorMessage;
  bool isGeneratingPdf = false;

  final ReportService _reportService = ReportService();

  final Map<String, String> deviceOptions = {
    "ESP32_1": "Monitor Interno",
    "ESP32_2": "Monitor Externo",
  };

  @override
  void initState() {
    super.initState();
    loadReport();
  }

  Future<void> loadReport() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await _reportService.fetchWeeklyReport(selectedDevice, widget.accessToken);
      setState(() {
        report = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _generatePdf() async {
    if (report == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay datos para generar el PDF'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isGeneratingPdf = true;
    });

    try {
      final pdfFile = await PdfService.generateWeeklyReportPdf(report!, selectedDevice);
      
      setState(() {
        isGeneratingPdf = false;
      });

      if (pdfFile != null) {
        // Mostrar diálogo con opciones
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('PDF Generado'),
            content: const Text('El reporte PDF se ha generado exitosamente. ¿Qué desea hacer?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // Compartir el archivo PDF usando share_plus
                  try {
                    await Share.shareXFiles(
                      [XFile(pdfFile.path)],
                      text: 'Reporte Semanal - AgroCordIoT',
                      subject: 'Reporte Semanal IoT',
                    );
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al compartir: $e')),
                      );
                    }
                  }
                },
                child: const Text('Compartir'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final result = await OpenFile.open(pdfFile.path);
                  if (result.type != ResultType.done && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No se pudo abrir el PDF'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                child: const Text('Abrir'),
              ),
            ],
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al generar el PDF'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isGeneratingPdf = false;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: ReportNavigationDrawer(
        selectedLabel: 'Reporte semanal',
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
          'Reporte Semanal',
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
            icon: isGeneratingPdf 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: isGeneratingPdf ? null : _generatePdf,
            tooltip: 'Descargar PDF',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: loadReport,
            tooltip: 'Actualizar',
          ),
        ],
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildDropdownSection(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[700]!, Colors.green[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.monitor_outlined, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Seleccionar Monitor',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedDevice,
                isExpanded: true,
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.green[700], size: 26),
                ),
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(16),
                items: deviceOptions.entries.map((entry) {
                  final isInternal = entry.key == "ESP32_1";
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.green[400]!, Colors.green[600]!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              isInternal ? Icons.home_rounded : Icons.park_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (selectedDevice == entry.key)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.green[700],
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null && newValue != selectedDevice) {
                    setState(() {
                      selectedDevice = newValue;
                    });
                    loadReport();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Error al cargar el reporte',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: loadReport,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (report == null) {
      return const Center(
        child: Text('No hay datos disponibles'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummarySection(),
        const SizedBox(height: 24),
        _buildDailySection(),
      ],
    );
  }

  Widget _buildSummarySection() {
    if (report!.sensors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[700]!, Colors.green[500]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.analytics, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumen General de la Semana',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Promedios de los últimos 7 días',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...report!.sensors.map((sensor) => _buildSensorCard(sensor)),
      ],
    );
  }

  Widget _buildSensorCard(SensorSummary sensor) {
    final sensorName = _getSensorDisplayName(sensor.sensor);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.green[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[600]!, Colors.green[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _getSensorIcon(sensor.sensor),
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sensorName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.show_chart, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Promedio de ${sensor.samples} muestras',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green[700],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      sensor.average.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      sensor.units,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailySection() {
    if (report!.daily.isEmpty) {
      return const SizedBox.shrink();
    }

    // Ordenar los días de Lunes a Domingo
    final sortedDays = _sortDaysByWeek(report!.daily);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[700]!, Colors.green[500]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_month, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detalles Diarios',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Análisis día por día (Lunes - Domingo)',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...sortedDays.map((daily) => _buildDailyExpansionTile(daily)),
      ],
    );
  }

  // Ordenar días de la semana (Lunes a Domingo)
  List<DailyReport> _sortDaysByWeek(List<DailyReport> days) {
    final dayOrder = {
      'Lunes': 1,
      'Martes': 2,
      'Miércoles': 3,
      'Jueves': 4,
      'Viernes': 5,
      'Sábado': 6,
      'Domingo': 7,
    };

    final sortedList = List<DailyReport>.from(days);
    sortedList.sort((a, b) {
      final orderA = dayOrder[a.day] ?? 999;
      final orderB = dayOrder[b.day] ?? 999;
      return orderA.compareTo(orderB);
    });

    return sortedList;
  }

  Widget _buildDailyExpansionTile(DailyReport daily) {
    // Obtener el color según el día de la semana
    Color dayColor = _getDayColor(daily.day);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [dayColor, dayColor.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: dayColor.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _getDayInitial(daily.day),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                _getDayNumber(daily.date),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
        title: Text(
          _getFullDayName(daily.day),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                _formatDate(daily.date),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              if (daily.sensors.isNotEmpty) ...[
                Icon(Icons.sensors, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${daily.sensors.length} sensores',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
        children: [
          if (daily.sensors.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 40, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Sin datos registrados',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...daily.sensors.map((sensor) => _buildDailySensorRow(sensor)),
        ],
      ),
    );
  }

  // Obtener inicial del día
  String _getDayInitial(String day) {
    if (day.isEmpty) return '?';
    
    final dayMap = {
      'Lunes': 'L',
      'Martes': 'M',
      'Miércoles': 'X',
      'Jueves': 'J',
      'Viernes': 'V',
      'Sábado': 'S',
      'Domingo': 'D',
    };
    return dayMap[day] ?? day.substring(0, 1).toUpperCase();
  }

  // Obtener nombre completo del día en español
  String _getFullDayName(String day) {
    // El día ya viene en español desde el backend
    return day;
  }

  // Obtener el número del día de la fecha
  String _getDayNumber(String date) {
    try {
      // Fecha viene como "2025-11-17T00:00:00Z"
      final parts = date.split('T')[0].split('-');
      if (parts.length >= 3) {
        return parts[2]; // Día
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  // Formatear fecha a un formato más legible
  String _formatDate(String date) {
    try {
      // Fecha viene como "2025-11-17T00:00:00Z"
      final parts = date.split('T')[0].split('-');
      if (parts.length >= 3) {
        final months = [
          '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
          'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
        ];
        final day = parts[2];
        final month = int.parse(parts[1]);
        final year = parts[0];
        return '$day ${months[month]} $year';
      }
      return date;
    } catch (e) {
      return date;
    }
  }

  // Obtener color según el día de la semana
  Color _getDayColor(String day) {
    final colorMap = {
      'Lunes': Colors.blue[600]!,
      'Martes': Colors.purple[600]!,
      'Miércoles': Colors.green[600]!,
      'Jueves': Colors.orange[600]!,
      'Viernes': Colors.teal[600]!,
      'Sábado': Colors.indigo[600]!,
      'Domingo': Colors.red[600]!,
    };
    return colorMap[day] ?? Colors.grey[600]!;
  }

  Widget _buildDailySensorRow(SensorSummary sensor) {
    final sensorName = _getSensorDisplayName(sensor.sensor);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            _getSensorIcon(sensor.sensor),
            color: Colors.grey[700],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sensorName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '${sensor.samples} muestras',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                sensor.average.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                sensor.units,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Convertir nombre técnico del sensor a nombre legible
  String _getSensorDisplayName(String sensorType) {
    final nameMap = {
      'temperature': 'Temperatura',
      'humidity': 'Humedad',
      'solar_radiation': 'Radiación Solar',
      'ph': 'pH del Suelo',
      'ec': 'Conductividad Eléctrica',
      'soil_moisture': 'Humedad del Suelo',
      'light': 'Luz',
      'pressure': 'Presión Atmosférica',
      'wind_speed': 'Velocidad del Viento',
      'rainfall': 'Precipitación',
      'uv_index': 'Índice UV',
      'co2': 'Dióxido de Carbono',
      'nitrogen': 'Nitrógeno',
      'phosphorus': 'Fósforo',
      'potassium': 'Potasio',
    };
    
    // Si no está en el mapa, capitalizar primera letra
    if (nameMap.containsKey(sensorType)) {
      return nameMap[sensorType]!;
    }
    
    // Intentar convertir guiones bajos a espacios y capitalizar
    String formatted = sensorType.replaceAll('_', ' ');
    if (formatted.isNotEmpty) {
      formatted = formatted.split(' ').map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1);
      }).join(' ');
    }
    
    return formatted.isEmpty ? sensorType : formatted;
  }

  IconData _getSensorIcon(String sensorName) {
    final name = sensorName.toLowerCase();
    if (name.contains('temperatura') || name.contains('temperature')) {
      return Icons.thermostat;
    } else if (name.contains('humedad') || name.contains('humidity')) {
      return Icons.water_drop;
    } else if (name.contains('luz') || name.contains('light') || name.contains('solar') || name.contains('radiation')) {
      return Icons.wb_sunny;
    } else if (name.contains('ph')) {
      return Icons.science;
    } else if (name.contains('conductividad') || name.contains('ec')) {
      return Icons.bolt;
    } else if (name.contains('soil') || name.contains('suelo')) {
      return Icons.grass;
    } else {
      return Icons.sensors;
    }
  }
}
