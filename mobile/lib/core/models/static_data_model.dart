import 'package:hive/hive.dart';

part 'static_data_model.g.dart';

@HiveType(typeId: 0)
class Position extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String abbreviation;

  Position({
    required this.id,
    required this.name,
    required this.abbreviation,
  });

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      id: json['id'] as String,
      name: json['name'] as String,
      abbreviation: json['abbreviation'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'abbreviation': abbreviation,
    };
  }
}

@HiveType(typeId: 1)
class MatchType extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int playerCount;

  MatchType({
    required this.id,
    required this.name,
    required this.playerCount,
  });

  factory MatchType.fromJson(Map<String, dynamic> json) {
    return MatchType(
      id: json['id'] as String,
      name: json['name'] as String,
      playerCount: json['playerCount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'playerCount': playerCount,
    };
  }
}

@HiveType(typeId: 2)
class ReportReason extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String severity;

  ReportReason({
    required this.id,
    required this.name,
    required this.severity,
  });

  factory ReportReason.fromJson(Map<String, dynamic> json) {
    return ReportReason(
      id: json['id'] as String,
      name: json['name'] as String,
      severity: json['severity'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'severity': severity,
    };
  }
}
