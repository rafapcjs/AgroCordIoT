class SensorThreshold {
  final double? min;
  final double? max;

  SensorThreshold({this.min, this.max});

  factory SensorThreshold.fromJson(Map<String, dynamic> json) {
    return SensorThreshold(
      min: json['min']?.toDouble(),
      max: json['max']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {if (min != null) 'min': min, if (max != null) 'max': max};
  }
}

class PlantThresholds {
  final SensorThreshold temperature;
  final SensorThreshold humidity;
  final SensorThreshold soilHumidity;
  final SensorThreshold solarRadiation;

  PlantThresholds({
    required this.temperature,
    required this.humidity,
    required this.soilHumidity,
    required this.solarRadiation,
  });

  factory PlantThresholds.fromJson(Map<String, dynamic> json) {
    return PlantThresholds(
      temperature: SensorThreshold.fromJson(json['temperature'] ?? {}),
      humidity: SensorThreshold.fromJson(json['humidity'] ?? {}),
      soilHumidity: SensorThreshold.fromJson(json['soil_humidity'] ?? {}),
      solarRadiation: SensorThreshold.fromJson(json['solar_radiation'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature.toJson(),
      'humidity': humidity.toJson(),
      'soil_humidity': soilHumidity.toJson(),
      'solar_radiation': solarRadiation.toJson(),
    };
  }
}
