import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../../core/exceptions.dart';
import '../models/monthly_report_model.dart';

class MonthlyReportService {
  static const Duration _timeout = Duration(seconds: 30);

  Future<List<MonthlyReport>> getMonthlyReportsPaginated({
    required String deviceId,
    required int year,
    required int month,
    required String accessToken,
    int page = 1,
    int limit = 6,
  }) async {
    try {
      final url = Uri.parse(
          '${Constants.baseUrl}/api/reports/monthly/paginated?deviceId=$deviceId&year=$year&month=$month&page=$page&limit=$limit');
      
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
      ).timeout(_timeout);

      return _handlePaginatedReportsResponse(response);
    } on SocketException {
      throw NetworkException('Sin conexión a internet. Verifica tu red.');
    } on HttpException {
      throw NetworkException('Error de conexión al servidor.');
    } on FormatException {
      throw NetworkException('Respuesta inválida del servidor.');
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw UnknownException('Error inesperado: ${e.toString()}');
    }
  }

  List<MonthlyReport> _handlePaginatedReportsResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
        try {
          final jsonData = json.decode(response.body);
          if (jsonData is List) {
            return jsonData.map((item) => MonthlyReport.fromJson(item)).toList();
          } else if (jsonData is Map && jsonData.containsKey('data')) {
            final data = jsonData['data'] as List;
            return data.map((item) => MonthlyReport.fromJson(item)).toList();
          }
          throw ServerException('Formato de respuesta inesperado.');
        } catch (e) {
          throw ServerException('Respuesta del servidor malformada.');
        }
      case 401:
        throw AuthenticationException('Token de acceso inválido.');
      case 403:
        throw AuthorizationException('No tienes permisos para acceder.');
      case 404:
        throw NetworkException('No se encontraron datos para el período solicitado.');
      case 500:
        throw ServerException('Error interno del servidor.');
      case 502:
        throw NetworkException('Servidor no disponible.');
      case 503:
        throw NetworkException('Servicio temporalmente no disponible.');
      default:
        throw NetworkException(
          'Error del servidor (${response.statusCode})',
          statusCode: response.statusCode,
        );
    }
  }
  
  /// Convierte fechas UTC a GMT-5 (hora local de Colombia)
  DateTime _convertToLocalTime(DateTime utcTime) {
    return utcTime.subtract(const Duration(hours: 5));
  }

  /// Convierte fechas locales a UTC para envío al servidor
  DateTime _convertToUtc(DateTime localTime) {
    return localTime.add(const Duration(hours: 5));
  }

  Future<MonthlyReport> getMonthlyReport({
    required String deviceId,
    required int year,
    required int month,
    required String accessToken,
    int page = 1,
    int limit = 6,
  }) async {
    try {
      final url = Uri.parse(
          '${Constants.baseUrl}/api/reports/monthly?deviceId=$deviceId&year=$year&month=$month&page=$page&limit=$limit');
      
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
      ).timeout(_timeout);

      return _handleMonthlyReportResponse(response, deviceId, year, month);
    } on SocketException {
      throw NetworkException('Sin conexión a internet. Verifica tu red.');
    } on HttpException {
      throw NetworkException('Error de conexión al servidor.');
    } on FormatException {
      throw NetworkException('Respuesta inválida del servidor.');
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw UnknownException('Error inesperado: ${e.toString()}');
    }
  }

  MonthlyReport _handleMonthlyReportResponse(
      http.Response response, String deviceId, int year, int month) {
    switch (response.statusCode) {
      case 200:
        try {
          final jsonData = json.decode(response.body);
          return MonthlyReport.fromJson(jsonData);
        } catch (e) {
          throw ServerException('Respuesta del servidor malformada.');
        }
      case 401:
        throw AuthenticationException('Token de acceso inválido.');
      case 403:
        throw AuthorizationException('No tienes permisos para acceder.');
      case 404:
        throw NetworkException('No se encontraron datos para el período solicitado.');
      case 500:
        throw ServerException('Error interno del servidor.');
      case 502:
        throw NetworkException('Servidor no disponible.');
      case 503:
        throw NetworkException('Servicio temporalmente no disponible.');
      default:
        throw NetworkException(
          'Error del servidor (${response.statusCode})',
          statusCode: response.statusCode,
        );
    }
  }
}