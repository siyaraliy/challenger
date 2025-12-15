/// Team Invitation model
class TeamInvitation {
  final String id;
  final String teamId;
  final String inviteCode;
  final String? invitedUserId;
  final InvitationStatus status;
  final DateTime expiresAt;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final InvitationTeam? team;

  TeamInvitation({
    required this.id,
    required this.teamId,
    required this.inviteCode,
    this.invitedUserId,
    required this.status,
    required this.expiresAt,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.team,
  });

  factory TeamInvitation.fromJson(Map<String, dynamic> json) {
    return TeamInvitation(
      id: json['id'] as String,
      teamId: json['team_id'] as String,
      inviteCode: json['invite_code'] as String,
      invitedUserId: json['invited_user_id'] as String?,
      status: InvitationStatus.fromString(json['status'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      team: json['team'] != null 
          ? InvitationTeam.fromJson(json['team'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team_id': teamId,
      'invite_code': inviteCode,
      'invited_user_id': invitedUserId,
      'status': status.value,
      'expires_at': expiresAt.toIso8601String(),
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isPending => status == InvitationStatus.pending && !isExpired;

  String get remainingTime {
    final diff = expiresAt.difference(DateTime.now());
    if (diff.isNegative) return 'Süresi doldu';
    if (diff.inDays > 0) return '${diff.inDays} gün kaldı';
    if (diff.inHours > 0) return '${diff.inHours} saat kaldı';
    return '${diff.inMinutes} dakika kaldı';
  }
}

/// Invitation status enum
enum InvitationStatus {
  pending('pending'),
  accepted('accepted'),
  rejected('rejected'),
  expired('expired');

  const InvitationStatus(this.value);
  final String value;

  static InvitationStatus fromString(String value) {
    return InvitationStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => InvitationStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case InvitationStatus.pending:
        return 'Bekliyor';
      case InvitationStatus.accepted:
        return 'Kabul Edildi';
      case InvitationStatus.rejected:
        return 'Reddedildi';
      case InvitationStatus.expired:
        return 'Süresi Doldu';
    }
  }
}

/// Simplified team info for invitation
class InvitationTeam {
  final String id;
  final String name;
  final String? logoUrl;

  InvitationTeam({
    required this.id,
    required this.name,
    this.logoUrl,
  });

  factory InvitationTeam.fromJson(Map<String, dynamic> json) {
    return InvitationTeam(
      id: json['id'] as String,
      name: json['name'] as String,
      logoUrl: json['logo_url'] as String?,
    );
  }
}
