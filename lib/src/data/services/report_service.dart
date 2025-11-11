
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/report_model.dart';
import '../../core/constants.dart';

class ReportService {
  Future<void> sendReport(Report report, String accessToken) async {
    final url = Uri.parse('${Constants.baseUrl}/api/reports');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(report.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to send report. Status code: ${response.statusCode}');
    }
  }
}
