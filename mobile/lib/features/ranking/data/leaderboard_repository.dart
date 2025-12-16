import 'package:supabase_flutter/supabase_flutter.dart';

/// Team ranking data model
class TeamRanking {
  final String id;
  final String name;
  final String? logoUrl;
  final int totalPoints;
  final int matchesPlayed;
  final int memberCount;
  final int rank;

  const TeamRanking({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.totalPoints,
    required this.matchesPlayed,
    required this.memberCount,
    required this.rank,
  });

  factory TeamRanking.fromJson(Map<String, dynamic> json) {
    return TeamRanking(
      id: json['id'] as String,
      name: json['name'] as String,
      logoUrl: json['logo_url'] as String?,
      totalPoints: (json['total_points'] as num?)?.toInt() ?? 0,
      matchesPlayed: (json['matches_played'] as num?)?.toInt() ?? 0,
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Team detailed stats model
class TeamStats {
  final String teamId;
  final String teamName;
  final String? logoUrl;
  final int totalPoints;
  final int matchesPlayed;
  final int memberCount;
  final int rank;
  final List<RecentChallenge> recentChallenges;

  const TeamStats({
    required this.teamId,
    required this.teamName,
    this.logoUrl,
    required this.totalPoints,
    required this.matchesPlayed,
    required this.memberCount,
    required this.rank,
    required this.recentChallenges,
  });

  factory TeamStats.fromJson(Map<String, dynamic> json) {
    final challenges = json['recent_challenges'] as List<dynamic>? ?? [];
    return TeamStats(
      teamId: json['team_id'] as String,
      teamName: json['team_name'] as String,
      logoUrl: json['logo_url'] as String?,
      totalPoints: (json['total_points'] as num?)?.toInt() ?? 0,
      matchesPlayed: (json['matches_played'] as num?)?.toInt() ?? 0,
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      recentChallenges: challenges
          .map((c) => RecentChallenge.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RecentChallenge {
  final String id;
  final String status;
  final int pointsAwarded;
  final String updatedAt;
  final String opponentTeamId;

  const RecentChallenge({
    required this.id,
    required this.status,
    required this.pointsAwarded,
    required this.updatedAt,
    required this.opponentTeamId,
  });

  factory RecentChallenge.fromJson(Map<String, dynamic> json) {
    return RecentChallenge(
      id: json['id'] as String,
      status: json['status'] as String? ?? '',
      pointsAwarded: (json['points_awarded'] as num?)?.toInt() ?? 0,
      updatedAt: json['updated_at'] as String? ?? '',
      opponentTeamId: json['opponent_team_id'] as String? ?? '',
    );
  }
}

/// Repository for leaderboard data
class LeaderboardRepository {
  final SupabaseClient _supabase;

  LeaderboardRepository(this._supabase);

  /// Get team leaderboard rankings
  Future<List<TeamRanking>> getTeamLeaderboard({int limit = 50}) async {
    final response = await _supabase
        .from('team_rankings')
        .select()
        .limit(limit);

    return (response as List<dynamic>)
        .map((json) => TeamRanking.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get detailed stats for a specific team
  Future<TeamStats?> getTeamStats(String teamId) async {
    final response = await _supabase
        .rpc('get_team_stats', params: {'p_team_id': teamId});

    if (response == null || (response as List).isEmpty) {
      return null;
    }

    return TeamStats.fromJson(response[0] as Map<String, dynamic>);
  }

  /// Get team's rank position
  Future<int?> getTeamRank(String teamId) async {
    final response = await _supabase
        .from('team_rankings')
        .select('rank')
        .eq('id', teamId)
        .maybeSingle();

    return response?['rank'] as int?;
  }
}
