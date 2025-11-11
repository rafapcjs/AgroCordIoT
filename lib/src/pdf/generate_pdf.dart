import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../data/models/monthly_report_model.dart';
import '../data/models/daily_report_model.dart';
import 'reportDiary/template_diary.dart';
import '../services/pdf_service.dart';

class PdfGenerator {
  /// Descarga y comparte un reporte mensual 
  static Future<bool> downloadMonthlyReport(MonthlyReport report) async {
    try {
      debugPrint('Iniciando descarga de reporte mensual...');
      
      // Intentar compartir el PDF (esto lo genera internamente)
      final success = await MonthlyReportTemplate.shareMonthlyReport(report);
      if (success) {
        debugPrint('Reporte mensual compartido exitosamente');
        return true;
      }
      
      // Si falla compartir, intenta abrir directamente
      debugPrint('No se pudo compartir, intentando abrir directamente...');
      final openSuccess = await MonthlyReportTemplate.openMonthlyReport(report);
      if (openSuccess) {
        debugPrint('Reporte mensual abierto exitosamente');
        return true;
      }
      
      debugPrint('Error: No se pudo compartir ni abrir el PDF mensual');
      return false;
      
    } catch (e, stackTrace) {
      debugPrint('Error en descarga de reporte mensual: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Descarga y comparte un reporte diario
  static Future<bool> downloadDailyReport(DailyReportModel report) async {
    try {
      final success = await PdfService.shareReportPdf(report);
      if (success) {
        debugPrint('Reporte diario compartido exitosamente');
        return true;
      }
      // Si falla compartir, intenta abrir directamente
      final openSuccess = await PdfService.openReportPdf(report);
      return openSuccess;
    } catch (e) {
      debugPrint('Error en descarga de reporte diario: $e');
      return false;
    }
  }

  /// Muestra mensaje de éxito al descargar
  static Future<void> _showDownloadSuccess(File file) async {
    debugPrint('PDF guardado exitosamente en: ${file.path}');
  }

  /// Muestra diálogo de error
  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Muestra diálogo de éxito
  static void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Éxito'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}