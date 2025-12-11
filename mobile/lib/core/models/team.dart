import 'package:equatable/equatable.dart';

class Team extends Equatable {
  final String id;
  final String name;
  final String captainId;
  final String? logoUrl;
  final DateTime createdAt;

  const Team({
    required this.id,
    required this.name,
    required this.captainId,
    this.logoUrl,
    required this.createdAt,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as String,
      name: json['name'] as String,
      captainId: json['captain_id'] as String,
      logoUrl: json['logo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'captain_id': captainId,
      'logo_url': logoUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Team copyWith({
    String? id,
    String? name,
    String? captainId,
    String? logoUrl,
    DateTime? createdAt,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      captainId: captainId ?? this.captainId,
      logoUrl: logoUrl ?? this.logoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, captainId, logoUrl, createdAt];
}
