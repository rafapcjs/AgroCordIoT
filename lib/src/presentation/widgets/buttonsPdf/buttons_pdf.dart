import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../data/models/monthly_report_model.dart';
import '../../../data/models/daily_report_model.dart';
import '../../../pdf/generate_pdf.dart';

class PdfDownloadButton extends StatefulWidget {
  final MonthlyReport? monthlyReport;
  final DailyReportModel? dailyReport;
  final IconData icon;
  final String text;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final VoidCallback? onSuccess;
  final VoidCallback? onError;

  const PdfDownloadButton({
    Key? key,
    this.monthlyReport,
    this.dailyReport,
    this.icon = Icons.download,
    this.text = 'Descargar PDF',
    this.backgroundColor,
    this.foregroundColor,
    this.onSuccess,
    this.onError,
  }) : super(key: key);

  @override
  State<PdfDownloadButton> createState() => _PdfDownloadButtonState();
}

class _PdfDownloadButtonState extends State<PdfDownloadButton> {
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isDownloading ? null : _handlePdfDownload,
      icon: _isDownloading 
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.foregroundColor ?? Colors.white,
                ),
              ),
            )
          : Icon(widget.icon),
      label: Text(_isDownloading ? 'Descargando...' : widget.text),
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.backgroundColor ?? Theme.of(context).primaryColor,
        foregroundColor: widget.foregroundColor ?? Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _handlePdfDownload() async {
    if (widget.monthlyReport == null && widget.dailyReport == null) {
      _showErrorMessage('No hay datos para generar el PDF');
      return;
    }

    // Validación adicional para reporte diario
    if (widget.dailyReport != null) {
      final dailyReport = widget.dailyReport!;
      if (dailyReport.deviceId.isEmpty || dailyReport.date.isEmpty) {
        _showErrorMessage('Datos del reporte incompletos. Verifique el dispositivo y la fecha.');
        return;
      }
      
      // Informar al usuario si no hay datos de sensores
      if (dailyReport.rows.isEmpty) {
        _showWarningMessage('No hay datos de sensores para esta fecha. El PDF se generará solo con estadísticas.');
      }
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      bool success = false;
      String reportType = '';
      
      if (widget.monthlyReport != null) {
        reportType = 'mensual';
        success = await PdfGenerator.downloadMonthlyReport(widget.monthlyReport!);
      } else if (widget.dailyReport != null) {
        reportType = 'diario';
        success = await PdfGenerator.downloadDailyReport(widget.dailyReport!);
      }

      if (success) {
        widget.onSuccess?.call();
        _showSuccessMessage('PDF $reportType generado y guardado exitosamente');
      } else {
        widget.onError?.call();
        _showErrorMessage('Error al generar el PDF $reportType. Verifique los permisos de almacenamiento.');
      }
      
    } catch (e) {
      widget.onError?.call();
      _showErrorMessage('Error inesperado: ${e.toString()}');
      debugPrint('Error en PDF download: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
  
  void _showWarningMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green[600],
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}

class SimplePdfButton extends StatelessWidget {
  final MonthlyReport? monthlyReport;
  final DailyReportModel? dailyReport;
  final String text;
  final IconData icon;
  final Color? color;

  const SimplePdfButton({
    Key? key,
    this.monthlyReport,
    this.dailyReport,
    this.text = 'PDF',
    this.icon = Icons.picture_as_pdf,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PdfDownloadButton(
      monthlyReport: monthlyReport,
      dailyReport: dailyReport,
      icon: icon,
      text: text,
      backgroundColor: color ?? Colors.green[700],
      foregroundColor: Colors.white,
    );
  }
}

class FloatingPdfButton extends StatelessWidget {
  final MonthlyReport? monthlyReport;
  final DailyReportModel? dailyReport;
  final String tooltipMessage;

  const FloatingPdfButton({
    Key? key,
    this.monthlyReport,
    this.dailyReport,
    this.tooltipMessage = 'Descargar PDF',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () async {
        if (monthlyReport != null) {
          await PdfGenerator.downloadMonthlyReport(monthlyReport!);
        } else if (dailyReport != null) {
          await PdfGenerator.downloadDailyReport(dailyReport!);
        }
      },
      tooltip: tooltipMessage,
      backgroundColor: Colors.green[700],
      child: const Icon(Icons.picture_as_pdf, color: Colors.white),
    );
  }
}