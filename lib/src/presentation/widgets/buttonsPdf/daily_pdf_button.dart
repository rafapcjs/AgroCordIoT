import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../data/models/daily_report_model.dart';
import '../../../services/daily_pdf_service.dart';

class DailyPdfButton extends StatefulWidget {
  final DailyReportModel? dailyReport;
  final String deviceLabel;
  final String text;
  final IconData icon;
  final Color? color;

  const DailyPdfButton({
    super.key,
    required this.dailyReport,
    required this.deviceLabel,
    this.text = 'Descargar PDF',
    this.icon = Icons.picture_as_pdf,
    this.color,
  });

  @override
  State<DailyPdfButton> createState() => _DailyPdfButtonState();
}

class _DailyPdfButtonState extends State<DailyPdfButton> {
  bool _isGenerating = false;

  Future<void> _generateDailyPdf() async {
    if (widget.dailyReport == null || _isGenerating) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      // Mostrar indicador de carga
      if (mounted) {
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
                      'Generando PDF de reporte diario...',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Dispositivo: ${widget.deviceLabel}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }

      // Generar el PDF usando el servicio dedicado
      final file = await DailyPdfService.generateDailyReportPdf(
        widget.dailyReport!,
        deviceLabel: widget.deviceLabel,
      );

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
                        'PDF generado exitosamente',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Dispositivo: ${widget.deviceLabel}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Guardado en: ${file.path}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            action: SnackBarAction(
              label: 'Abrir',
              textColor: Colors.white,
              onPressed: () async {
                final success = await DailyPdfService.generateAndOpenDailyPdf(
                  widget.dailyReport!,
                  deviceLabel: widget.deviceLabel,
                );
                if (!success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No se pudo abrir el archivo'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              },
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
      debugPrint('Error generando PDF diario: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.dailyReport != null && !_isGenerating;
    
    return Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton.icon(
        onPressed: isEnabled ? _generateDailyPdf : null,
        icon: _isGenerating
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isEnabled ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              )
            : Icon(
                widget.icon,
                color: isEnabled ? Colors.white : AppTheme.textSecondary,
                size: 24,
              ),
        label: Text(
          _isGenerating ? 'Generando...' : widget.text,
          style: TextStyle(
            color: isEnabled ? Colors.white : AppTheme.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled 
              ? widget.color ?? Colors.green[700] 
              : AppTheme.surfaceDark,
          foregroundColor: isEnabled ? Colors.white : AppTheme.textSecondary,
          elevation: isEnabled ? 4 : 0,
          shadowColor: isEnabled 
              ? (widget.color ?? Colors.red[700])?.withValues(alpha: 0.3) 
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppTheme.surfaceDark;
            }
            if (states.contains(WidgetState.pressed)) {
              return (widget.color ?? Colors.green[700])!.withValues(alpha: 0.8);
            }
            if (states.contains(WidgetState.hovered)) {
              return (widget.color ?? Colors.green[700])!.withValues(alpha: 0.9);
            }
            return widget.color ?? Colors.green[700]!;
          }),
        ),
      ),
    );
  }
}

// Widget adicional para opciones múltiples
class DailyPdfOptionsButton extends StatelessWidget {
  final DailyReportModel? dailyReport;
  final String deviceLabel;

  const DailyPdfOptionsButton({
    super.key,
    required this.dailyReport,
    required this.deviceLabel,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      enabled: dailyReport != null,
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.picture_as_pdf,
          color: Colors.white,
          size: 20,
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'download',
          child: Row(
            children: [
              Icon(Icons.download, color: AppTheme.textPrimary, size: 20),
              const SizedBox(width: 12),
              Text(
                'Descargar PDF',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share, color: AppTheme.textPrimary, size: 20),
              const SizedBox(width: 12),
              Text(
                'Compartir PDF',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'open',
          child: Row(
            children: [
              Icon(Icons.open_in_new, color: AppTheme.textPrimary, size: 20),
              const SizedBox(width: 12),
              Text(
                'Abrir PDF',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        if (dailyReport == null) return;

        switch (value) {
          case 'download':
            final file = await DailyPdfService.generateDailyReportPdf(
              dailyReport!,
              deviceLabel: deviceLabel,
            );
            if (file != null && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('PDF guardado en: ${file.path}'),
                  backgroundColor: AppTheme.success,
                ),
              );
            }
            break;
          case 'share':
            final success = await DailyPdfService.generateAndShareDailyPdf(
              dailyReport!,
              deviceLabel: deviceLabel,
            );
            if (!success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error al compartir el PDF'),
                  backgroundColor: AppTheme.error,
                ),
              );
            }
            break;
          case 'open':
            final success = await DailyPdfService.generateAndOpenDailyPdf(
              dailyReport!,
              deviceLabel: deviceLabel,
            );
            if (!success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error al abrir el PDF'),
                  backgroundColor: AppTheme.error,
                ),
              );
            }
            break;
        }
      },
    );
  }
}