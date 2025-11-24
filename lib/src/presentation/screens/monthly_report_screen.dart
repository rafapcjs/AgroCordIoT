import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../utils/navigation_helper.dart';
import '../../data/models/monthly_report_model.dart';
import '../../data/services/monthly_report_service.dart';
import '../widgets/navigation/report_navigation_drawer.dart';
import '../widgets/buttonsPdf/buttons_pdf.dart';
import 'package:intl/intl.dart';

class MonthlyReportScreen extends StatefulWidget {
  final String accessToken;

  const MonthlyReportScreen({super.key, required this.accessToken});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  final MonthlyReportService _monthlyReportService = MonthlyReportService();
  String _selectedDevice = 'ESP32_1';
  bool _isLoading = false;
  String? _errorMessage;
  MonthlyReport? _monthlyReport;
  DateTime _selectedDate = DateTime.now();

  final List<String> _devices = ['ESP32_1', 'ESP32_2'];
  final Map<String, String> _deviceLabels = {
    'ESP32_1': 'Monitor Interno',
    'ESP32_2': 'Monitor Externo',
  };

  @override
  void initState() {
    super.initState();
    _loadMonthlyReport();
  }

  Future<void> _loadMonthlyReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final report = await _monthlyReportService.getMonthlyReport(
        deviceId: _selectedDevice,
        year: _selectedDate.year,
        month: _selectedDate.month,
        accessToken: widget.accessToken,
      );
      setState(() {
        _monthlyReport = report;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onDeviceChanged(String? device) {
    if (device != null && device != _selectedDevice) {
      setState(() {
        _selectedDevice = device;
      });
      _loadMonthlyReport();
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Seleccionar mes y año',
      fieldLabelText: 'Mes/Año',
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryBlue,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && (picked.year != _selectedDate.year || picked.month != _selectedDate.month)) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month);
      });
      _loadMonthlyReport();
    }
  }

  /// Convierte fechas UTC a GMT-5 (hora local de Colombia)
  DateTime _convertToLocalTime(DateTime utcTime) {
    return utcTime.subtract(const Duration(hours: 5));
  }

  /// Convierte fechas locales a UTC para envío al servidor
  DateTime _convertToUtc(DateTime localTime) {
    return localTime.add(const Duration(hours: 5));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: ReportNavigationDrawer(
        selectedLabel: 'Reporte del Mes',
        items: [
          ReportNavigationItem(
            icon: Icons.sensors,
            label: 'Ver Sensores en Tiempo Real',
            onTap: () {
              Navigator.of(context).pushReplacementNamed(
                '/sensors/dashboard',
                arguments: {'accessToken': widget.accessToken},
              );
            },
          ),
          ReportNavigationItem(
            icon: Icons.assessment_outlined,
            label: 'Reporte del Día',
            onTap: () {
              Navigator.of(context).pushReplacementNamed(
                '/reports/internal',
                arguments: {
                  'accessToken': widget.accessToken,
                  'deviceId': _selectedDevice,
                },
              );
            },
          ),
          ReportNavigationItem(
            icon: Icons.calendar_view_week,
            label: 'Reporte de la Semana',
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
            label: 'Reporte del Mes',
            onTap: () {
              Navigator.of(context).pushReplacementNamed(
                '/reports/monthly',
                arguments: {'accessToken': widget.accessToken},
              );
            },
          ),
          ReportNavigationItem(
            icon: Icons.dashboard_outlined,
            label: 'Volver al Inicio',
            onTap: () {
              NavigationHelper.navigateToDashboard(context);
            },
          ),
        ],
      ),
      appBar: AppBar(
        title: const Text(
          'Reporte Mensual',
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
            onPressed: _loadMonthlyReport,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
                            colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calendar_month_outlined,
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
                              'Reporte Mensual',
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
                                      '${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.surfaceDark),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: DropdownButton<String>(
                      value: _selectedDevice,
                      onChanged: _onDeviceChanged,
                      underline: const SizedBox(),
                      isExpanded: true,
                      items: _devices.map((String device) {
                        return DropdownMenuItem<String>(
                          value: device,
                          child: Text(
                            _deviceLabels[device] ?? device,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Botón de descarga PDF
            if (_monthlyReport != null && _monthlyReport!.data.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SimplePdfButton(
                  monthlyReport: _monthlyReport,
                  text: 'Descargar PDF (${_deviceLabels[_selectedDevice]})',
                  icon: Icons.picture_as_pdf,
                  color: Colors.green[700],
                ),
              ),

            // Content
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Cargando datos del reporte...',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: ThemedCard(
          gradient: AppTheme.surfaceGradient,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: AppTheme.error,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Error al cargar datos',
                style: TextStyle(
                  color: AppTheme.error,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadMonthlyReport,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_monthlyReport == null || _monthlyReport!.data.isEmpty) {
      return Center(
        child: ThemedCard(
          gradient: AppTheme.surfaceGradient,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.data_usage_outlined,
                color: AppTheme.textSecondary,
                size: 64,
              ),
              SizedBox(height: 16),
              Text(
                'No hay datos disponibles',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'No se encontraron datos para el dispositivo seleccionado en este mes.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Filter data with values (non-zero)
    final filteredData = _monthlyReport!.data.where((data) => 
      data.radTot > 0 || data.radPro > 0 || data.radMax > 0 || 
      data.hr > 0 || data.tmax > 0 || data.tmin > 0 || data.tpro > 0
    ).toList();

    if (filteredData.isEmpty) {
      return Center(
        child: ThemedCard(
          gradient: AppTheme.surfaceGradient,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.filter_alt_outlined,
                color: AppTheme.textSecondary,
                size: 64,
              ),
              SizedBox(height: 16),
              Text(
                'No hay datos con valores',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Todos los días del mes tienen valores en cero.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return _buildDataCards(filteredData);
  }

  Widget _buildDataCards(List<MonthlyReportData> filteredData) {
    return ListView.builder(
      itemCount: filteredData.length,
      itemBuilder: (context, index) {
        final data = filteredData[index];
        return _buildDayCard(data);
      },
    );
  }

  Widget _buildDayCard(MonthlyReportData data) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ThemedCard(
        gradient: AppTheme.surfaceGradient,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Día ${data.day}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            // Data content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Radiation data
                  _buildDataSection(
                    'Radiación Solar',
                    Icons.wb_sunny_outlined,
                    const Color(0xFF9CCC65),
                    [
                      _buildDataRow('Radiación Total', '${data.radTot.toStringAsFixed(2)} MJ/m²'),
                      _buildDataRow('Radiación Promedio', '${data.radPro.toStringAsFixed(2)} W/m²'),
                      _buildDataRow('Radiación Máxima', '${data.radMax.toStringAsFixed(2)} W/m²'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Temperature data
                  _buildDataSection(
                    'Temperatura',
                    Icons.thermostat_outlined,
                    const Color(0xFF66BB6A),
                    [
                      _buildDataRow('Temperatura Máxima', '${data.tmax.toStringAsFixed(1)}°C'),
                      _buildDataRow('Temperatura Mínima', '${data.tmin.toStringAsFixed(1)}°C'),
                      _buildDataRow('Temperatura Promedio', '${data.tpro.toStringAsFixed(1)}°C'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Humidity data
                  _buildDataSection(
                    'Humedad Relativa',
                    Icons.water_drop_outlined,
                    const Color(0xFF4DB6AC),
                    [
                      _buildDataRow('Humedad Relativa', '${data.hr.toStringAsFixed(1)}%'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSection(String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month];
  }
}
