import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/models/monthly_report_model.dart';
import '../../data/services/monthly_report_service.dart';

class MonthlyReportCard extends StatefulWidget {
  final String accessToken;

  const MonthlyReportCard({super.key, required this.accessToken});

  @override
  State<MonthlyReportCard> createState() => _MonthlyReportCardState();
}

class _MonthlyReportCardState extends State<MonthlyReportCard> {
  final MonthlyReportService _monthlyReportService = MonthlyReportService();
  String _selectedDevice = 'ESP32_1';
  bool _isLoading = false;
  String? _errorMessage;
  MonthlyReport? _monthlyReport;

  final List<String> _devices = ['ESP32_1', 'ESP32_2'];
  final Map<String, String> _deviceLabels = {
    'ESP32_1': 'Interno',
    'ESP32_2': 'Externo',
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
      final now = DateTime.now();
      final report = await _monthlyReportService.getMonthlyReport(
        deviceId: _selectedDevice,
        year: now.year,
        month: now.month,
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

  @override
  Widget build(BuildContext context) {
    return ThemedCard(
      gradient: AppTheme.surfaceGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Datos del mes actual',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Device Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.surfaceDark),
              borderRadius: BorderRadius.circular(8),
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
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Content
          Flexible(
            child: _buildContent(),
          ),
        ],
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
              'Cargando datos...',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: AppTheme.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar datos',
              style: TextStyle(
                color: AppTheme.error,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMonthlyReport,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_monthlyReport == null || _monthlyReport!.data.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.data_usage_outlined,
              color: AppTheme.textSecondary,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'No hay datos disponibles',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return _buildDataTable();
  }

  Widget _buildDataTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.surfaceDark),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DataTable(
            columnSpacing: 16,
            horizontalMargin: 16,
            headingRowHeight: 48,
            dataRowHeight: 40,
            columns: const [
              DataColumn(
                label: Text(
                  'Día',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'RadTot',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'RadPro',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'RadMax',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'HR',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Tmax',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Tmin',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Tpro',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
            rows: _monthlyReport!.data.map((data) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      data.day.toString(),
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                  ),
                  DataCell(
                    Text(
                      data.radTot.toStringAsFixed(2),
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                  ),
                  DataCell(
                    Text(
                      data.radPro.toStringAsFixed(2),
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                  ),
                  DataCell(
                    Text(
                      data.radMax.toStringAsFixed(2),
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${data.hr.toStringAsFixed(1)}%',
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${data.tmax.toStringAsFixed(1)}°C',
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${data.tmin.toStringAsFixed(1)}°C',
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${data.tpro.toStringAsFixed(1)}°C',
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}