class SensorData {
  final String deviceId;
  final String sensorType;
  final double value;
  final String unit;
  final DateTime timestamp;

  SensorData({
    required this.deviceId,
    required this.sensorType,
    required this.value,
    required this.unit,
    required this.timestamp,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      deviceId: json['deviceId'] ?? '',
      sensorType: json['sensorType'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'sensorType': sensorType,
      'value': value,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Método auxiliar para verificar si el dato es válido
  bool get hasData => value != 0;

  // Método auxiliar para obtener el nombre legible del sensor
  String get displayName {
    switch (sensorType) {
      case 'temperature':
        return 'Temperatura';
      case 'humidity':
        return 'Humedad';
      case 'soil_humidity':
        return 'Humedad del suelo';
      case 'solar_radiation':
        return 'Radiación solar';
      default:
        return sensorType;
    }
  }
}
