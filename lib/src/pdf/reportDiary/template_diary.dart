import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import '../../data/models/monthly_report_model.dart';

class MonthlyReportTemplate {
  static Future<File?> generateMonthlyReportPdf(MonthlyReport report) async {
    try {
      debugPrint('=== INICIANDO GENERACIÓN PDF MENSUAL ===');
      debugPrint('DeviceId: ${report.deviceId}');
      debugPrint('Año: ${report.year}');
      debugPrint('Mes: ${report.month}');
      debugPrint('Total de días con datos: ${report.data.length}');
      
      if (report.data.isEmpty) {
        debugPrint('ADVERTENCIA: No hay datos para generar el PDF');
        return null;
      }
      
      final pdf = pw.Document();

      // Crear páginas con paginación automática
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return _buildReportWidgets(report);
          },
        ),
      );

      // Guardar el PDF en directorio de la app
      final fileName = 'reporte_mensual_${report.deviceId}_${report.year}_${report.month.toString().padLeft(2, '0')}.pdf';
      
      debugPrint('Guardando PDF: $fileName');
      
      if (kIsWeb) {
        final bytes = await pdf.save();
        final tempDir = Directory.systemTemp;
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        debugPrint('PDF generado en web: ${file.path}');
        return file;
      } else {
        try {
          // Para Android/iOS, intentar directorio de documentos primero
          final appDir = await getApplicationDocumentsDirectory();
          final file = File('${appDir.path}/$fileName');
          
          // Verificar que el directorio existe
          if (!await appDir.exists()) {
            await appDir.create(recursive: true);
          }
          
          final bytes = await pdf.save();
          await file.writeAsBytes(bytes);
          
          // Verificar que el archivo se creó correctamente
          if (await file.exists()) {
            final fileSize = await file.length();
            debugPrint('PDF mensual generado exitosamente: ${file.path} (${fileSize} bytes)');
            return file;
          } else {
            debugPrint('Error: El archivo PDF mensual no se creó correctamente');
            return null;
          }
        } catch (e) {
          debugPrint('Error guardando PDF mensual en directorio de documentos: $e');
          
          // Fallback: intentar directorio temporal
          try {
            final tempDir = Directory.systemTemp;
            final file = File('${tempDir.path}/$fileName');
            final bytes = await pdf.save();
            await file.writeAsBytes(bytes);
            debugPrint('PDF mensual guardado en directorio temporal: ${file.path}');
            return file;
          } catch (tempError) {
            debugPrint('Error guardando PDF mensual en directorio temporal: $tempError');
            return null;
          }
        }
      }

    } catch (e) {
      debugPrint('Error general generando PDF mensual: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // Método para compartir reporte mensual
  static Future<bool> shareMonthlyReport(MonthlyReport report) async {
    try {
      final file = await generateMonthlyReportPdf(report);
      if (file == null) return false;
      
      final monthNames = [
        '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
      ];
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Reporte mensual IoT - ${monthNames[report.month]} ${report.year}',
        subject: 'Reporte Mensual - Dispositivo ${report.deviceId}',
      );
      return true;
    } catch (e) {
      debugPrint('Error compartiendo PDF mensual: $e');
      return false;
    }
  }

  // Método para abrir reporte mensual
  static Future<bool> openMonthlyReport(MonthlyReport report) async {
    try {
      final file = await generateMonthlyReportPdf(report);
      if (file == null) return false;
      
      final result = await OpenFile.open(file.path);
      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('Error abriendo PDF mensual: $e');
      return false;
    }
  }

  static List<pw.Widget> _buildReportWidgets(MonthlyReport report) {
    final monthNames = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    final deviceName = report.deviceId == 'ESP32_1' ? 'Monitor Interno' : 'Monitor Externo';

    final stats = _calculateStats(report);
    
    debugPrint('Construyendo reporte con ${report.data.length} días');
    for (var day in report.data) {
      debugPrint('Día ${day.day}: Temp=${day.tpro}, Hum=${day.hr}, Rad=${day.radTot}');
    }
    
    const textStyle = pw.TextStyle(fontSize: 12);
    final headerStyle = pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold);
    final subHeaderStyle = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold);
    final tableBoldStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold);

    return [
        // Header mejorado con estilo similar al reporte diario
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 2),
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('REPORTE MENSUAL IoT', style: headerStyle),
              pw.SizedBox(height: 5),
              pw.Text('Sistema de Monitoreo Agrícola', style: textStyle),
              pw.Text('Universidad de Córdoba', style: textStyle),
            ],
          ),
        ),
        
        pw.SizedBox(height: 20),
        
        // Información del reporte
        pw.Text('INFORMACIÓN DEL REPORTE', style: subHeaderStyle),
        pw.SizedBox(height: 10),
        pw.Text('Dispositivo: $deviceName', style: textStyle),
        pw.Text('Periodo: ${monthNames[report.month]} ${report.year}', style: textStyle),
        pw.Text('Generado: ${DateTime.now().toString().substring(0, 16)}', style: textStyle),
        pw.Text('Total de días con datos: ${report.data.length}', style: textStyle),
        
        pw.SizedBox(height: 20),
        
        // Estadísticas mejoradas con tabla
        pw.Text('RESUMEN ESTADÍSTICO', style: subHeaderStyle),
        pw.SizedBox(height: 10),
        
        pw.Table(
          border: pw.TableBorder.all(),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Parámetro', style: tableBoldStyle),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Valor', style: tableBoldStyle),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Unidad', style: tableBoldStyle),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Temperatura Promedio', style: textStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${_safeFormatNumber(stats.avgTemp, 1)}', style: textStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('°C', style: textStyle)),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Temperatura Máxima', style: textStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${_safeFormatNumber(stats.maxTemp, 1)}', style: textStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('°C', style: textStyle)),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Temperatura Mínima', style: textStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${_safeFormatNumber(stats.minTemp, 1)}', style: textStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('°C', style: textStyle)),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Humedad Promedio', style: textStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${_safeFormatNumber(stats.avgHumidity, 1)}', style: textStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('%', style: textStyle)),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Radiación Total', style: textStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${_safeFormatNumber(stats.totalRadiation, 0)}', style: textStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('W/m²', style: textStyle)),
              ],
            ),
          ],
        ),
        
        pw.SizedBox(height: 20),
        
        // Datos del mes (TODOS los días)
        pw.Text('DATOS DIARIOS DEL MES', style: subHeaderStyle),
        pw.SizedBox(height: 10),
        
        // Tabla con todos los datos del mes (estilo mejorado con colores)
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey800, width: 1),
          columnWidths: {
            0: const pw.FlexColumnWidth(0.8),
            1: const pw.FlexColumnWidth(1.2),
            2: const pw.FlexColumnWidth(1.2),
            3: const pw.FlexColumnWidth(1.2),
            4: const pw.FlexColumnWidth(1),
            5: const pw.FlexColumnWidth(1),
            6: const pw.FlexColumnWidth(1),
            7: const pw.FlexColumnWidth(1),
          },
          children: [
            // Header de la tabla con colores verdes
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.green700),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'Día',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'RadTot\n(MJ/m²)',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'RadPro\n(W/m²)',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'RadMax\n(W/m²)',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'HR\n(%)',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'Tmax\n(°C)',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'Tmin\n(°C)',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'Tpro\n(°C)',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            ),
            // Datos de todos los días con colores alternados
            ...report.data.asMap().entries.map((entry) {
              final index = entry.key;
              final day = entry.value;
              final isEven = index % 2 == 0;
              
              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: isEven ? PdfColors.green50 : PdfColors.white,
                ),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      '${day.day}',
                      style: const pw.TextStyle(fontSize: 9),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      _safeFormatNumber(day.radTot / 1000, 2), // Convertir a MJ/m²
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      _safeFormatNumber(day.radPro, 1),
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      _safeFormatNumber(day.radMax, 1),
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      _safeFormatNumber(day.hr, 0),
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      _safeFormatNumber(day.tmax, 1),
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      _safeFormatNumber(day.tmin, 1),
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      _safeFormatNumber(day.tpro, 1),
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ],
              );
            }).toList(),
          ],
        ),

        pw.SizedBox(height: 20),
        
        // Footer mejorado igual al reporte diario
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(width: 1),
            ),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('Sistema IoT Agrícola - Universidad de Córdoba', 
                     style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              pw.Text('Reporte generado automáticamente - ${DateTime.now().toString().substring(0, 19)}', 
                     style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
            ],
          ),
        ),
    ];
  }

  // Helper method for safe number formatting
  static String _safeFormatNumber(double? value, int decimals) {
    if (value == null || value.isNaN || value.isInfinite) {
      return '--';
    }
    return value.toStringAsFixed(decimals);
  }

  static SimpleStats _calculateStats(MonthlyReport report) {
    if (report.data.isEmpty) {
      return SimpleStats(avgTemp: 0, avgHumidity: 0, totalRadiation: 0, maxTemp: 0, minTemp: 0);
    }

    double totalTemp = 0;
    double totalHumidity = 0;
    double totalRadiationSum = 0;
    double maxTemp = report.data.first.tmax;
    double minTemp = report.data.first.tmin;

    for (final day in report.data) {
      totalTemp += day.tpro;
      totalHumidity += day.hr;
      totalRadiationSum += day.radTot;
      if (day.tmax > maxTemp) maxTemp = day.tmax;
      if (day.tmin < minTemp) minTemp = day.tmin;
    }

    final count = report.data.length;
    return SimpleStats(
      avgTemp: totalTemp / count,
      avgHumidity: totalHumidity / count,
      totalRadiation: totalRadiationSum,
      maxTemp: maxTemp,
      minTemp: minTemp,
    );
  }
}

class SimpleStats {
  final double avgTemp;
  final double avgHumidity;
  final double totalRadiation;
  final double maxTemp;
  final double minTemp;

  SimpleStats({
    required this.avgTemp,
    required this.avgHumidity,
    required this.totalRadiation,
    required this.maxTemp,
    required this.minTemp,
  });
}