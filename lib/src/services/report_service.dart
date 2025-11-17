import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/report.dart';

class ReportService {
  static const String baseUrl =
      'http://ec2-98-86-100-220.compute-1.amazonaws.com:3000';

  Future<WeeklyReport> fetchWeeklyReport(String deviceId, String accessToken) async {
    try {
      final url = Uri.parse('$baseUrl/api/reports/weekly?deviceId=$deviceId&days=7');
      
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Error al cargar el reporte: ${response.statusCode} - ${response.body}');
      }

      final Map<String, dynamic> jsonData = json.decode(response.body);
      
      return WeeklyReport.fromJson(jsonData);
    } catch (e) {
      throw Exception('Error al obtener el reporte semanal: $e');
    }
  }
}
