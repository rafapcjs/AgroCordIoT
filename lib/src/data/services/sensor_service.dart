import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor_data_model.dart';
import '../../core/constants.dart';

class SensorService {
  /// Obtiene los datos más recientes de un dispositivo específico
  Future<List<SensorData>> getLatestSensorData(String deviceId, String accessToken) async {
    try {
      final url = Uri.parse('${Constants.baseUrl}/api/sensor-data/latest?deviceId=$deviceId');

      print('🔍 SENSOR SERVICE DEBUG: Fetching data from: $url');

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
      );

      print('🔍 SENSOR SERVICE DEBUG: Status Code: ${response.statusCode}');
      print('🔍 SENSOR SERVICE DEBUG: Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final sensorDataList = jsonList
            .map((json) => SensorData.fromJson(json))
            .toList();

        print('✅ SENSOR SERVICE DEBUG: Successfully parsed ${sensorDataList.length} sensor readings');
        return sensorDataList;
      } else if (response.statusCode == 404) {
        print('⚠️ SENSOR SERVICE DEBUG: No data found for device $deviceId');
        return [];
      } else {
        throw Exception('Failed to load sensor data: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ SENSOR SERVICE ERROR: $e');
      rethrow;
    }
  }

  /// Obtiene los datos de múltiples dispositivos
  Future<Map<String, List<SensorData>>> getMultipleDevicesData(
    List<String> deviceIds,
    String accessToken,
  ) async {
    final Map<String, List<SensorData>> devicesData = {};

    for (final deviceId in deviceIds) {
      try {
        final data = await getLatestSensorData(deviceId, accessToken);
        devicesData[deviceId] = data;
      } catch (e) {
        print('❌ Error fetching data for device $deviceId: $e');
        devicesData[deviceId] = [];
      }
    }

    return devicesData;
  }

  /// Obtiene un sensor específico de un dispositivo
  SensorData? getSensorByType(List<SensorData> sensorList, String sensorType) {
    try {
      return sensorList.firstWhere(
        (sensor) => sensor.sensorType == sensorType,
      );
    } catch (e) {
      return null;
    }
  }
}
