import 'package:equatable/equatable.dart';

enum ChallengeStatus { pending, accepted, rejected, completed, cancelled }

class Challenge extends Equatable {
  final String id;
  final String challengerTeamId;
  final String challengedTeamId;
  final String? challengerTeamName;
  final String? challengedTeamName;
  final String? challengerTeamLogo;
  final String? challengedTeamLogo;
  final ChallengeStatus status;
  final DateTime? matchDate;
  final String? location;
  final String? message;
  final int pointsAwarded;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Challenge({
    required this.id,
    required this.challengerTeamId,
    required this.challengedTeamId,
    this.challengerTeamName,
    this.challengedTeamName,
    this.challengerTeamLogo,
    this.challengedTeamLogo,
    this.status = ChallengeStatus.pending,
    this.matchDate,
    this.location,
    this.message,
    this.pointsAwarded = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      challengerTeamId: json['challenger_team_id'] as String,
      challengedTeamId: json['challenged_team_id'] as String,
      challengerTeamName: json['challenger_team_name'] as String?,
      challengedTeamName: json['challenged_team_name'] as String?,
      challengerTeamLogo: json['challenger_team_logo'] as String?,
      challengedTeamLogo: json['challenged_team_logo'] as String?,
      status: _parseStatus(json['status'] as String?),
      matchDate: json['match_date'] != null 
          ? DateTime.parse(json['match_date'] as String) 
          : null,
      location: json['location'] as String?,
      message: json['message'] as String?,
      pointsAwarded: json['points_awarded'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  static ChallengeStatus _parseStatus(String? status) {
    switch (status) {
      case 'pending':
        return ChallengeStatus.pending;
      case 'accepted':
        return ChallengeStatus.accepted;
      case 'rejected':
        return ChallengeStatus.rejected;
      case 'completed':
        return ChallengeStatus.completed;
      case 'cancelled':
        return ChallengeStatus.cancelled;
      default:
        return ChallengeStatus.pending;
    }
  }

  String get statusText {
    switch (status) {
      case ChallengeStatus.pending:
        return 'Bekliyor';
      case ChallengeStatus.accepted:
        return 'Kabul Edildi';
      case ChallengeStatus.rejected:
        return 'Reddedildi';
      case ChallengeStatus.completed:
        return 'Tamamlandı';
      case ChallengeStatus.cancelled:
        return 'İptal Edildi';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dk önce';
    } else {
      return 'Şimdi';
    }
  }

  String get formattedMatchDate {
    if (matchDate == null) return 'Tarih belirtilmedi';
    final months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    return '${matchDate!.day} ${months[matchDate!.month - 1]} ${matchDate!.year} - ${matchDate!.hour.toString().padLeft(2, '0')}:${matchDate!.minute.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
        id,
        challengerTeamId,
        challengedTeamId,
        status,
        matchDate,
        pointsAwarded,
      ];
}
