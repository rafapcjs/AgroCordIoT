import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import '../data/models/daily_report_model.dart';

class PdfService {
  static Future<File?> generateReportPdf(DailyReportModel report) async {
    try {
      // Validar datos del reporte
      if (report.deviceId.isEmpty || report.date.isEmpty) {
        debugPrint('Error: Datos del reporte inválidos - deviceId: ${report.deviceId}, date: ${report.date}');
        return null;
      }

      final pdf = pw.Document();

      // Crear página con manejo mejorado de errores
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return _buildSimpleDailyReport(report);
          },
        ),
      );

      // Crear nombre de archivo seguro
      final sanitizedDate = report.date.replaceAll(RegExp(r'[^\w\-_]'), '_');
      final sanitizedDeviceId = report.deviceId.replaceAll(RegExp(r'[^\w\-_]'), '_');
      final fileName = 'reporte_diario_${sanitizedDeviceId}_${sanitizedDate}.pdf';
      
      debugPrint('Generando PDF: $fileName');
      
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
            debugPrint('PDF generado exitosamente: ${file.path} (${fileSize} bytes)');
            return file;
          } else {
            debugPrint('Error: El archivo PDF no se creó correctamente');
            return null;
          }
        } catch (e) {
          debugPrint('Error guardando en directorio de documentos: $e');
          
          // Fallback: intentar directorio temporal
          try {
            final tempDir = Directory.systemTemp;
            final file = File('${tempDir.path}/$fileName');
            final bytes = await pdf.save();
            await file.writeAsBytes(bytes);
            debugPrint('PDF guardado en directorio temporal: ${file.path}');
            return file;
          } catch (tempError) {
            debugPrint('Error guardando en directorio temporal: $tempError');
            return null;
          }
        }
      }

    } catch (e) {
      debugPrint('Error general generando PDF diario: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // Método para compartir el PDF una vez generado
  static Future<bool> shareReportPdf(DailyReportModel report) async {
    try {
      final file = await generateReportPdf(report);
      if (file == null) return false;
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Reporte diario IoT - ${report.date}',
        subject: 'Reporte Diario - Dispositivo ${report.deviceId}',
      );
      return true;
    } catch (e) {
      debugPrint('Error compartiendo PDF: $e');
      return false;
    }
  }

  // Método para abrir el PDF directamente
  static Future<bool> openReportPdf(DailyReportModel report) async {
    try {
      final file = await generateReportPdf(report);
      if (file == null) return false;
      
      final result = await OpenFile.open(file.path);
      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('Error abriendo PDF: $e');
      return false;
    }
  }

  static pw.Widget _buildSimpleDailyReport(DailyReportModel report) {
    const textStyle = pw.TextStyle(fontSize: 12);
    const headerStyle = pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold);
    const subHeaderStyle = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold);
    
    // Filtrar datos válidos
    final validRows = report.rows.where((hourData) => 
      hourData.temperatureAvg > 0 || hourData.humidityAvg > 0 || hourData.solarRadiationAvg > 0
    ).toList();
    
    // Ordenar por hora
    validRows.sort((a, b) => a.hour.compareTo(b.hour));
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header mejorado
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
              pw.Text('REPORTE DIARIO IoT', style: headerStyle),
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
        pw.Text('Dispositivo: ${report.deviceId}', style: textStyle),
        pw.Text('Fecha: ${report.date}', style: textStyle),
        pw.Text('Generado: ${DateTime.now().toString().substring(0, 16)}', style: textStyle),
        pw.Text('Total de lecturas válidas: ${validRows.length}', style: textStyle),
        
        pw.SizedBox(height: 20),
        
        // Estadísticas mejoradas
        pw.Text('RESUMEN ESTADÍSTICO', style: subHeaderStyle),
        pw.SizedBox(height: 10),
        
        // Crear tabla de estadísticas
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
                  child: pw.Text('Parámetro', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Valor', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Unidad', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Temperatura Promedio', style: textStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${_safeFormatNumber(report.temperature.tpro, 1)}', style: textStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('°C', style: textStyle)),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Temperatura Máxima', style: textStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${_safeFormatNumber(report.temperature.tmax, 1)}', style: textStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('°C', style: textStyle)),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Temperatura Mínima', style: textStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${_safeFormatNumber(report.temperature.tmin, 1)}', style: textStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('°C', style: textStyle)),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Humedad Promedio', style: textStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${_safeFormatNumber(report.humidity.hpro, 1)}', style: textStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('%', style: textStyle)),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Radiación Total', style: textStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${_safeFormatNumber(report.radiation.radTot, 0)}', style: textStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('W/m²', style: textStyle)),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Radiación Promedio', style: textStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${_safeFormatNumber(report.radiation.radPro, 0)}', style: textStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('W/m²', style: textStyle)),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Radiación Máxima', style: textStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${_safeFormatNumber(report.radiation.radMax, 0)}', style: textStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('W/m²', style: textStyle)),
              ],
            ),
          ],
        ),
        
        pw.SizedBox(height: 20),
        
        // Datos por hora
        if (validRows.isNotEmpty) ...[
          pw.Text('DATOS HORARIOS', style: subHeaderStyle),
          pw.SizedBox(height: 10),
          
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(1.2),
              2: const pw.FlexColumnWidth(1.2),
              3: const pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Hora', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Temp. (°C)', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Hum. (%)', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Rad. (W/m²)', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
              ...validRows.take(20).map((hourData) => pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(_formatHourLabel(hourData.hour), style: textStyle),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('${_safeFormatNumber(hourData.temperatureAvg, 1)}', style: textStyle),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('${_safeFormatNumber(hourData.humidityAvg, 1)}', style: textStyle),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('${_safeFormatNumber(hourData.solarRadiationAvg, 0)}', style: textStyle),
                  ),
                ],
              )).toList(),
            ],
          ),
          
          if (validRows.length > 20)
            pw.Text('\nNota: Se muestran solo las primeras 20 lecturas. Total de lecturas: ${validRows.length}', 
                   style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        ] else ...[
          pw.Text('DATOS HORARIOS', style: subHeaderStyle),
          pw.SizedBox(height: 10),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey),
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Text(
              'No se encontraron mediciones válidas para este día.\nVerifique la conectividad del dispositivo o intente con otra fecha.',
              style: textStyle,
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],

        pw.Spacer(),
        
        // Footer
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
      ],
    );
  }
  
  // Helper method for safe number formatting
  static String _safeFormatNumber(double? value, int decimals) {
    if (value == null || value.isNaN || value.isInfinite) {
      return '--';
    }
    return value.toStringAsFixed(decimals);
  }
  
  // Helper method for formatting hour labels (12-hour format with am/pm)
  static String _formatHourLabel(int hour) {
    if (hour == 0) return '12 am';
    if (hour < 12) return '$hour am';
    if (hour == 12) return '12 pm';
    return '${hour - 12} pm';
  }
}