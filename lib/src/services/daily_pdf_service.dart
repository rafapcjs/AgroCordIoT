import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import '../data/models/daily_report_model.dart';

class DailyPdfService {
  /// Genera un PDF específico para reportes diarios
  static Future<File?> generateDailyReportPdf(DailyReportModel report, {String deviceLabel = 'Dispositivo'}) async {
    try {
      final pdf = pw.Document();

      // Agregar página con el reporte completo
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildHeader(report, deviceLabel),
          footer: (context) => _buildFooter(context),
          build: (context) => _buildDailyReportContent(report, deviceLabel),
        ),
      );

      // Guardar el archivo con nombre específico
      final fileName = 'reporte_diario_${deviceLabel.toLowerCase()}_${_formatDateForFile(report.date)}.pdf';
      
      File file;
      if (kIsWeb) {
        final bytes = await pdf.save();
        final tempDir = Directory.systemTemp;
        file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(bytes);
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        file = File('${appDir.path}/$fileName');
        await file.writeAsBytes(await pdf.save());
      }

      debugPrint('PDF generado exitosamente: ${file.path}');
      return file;

    } catch (e) {
      debugPrint('Error generando PDF de reporte diario: $e');
      return null;
    }
  }

  /// Genera y comparte el PDF del reporte diario
  static Future<bool> generateAndShareDailyPdf(DailyReportModel report, {String deviceLabel = 'Dispositivo'}) async {
    try {
      final file = await generateDailyReportPdf(report, deviceLabel: deviceLabel);
      if (file == null) return false;
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Reporte Diario IoT - $deviceLabel - ${report.date}',
        subject: 'Reporte Diario - $deviceLabel - ${report.date}',
      );
      
      return true;
    } catch (e) {
      debugPrint('Error compartiendo PDF de reporte diario: $e');
      return false;
    }
  }

  /// Genera y abre el PDF del reporte diario
  static Future<bool> generateAndOpenDailyPdf(DailyReportModel report, {String deviceLabel = 'Dispositivo'}) async {
    try {
      final file = await generateDailyReportPdf(report, deviceLabel: deviceLabel);
      if (file == null) return false;
      
      final result = await OpenFile.open(file.path);
      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('Error abriendo PDF de reporte diario: $e');
      return false;
    }
  }

  /// Construye el encabezado del PDF
  static pw.Widget _buildHeader(DailyReportModel report, String deviceLabel) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            width: 2,
            color: PdfColors.blue600,
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'REPORTE DIARIO IoT',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Sistema de Monitoreo Agrícola',
                style: pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Dispositivo: $deviceLabel',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Fecha: ${report.date}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.Text(
                'Generado: ${_formatCurrentDateTime()}',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construye el pie de página del PDF
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(
            width: 1,
            color: PdfColors.grey400,
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Universidad de Córdoba - Sistema IoT Agrícola',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el contenido principal del reporte diario
  static List<pw.Widget> _buildDailyReportContent(DailyReportModel report, String deviceLabel) {
    return [
      // Resumen estadístico
      _buildStatisticsSection(report),
      
      pw.SizedBox(height: 30),
      
      // Tabla de datos por hora
      _buildHourlyDataTable(report),
      
      pw.SizedBox(height: 30),
      
      // Análisis de condiciones
      _buildConditionsAnalysis(report),
    ];
  }

  /// Construye la sección de estadísticas
  static pw.Widget _buildStatisticsSection(DailyReportModel report) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'RESUMEN ESTADÍSTICO',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue700,
          ),
        ),
        pw.SizedBox(height: 15),
        
        // Estadísticas en tabla
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          columnWidths: const {
            0: pw.FlexColumnWidth(2),
            1: pw.FlexColumnWidth(1),
            2: pw.FlexColumnWidth(1),
            3: pw.FlexColumnWidth(1),
          },
          children: [
            // Encabezado
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blue100),
              children: [
                _buildTableCell('Parámetro', isHeader: true),
                _buildTableCell('Promedio', isHeader: true),
                _buildTableCell('Mínimo', isHeader: true),
                _buildTableCell('Máximo', isHeader: true),
              ],
            ),
            // Temperatura
            pw.TableRow(
              children: [
                _buildTableCell('Temperatura (°C)'),
                _buildTableCell('${report.temperature.tpro.toStringAsFixed(1)}'),
                _buildTableCell('${report.temperature.tmin.toStringAsFixed(1)}'),
                _buildTableCell('${report.temperature.tmax.toStringAsFixed(1)}'),
              ],
            ),
            // Humedad
            pw.TableRow(
              children: [
                _buildTableCell('Humedad Relativa (%)'),
                _buildTableCell('${report.humidity.hpro.toStringAsFixed(1)}'),
                _buildTableCell('--'),
                _buildTableCell('--'),
              ],
            ),
            // Radiación
            pw.TableRow(
              children: [
                _buildTableCell('Radiación Solar (W/m²)'),
                _buildTableCell('${report.radiation.radPro.toStringAsFixed(0)}'),
                _buildTableCell('--'),
                _buildTableCell('${report.radiation.radMax.toStringAsFixed(0)}'),
              ],
            ),
          ],
        ),
        
        pw.SizedBox(height: 15),
        
        // Información adicional
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Información adicional:',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '• Total de lecturas registradas: ${report.rows.length}',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.Text(
                '• Radiación solar total acumulada: ${report.radiation.radTot.toStringAsFixed(0)} W/m²',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.Text(
                '• Dispositivo de monitoreo: ${report.deviceId}',
                style: const pw.TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Construye la tabla de datos por hora
  static pw.Widget _buildHourlyDataTable(DailyReportModel report) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'DATOS POR HORA',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue700,
          ),
        ),
        pw.SizedBox(height: 15),
        
        // Tabla de datos horarios
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          columnWidths: const {
            0: pw.FlexColumnWidth(1),
            1: pw.FlexColumnWidth(1.5),
            2: pw.FlexColumnWidth(1.5),
            3: pw.FlexColumnWidth(1.5),
          },
          children: [
            // Encabezado
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blue100),
              children: [
                _buildTableCell('Hora', isHeader: true),
                _buildTableCell('Temperatura (°C)', isHeader: true),
                _buildTableCell('Humedad (%)', isHeader: true),
                _buildTableCell('Radiación (W/m²)', isHeader: true),
              ],
            ),
            
            // Datos (crear array completo de 24 horas)
            ...List.generate(24, (hour) {
              final hourDataList = report.rows.where((row) => row.hour == hour);
              final hourData = hourDataList.isNotEmpty ? hourDataList.first : null;
              
              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: hour % 2 == 0 ? PdfColors.grey50 : PdfColors.white,
                ),
                children: [
                  _buildTableCell(_formatHour(hour)),
                  _buildTableCell(hourData != null ? hourData.temperatureAvg.toStringAsFixed(1) : '--'),
                  _buildTableCell(hourData != null ? hourData.humidityAvg.toStringAsFixed(1) : '--'),
                  _buildTableCell(hourData != null ? hourData.solarRadiationAvg.toStringAsFixed(0) : '--'),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  /// Construye el análisis de condiciones
  static pw.Widget _buildConditionsAnalysis(DailyReportModel report) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'ANÁLISIS DE CONDICIONES AMBIENTALES',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue700,
          ),
        ),
        pw.SizedBox(height: 15),
        
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.blue300),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildAnalysisPoint('Temperatura:', _analyzeTemperature(report.temperature)),
              pw.SizedBox(height: 8),
              _buildAnalysisPoint('Humedad:', _analyzeHumidity(report.humidity)),
              pw.SizedBox(height: 8),
              _buildAnalysisPoint('Radiación Solar:', _analyzeRadiation(report.radiation)),
              pw.SizedBox(height: 8),
              _buildAnalysisPoint('Recomendación:', _generateRecommendation(report)),
            ],
          ),
        ),
      ],
    );
  }

  /// Construye una celda de tabla
  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 11,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.blue800 : PdfColors.black,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Construye un punto de análisis
  static pw.Widget _buildAnalysisPoint(String title, String content) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue700,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Text(
            content,
            style: const pw.TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }

  /// Analiza los datos de temperatura
  static String _analyzeTemperature(TemperatureStatsModel temp) {
    if (temp.tpro < 15) {
      return 'Temperatura baja (${temp.tpro.toStringAsFixed(1)}°C). Condiciones frías.';
    } else if (temp.tpro > 35) {
      return 'Temperatura alta (${temp.tpro.toStringAsFixed(1)}°C). Condiciones cálidas.';
    } else {
      return 'Temperatura óptima (${temp.tpro.toStringAsFixed(1)}°C). Condiciones favorables.';
    }
  }

  /// Analiza los datos de humedad
  static String _analyzeHumidity(HumidityStatsModel humidity) {
    if (humidity.hpro < 40) {
      return 'Humedad baja (${humidity.hpro.toStringAsFixed(1)}%). Ambiente seco.';
    } else if (humidity.hpro > 80) {
      return 'Humedad alta (${humidity.hpro.toStringAsFixed(1)}%). Ambiente húmedo.';
    } else {
      return 'Humedad adecuada (${humidity.hpro.toStringAsFixed(1)}%). Condiciones normales.';
    }
  }

  /// Analiza los datos de radiación
  static String _analyzeRadiation(RadiationStatsModel radiation) {
    if (radiation.radPro < 200) {
      return 'Radiación baja (${radiation.radPro.toStringAsFixed(0)} W/m²). Día nublado o medición nocturna.';
    } else if (radiation.radPro > 800) {
      return 'Radiación alta (${radiation.radPro.toStringAsFixed(0)} W/m²). Día muy soleado.';
    } else {
      return 'Radiación moderada (${radiation.radPro.toStringAsFixed(0)} W/m²). Condiciones normales.';
    }
  }

  /// Genera recomendaciones basadas en los datos
  static String _generateRecommendation(DailyReportModel report) {
    final temp = report.temperature.tpro;
    final humidity = report.humidity.hpro;
    final radiation = report.radiation.radPro;

    if (temp > 30 && humidity < 50 && radiation > 600) {
      return 'Considerar incrementar el riego debido a las condiciones de alta temperatura y baja humedad.';
    } else if (temp < 20 && humidity > 70) {
      return 'Monitorear posibles hongos o enfermedades debido a las condiciones de baja temperatura y alta humedad.';
    } else if (radiation < 300) {
      return 'Día con poca radiación solar, evaluar necesidad de luz artificial si es necesario.';
    } else {
      return 'Condiciones ambientales dentro de rangos normales. Mantener monitoreo regular.';
    }
  }

  /// Formatea la hora para mostrar
  static String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }

  /// Formatea la fecha para el nombre del archivo
  static String _formatDateForFile(String date) {
    return date.replaceAll('/', '_').replaceAll('-', '_');
  }

  /// Formatea la fecha y hora actual
  static String _formatCurrentDateTime() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}