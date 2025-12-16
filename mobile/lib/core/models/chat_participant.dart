import 'package:equatable/equatable.dart';

/// Represents a chat participant
class ChatParticipant extends Equatable {
  final String id;
  final String participantType; // 'user' or 'team'
  final String participantId;
  final String status; // 'pending', 'approved', 'rejected'
  final String role; // 'admin', 'member'
  final String? name;
  final String? avatarUrl;
  final DateTime? joinedAt;

  const ChatParticipant({
    required this.id,
    required this.participantType,
    required this.participantId,
    required this.status,
    required this.role,
    this.name,
    this.avatarUrl,
    this.joinedAt,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      id: json['id'] as String,
      participantType: json['participantType'] as String? ?? 'user',
      participantId: json['participantId'] as String,
      status: json['status'] as String? ?? 'approved',
      role: json['role'] as String? ?? 'member',
      name: json['name'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      joinedAt: json['joinedAt'] != null 
          ? DateTime.parse(json['joinedAt'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participantType': participantType,
      'participantId': participantId,
      'status': status,
      'role': role,
      'name': name,
      'avatarUrl': avatarUrl,
      'joinedAt': joinedAt?.toIso8601String(),
    };
  }

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isAdmin => role == 'admin';

  @override
  List<Object?> get props => [
        id,
        participantType,
        participantId,
        status,
        role,
        name,
        avatarUrl,
        joinedAt,
      ];
}
