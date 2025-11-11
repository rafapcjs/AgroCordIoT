import 'threshold_model.dart';

class PlantModel {
  final String id;
  final String name;
  final PlantThresholds thresholds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  PlantModel({
    required this.id,
    required this.name,
    required this.thresholds,
    required this.createdAt,
    required this.updatedAt,
    this.version = 0,
  });

  factory PlantModel.fromJson(Map<String, dynamic> json) {
    return PlantModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      thresholds: PlantThresholds.fromJson(json['thresholds'] ?? {}),
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      version: json['__v'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'thresholds': thresholds.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      '__v': version,
    };
  }

  PlantModel copyWith({
    String? id,
    String? name,
    PlantThresholds? thresholds,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
  }) {
    return PlantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      thresholds: thresholds ?? this.thresholds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }
}

class CreatePlantModel {
  final String name;
  final PlantThresholds thresholds;

  CreatePlantModel({required this.name, required this.thresholds});

  Map<String, dynamic> toJson() {
    return {'name': name, 'thresholds': thresholds.toJson()};
  }
}

class UpdatePlantModel {
  final String name;
  final PlantThresholds thresholds;

  UpdatePlantModel({required this.name, required this.thresholds});

  Map<String, dynamic> toJson() {
    return {'name': name, 'thresholds': thresholds.toJson()};
  }
}
