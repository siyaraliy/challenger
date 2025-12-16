import 'package:equatable/equatable.dart';

/// Represents a chat room
class ChatRoom extends Equatable {
  final String id;
  final String type; // 'direct' or 'team_group'
  final String? name;
  final String? avatarUrl;
  final String? teamId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final String role; // 'admin' or 'member'

  const ChatRoom({
    required this.id,
    required this.type,
    this.name,
    this.avatarUrl,
    this.teamId,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.role = 'member',
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] as String,
      type: json['type'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      teamId: json['teamId'] as String?,
      lastMessage: json['lastMessage'] as String?,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'] as String)
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      role: json['role'] as String? ?? 'member',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'avatarUrl': avatarUrl,
      'teamId': teamId,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'unreadCount': unreadCount,
      'role': role,
    };
  }

  bool get isDirect => type == 'direct';
  bool get isTeamGroup => type == 'team_group';
  bool get hasUnread => unreadCount > 0;
  bool get isAdmin => role == 'admin';

  /// Get display name for the chat room
  String get displayName => name ?? 'Bilinmeyen Sohbet';

  @override
  List<Object?> get props => [
        id,
        type,
        name,
        avatarUrl,
        teamId,
        lastMessage,
        lastMessageAt,
        unreadCount,
        role,
      ];
}
