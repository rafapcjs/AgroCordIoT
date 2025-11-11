import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class PdfFonts {
  // Usar estilos básicos sin fuentes específicas para mejor compatibilidad
  static pw.TextStyle titleStyle({
    double fontSize = 24,
    PdfColor? color,
  }) {
    return pw.TextStyle(
      fontSize: fontSize,
      fontWeight: pw.FontWeight.bold,
      color: color ?? PdfColors.black,
    );
  }

  static pw.TextStyle headingStyle({
    double fontSize = 18,
    PdfColor? color,
  }) {
    return pw.TextStyle(
      fontSize: fontSize,
      fontWeight: pw.FontWeight.bold,
      color: color ?? PdfColors.black,
    );
  }

  static pw.TextStyle bodyStyle({
    double fontSize = 12,
    PdfColor? color,
    pw.FontWeight? fontWeight,
  }) {
    return pw.TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight ?? pw.FontWeight.normal,
      color: color ?? PdfColors.black,
    );
  }

  static pw.TextStyle smallStyle({
    double fontSize = 10,
    PdfColor? color,
  }) {
    return pw.TextStyle(
      fontSize: fontSize,
      color: color ?? PdfColors.grey600,
    );
  }

  // Texto seguro que reemplaza caracteres problemáticos
  static String safeText(String text) {
    return text
        .replaceAll('ñ', 'n')
        .replaceAll('Ñ', 'N')
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('Á', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ú', 'U')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'U')
        .replaceAll('°', 'deg');
  }
}