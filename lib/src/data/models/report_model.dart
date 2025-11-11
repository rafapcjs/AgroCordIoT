
import 'package:flutter/foundation.dart' show immutable;

@immutable
class Report {
  final String deviceId;
  final String message;
  final DateTime timestamp;

  const Report({
    required this.deviceId,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
