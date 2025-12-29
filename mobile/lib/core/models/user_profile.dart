import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String? fullName;
  final String? avatarUrl;
  final String? position;
  final String? bio;
  final DateTime createdAt;
  final int followersCount;
  final int followingCount;

  const UserProfile({
    required this.id,
    this.fullName,
    this.avatarUrl,
    this.position,
    this.bio,
    required this.createdAt,
    this.followersCount = 0,
    this.followingCount = 0,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      position: json['position'] as String?,
      bio: json['bio'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'position': position,
      'bio': bio,
      'created_at': createdAt.toIso8601String(),
      'followers_count': followersCount,
      'following_count': followingCount,
    };
  }

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? avatarUrl,
    String? position,
    String? bio,
    DateTime? createdAt,
    int? followersCount,
    int? followingCount,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      position: position ?? this.position,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
    );
  }

  @override
  List<Object?> get props => [id, fullName, avatarUrl, position, bio, createdAt, followersCount, followingCount];
}
