class DailyReportModel {
  final String deviceId;
  final String date;
  final List<HourlyDataModel> rows;
  final TemperatureStatsModel temperature;
  final HumidityStatsModel humidity;
  final RadiationStatsModel radiation;

  DailyReportModel({
    required this.deviceId,
    required this.date,
    required this.rows,
    required this.temperature,
    required this.humidity,
    required this.radiation,
  });

  factory DailyReportModel.fromJson(Map<String, dynamic> json) {
    return DailyReportModel(
      deviceId: json['deviceId'] ?? '',
      date: json['date'] ?? '',
      rows: (json['rows'] as List<dynamic>?)
          ?.map((row) => HourlyDataModel.fromJson(row))
          .toList() ?? [],
      temperature: TemperatureStatsModel.fromJson(json['temperature'] ?? {}),
      humidity: HumidityStatsModel.fromJson(json['humidity'] ?? {}),
      radiation: RadiationStatsModel.fromJson(json['radiation'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'date': date,
      'rows': rows.map((row) => row.toJson()).toList(),
      'temperature': temperature.toJson(),
      'humidity': humidity.toJson(),
      'radiation': radiation.toJson(),
    };
  }
}

class HourlyDataModel {
  final int hour;
  final double humidityAvg;
  final double solarRadiationAvg;
  final double temperatureAvg;
  final bool? isTmax;
  final bool? isTmin;

  HourlyDataModel({
    required this.hour,
    required this.humidityAvg,
    required this.solarRadiationAvg,
    required this.temperatureAvg,
    this.isTmax,
    this.isTmin,
  });

  factory HourlyDataModel.fromJson(Map<String, dynamic> json) {
    return HourlyDataModel(
      hour: json['hour'] ?? 0,
      humidityAvg: (json['humidity_avg'] ?? 0.0).toDouble(),
      solarRadiationAvg: (json['solar_radiation_avg'] ?? 0.0).toDouble(),
      temperatureAvg: (json['temperature_avg'] ?? 0.0).toDouble(),
      isTmax: json['isTmax'],
      isTmin: json['isTmin'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'humidity_avg': humidityAvg,
      'solar_radiation_avg': solarRadiationAvg,
      'temperature_avg': temperatureAvg,
      'isTmax': isTmax,
      'isTmin': isTmin,
    };
  }

  // Convierte hora UTC a hora local (GMT-5)
  int get localHour {
    int convertedHour = hour - 5;
    if (convertedHour < 0) {
      convertedHour += 24;
    }
    return convertedHour;
  }

  // Formatea la hora para mostrar (ej: "5 p.m.")
  String get formattedHour {
    int localH = localHour;
    if (localH == 0) return "12 a.m.";
    if (localH == 12) return "12 p.m.";
    if (localH < 12) return "$localH a.m.";
    return "${localH - 12} p.m.";
  }
}

class TemperatureStatsModel {
  final double tmax;
  final double tmin;
  final double tpro;

  TemperatureStatsModel({
    required this.tmax,
    required this.tmin,
    required this.tpro,
  });

  factory TemperatureStatsModel.fromJson(Map<String, dynamic> json) {
    return TemperatureStatsModel(
      tmax: (json['tmax'] ?? 0.0).toDouble(),
      tmin: (json['tmin'] ?? 0.0).toDouble(),
      tpro: (json['tpro'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tmax': tmax,
      'tmin': tmin,
      'tpro': tpro,
    };
  }
}

class HumidityStatsModel {
  final double hpro;

  HumidityStatsModel({
    required this.hpro,
  });

  factory HumidityStatsModel.fromJson(Map<String, dynamic> json) {
    return HumidityStatsModel(
      hpro: (json['hpro'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hpro': hpro,
    };
  }
}

class RadiationStatsModel {
  final double radTot;
  final double radPro;
  final double radMax;

  RadiationStatsModel({
    required this.radTot,
    required this.radPro,
    required this.radMax,
  });

  factory RadiationStatsModel.fromJson(Map<String, dynamic> json) {
    return RadiationStatsModel(
      radTot: (json['radTot'] ?? 0.0).toDouble(),
      radPro: (json['radPro'] ?? 0.0).toDouble(),
      radMax: (json['radMax'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'radTot': radTot,
      'radPro': radPro,
      'radMax': radMax,
    };
  }
}