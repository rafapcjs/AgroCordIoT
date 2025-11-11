import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../models/daily_report_model.dart';

class DailyReportService {
  static const String _endpoint = '/api/reports/daily';

  static Future<DailyReportModel?> getDailyReport({
    required String accessToken,
    required String deviceId,
    required DateTime date,
  }) async {
    try {
      final formattedDate = _formatDate(date);
      final url = Uri.parse(
        '${Constants.baseUrl}$_endpoint?deviceId=$deviceId&date=$formattedDate'
      );

      print('🔍 DAILY REPORT DEBUG: URL: $url');
      print('🔍 DAILY REPORT DEBUG: deviceId: $deviceId, date: $formattedDate');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      print('🔍 DAILY REPORT DEBUG: Status Code: ${response.statusCode}');
      print('🔍 DAILY REPORT DEBUG: Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        print('🔍 DAILY REPORT DEBUG: Parsed JSON keys: ${jsonData.keys}');
        
        // Validar estructura de respuesta
        if (!_isValidResponse(jsonData)) {
          print('❌ DAILY REPORT ERROR: Invalid response structure');
          print('❌ Response data: $jsonData');
          return null;
        }
        
        if (jsonData.containsKey('rows')) {
          print('🔍 DAILY REPORT DEBUG: Rows found - count: ${jsonData['rows']?.length ?? 0}');
          if (jsonData['rows'] is List && jsonData['rows'].isNotEmpty) {
            print('🔍 DAILY REPORT DEBUG: First row example: ${jsonData['rows'][0]}');
            
            // Validar estructura de las filas
            final firstRow = jsonData['rows'][0] as Map<String, dynamic>;
            if (!_isValidRowStructure(firstRow)) {
              print('⚠️ DAILY REPORT WARNING: Row structure might be invalid');
              print('⚠️ First row: $firstRow');
            }
          }
        } else {
          print('🔍 DAILY REPORT DEBUG: No rows key found in response - creating empty rows');
          jsonData['rows'] = [];
        }
        
        try {
          final report = DailyReportModel.fromJson(jsonData);
          print('🔍 DAILY REPORT DEBUG: Created report successfully');
          print('  - Device ID: ${report.deviceId}');
          print('  - Date: ${report.date}');
          print('  - Hourly entries: ${report.rows.length}');
          print('  - Temperature stats: max=${report.temperature.tmax}, min=${report.temperature.tmin}, avg=${report.temperature.tpro}');
          print('  - Humidity avg: ${report.humidity.hpro}');
          print('  - Radiation: total=${report.radiation.radTot}, max=${report.radiation.radMax}');
          
          return report;
        } catch (parseError) {
          print('❌ DAILY REPORT PARSE ERROR: $parseError');
          print('❌ JSON Data: $jsonData');
          return null;
        }
      } else {
        print('❌ Error al obtener reporte diario: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error en getDailyReport: $e');
      return null;
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  // Validar estructura básica de respuesta
  static bool _isValidResponse(Map<String, dynamic> json) {
    // Verificar que tenga las claves principales
    final requiredKeys = ['deviceId', 'date'];
    for (final key in requiredKeys) {
      if (!json.containsKey(key) || json[key] == null) {
        print('❌ Missing or null required key: $key');
        return false;
      }
    }
    
    // Verificar que las estadísticas existan (aunque sean vacías)
    final statKeys = ['temperature', 'humidity', 'radiation'];
    for (final key in statKeys) {
      if (json.containsKey(key) && json[key] != null && json[key] is! Map) {
        print('❌ Invalid structure for stat key: $key - expected Map, got ${json[key].runtimeType}');
        return false;
      }
    }
    
    return true;
  }
  
  // Validar estructura de una fila de datos
  static bool _isValidRowStructure(Map<String, dynamic> row) {
    final requiredFields = ['hour', 'temperature_avg', 'humidity_avg', 'solar_radiation_avg'];
    
    for (final field in requiredFields) {
      if (!row.containsKey(field)) {
        print('⚠️ Missing field in row: $field');
        return false;
      }
    }
    
    // Verificar que hour sea numérico
    if (row['hour'] is! num) {
      print('⚠️ Hour field is not numeric: ${row['hour']}');
      return false;
    }
    
    return true;
  }
}