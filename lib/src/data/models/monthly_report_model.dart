class MonthlyReportData {
  final int day;
  final double radTot;
  final double radPro;
  final double radMax;
  final double hr;
  final double tmax;
  final double tmin;
  final double tpro;

  MonthlyReportData({
    required this.day,
    required this.radTot,
    required this.radPro,
    required this.radMax,
    required this.hr,
    required this.tmax,
    required this.tmin,
    required this.tpro,
  });

  factory MonthlyReportData.fromJson(Map<String, dynamic> json) {
    return MonthlyReportData(
      day: json['day'] ?? 0,
      radTot: (json['RadTot'] ?? 0).toDouble(),
      radPro: (json['RadPro'] ?? 0).toDouble(),
      radMax: (json['RadMax'] ?? 0).toDouble(),
      hr: (json['HR'] ?? 0).toDouble(),
      tmax: (json['Tmax'] ?? 0).toDouble(),
      tmin: (json['Tmin'] ?? 0).toDouble(),
      tpro: (json['Tpro'] ?? 0).toDouble(),
    );
  }
}

class MonthlyReport {
  final String deviceId;
  final int year;
  final int month;
  final List<MonthlyReportData> data;

  MonthlyReport({
    required this.deviceId,
    required this.year,
    required this.month,
    required this.data,
  });

  factory MonthlyReport.fromJson(Map<String, dynamic> json) {
    final dataList = json['days'] as List<dynamic>? ?? [];
    return MonthlyReport(
      deviceId: json['deviceId'] ?? '',
      year: json['year'] ?? 0,
      month: json['month'] ?? 0,
      data: dataList.map((item) => MonthlyReportData.fromJson(item)).toList(),
    );
  }
}