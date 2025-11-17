class WeeklyReport {
  final List<SensorSummary> sensors;
  final List<DailyReport> daily;

  WeeklyReport({
    required this.sensors,
    required this.daily,
  });

  factory WeeklyReport.fromJson(Map<String, dynamic> json) {
    return WeeklyReport(
      sensors: (json['sensors'] as List<dynamic>?)
              ?.map((item) => SensorSummary.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      daily: (json['daily'] as List<dynamic>?)
              ?.map((item) => DailyReport.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SensorSummary {
  final String sensor;
  final double average;
  final String units;
  final int samples;

  SensorSummary({
    required this.sensor,
    required this.average,
    required this.units,
    required this.samples,
  });

  factory SensorSummary.fromJson(Map<String, dynamic> json) {
    return SensorSummary(
      sensor: json['sensorType'] as String? ?? json['sensor'] as String? ?? '',
      average: (json['average'] as num?)?.toDouble() ?? 0.0,
      units: json['units'] as String? ?? '',
      samples: json['samples'] as int? ?? 0,
    );
  }
}

class DailyReport {
  final String day;
  final String date;
  final List<SensorSummary> sensors;

  DailyReport({
    required this.day,
    required this.date,
    required this.sensors,
  });

  factory DailyReport.fromJson(Map<String, dynamic> json) {
    return DailyReport(
      day: json['weekdayName'] as String? ?? json['day'] as String? ?? '',
      date: json['date'] as String? ?? '',
      sensors: (json['sensors'] as List<dynamic>?)
              ?.map((item) => SensorSummary.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
