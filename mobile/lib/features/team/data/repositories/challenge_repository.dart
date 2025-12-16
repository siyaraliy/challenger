import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/models/challenge.dart';

class ChallengeRepository {
  final SupabaseClient _supabase;

  ChallengeRepository(this._supabase);

  /// Get incoming challenges for a team (challenges where this team is challenged)
  Future<List<Challenge>> getIncomingChallenges(String teamId) async {
    try {
      print('Fetching incoming challenges for team: $teamId');
      
      final response = await _supabase
          .from('challenges')
          .select('*')
          .eq('challenged_team_id', teamId)
          .order('created_at', ascending: false);

      final challenges = <Challenge>[];
      
      for (final json in response as List) {
        try {
          // Get challenger team info
          final challengerTeam = await _supabase
              .from('teams')
              .select('name, logo_url')
              .eq('id', json['challenger_team_id'])
              .maybeSingle();
          
          final challengeData = <String, dynamic>{
            ...Map<String, dynamic>.from(json as Map),
            'challenger_team_name': challengerTeam?['name'],
            'challenger_team_logo': challengerTeam?['logo_url'],
          };
          
          challenges.add(Challenge.fromJson(challengeData));
        } catch (e) {
          print('Error parsing challenge: $e');
        }
      }
      
      print('Found ${challenges.length} incoming challenges');
      return challenges;
    } catch (e) {
      print('Error fetching incoming challenges: $e');
      return [];
    }
  }

  /// Get outgoing challenges for a team (challenges this team sent)
  Future<List<Challenge>> getOutgoingChallenges(String teamId) async {
    try {
      print('Fetching outgoing challenges for team: $teamId');
      
      final response = await _supabase
          .from('challenges')
          .select('*')
          .eq('challenger_team_id', teamId)
          .order('created_at', ascending: false);

      final challenges = <Challenge>[];
      
      for (final json in response as List) {
        try {
          // Get challenged team info
          final challengedTeam = await _supabase
              .from('teams')
              .select('name, logo_url')
              .eq('id', json['challenged_team_id'])
              .maybeSingle();
          
          final challengeData = <String, dynamic>{
            ...Map<String, dynamic>.from(json as Map),
            'challenged_team_name': challengedTeam?['name'],
            'challenged_team_logo': challengedTeam?['logo_url'],
          };
          
          challenges.add(Challenge.fromJson(challengeData));
        } catch (e) {
          print('Error parsing challenge: $e');
        }
      }
      
      print('Found ${challenges.length} outgoing challenges');
      return challenges;
    } catch (e) {
      print('Error fetching outgoing challenges: $e');
      return [];
    }
  }

  /// Create a new challenge
  Future<Challenge?> createChallenge({
    required String challengerTeamId,
    required String challengedTeamId,
    DateTime? matchDate,
    String? location,
    String? message,
  }) async {
    try {
      print('Creating challenge: $challengerTeamId -> $challengedTeamId');
      
      final response = await _supabase
          .from('challenges')
          .insert({
            'challenger_team_id': challengerTeamId,
            'challenged_team_id': challengedTeamId,
            'match_date': matchDate?.toIso8601String(),
            'location': location,
            'message': message,
            'status': 'pending',
          })
          .select()
          .single();

      print('Challenge created: ${response['id']}');
      return Challenge.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      print('Error creating challenge: $e');
      throw Exception('Meydan okuma oluşturulamadı: $e');
    }
  }

  /// Accept a challenge
  Future<bool> acceptChallenge(String challengeId) async {
    try {
      await _supabase
          .from('challenges')
          .update({'status': 'accepted'})
          .eq('id', challengeId);
      
      print('Challenge accepted: $challengeId');
      return true;
    } catch (e) {
      print('Error accepting challenge: $e');
      throw Exception('Meydan okuma kabul edilemedi: $e');
    }
  }

  /// Reject a challenge
  Future<bool> rejectChallenge(String challengeId) async {
    try {
      await _supabase
          .from('challenges')
          .update({'status': 'rejected'})
          .eq('id', challengeId);
      
      print('Challenge rejected: $challengeId');
      return true;
    } catch (e) {
      print('Error rejecting challenge: $e');
      throw Exception('Meydan okuma reddedilemedi: $e');
    }
  }

  /// Complete a challenge (awards points to both teams)
  Future<bool> completeChallenge(String challengeId) async {
    try {
      // Call the database function to complete challenge and add points
      await _supabase.rpc('complete_challenge', params: {
        'p_challenge_id': challengeId,
        'p_points': 100,
      });
      
      print('Challenge completed: $challengeId');
      return true;
    } catch (e) {
      print('Error completing challenge: $e');
      throw Exception('Maç tamamlanamadı: $e');
    }
  }

  /// Cancel a challenge (only challenger can cancel pending challenges)
  Future<bool> cancelChallenge(String challengeId) async {
    try {
      await _supabase
          .from('challenges')
          .update({'status': 'cancelled'})
          .eq('id', challengeId);
      
      print('Challenge cancelled: $challengeId');
      return true;
    } catch (e) {
      print('Error cancelling challenge: $e');
      throw Exception('Meydan okuma iptal edilemedi: $e');
    }
  }

  /// Get all teams (for team selection when creating challenge)
  Future<List<Map<String, dynamic>>> getAllTeams({String? excludeTeamId}) async {
    try {
      var query = _supabase
          .from('teams')
          .select('id, name, logo_url');
      
      if (excludeTeamId != null) {
        query = query.neq('id', excludeTeamId);
      }
      
      final response = await query.order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching teams: $e');
      return [];
    }
  }

  /// Get team points/stats
  Future<Map<String, dynamic>?> getTeamPoints(String teamId) async {
    try {
      final response = await _supabase
          .from('team_points')
          .select('*')
          .eq('team_id', teamId)
          .maybeSingle();
      
      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      print('Error fetching team points: $e');
      return null;
    }
  }

  // ==================== OPEN CHALLENGES ====================

  /// Get all open challenges (for discovery)
  Future<List<Map<String, dynamic>>> getOpenChallenges({String? excludeTeamId}) async {
    try {
      var query = _supabase
          .from('open_challenges')
          .select('*')
          .eq('status', 'open');
      
      if (excludeTeamId != null) {
        query = query.neq('team_id', excludeTeamId);
      }
      
      final response = await query.order('created_at', ascending: false);
      final List<Map<String, dynamic>> openChallenges = [];
      
      for (final json in response as List) {
        try {
          final team = await _supabase
              .from('teams')
              .select('name, logo_url')
              .eq('id', json['team_id'])
              .maybeSingle();
          
          openChallenges.add({
            ...Map<String, dynamic>.from(json as Map),
            'team_name': team?['name'],
            'team_logo': team?['logo_url'],
          });
        } catch (e) {
          print('Error parsing open challenge: $e');
        }
      }
      
      return openChallenges;
    } catch (e) {
      print('Error fetching open challenges: $e');
      return [];
    }
  }

  /// Create an open challenge
  Future<Map<String, dynamic>?> createOpenChallenge({
    required String teamId,
    required String title,
    String? message,
    DateTime? matchDate,
    String? location,
  }) async {
    try {
      final response = await _supabase
          .from('open_challenges')
          .insert({
            'team_id': teamId,
            'title': title,
            'message': message,
            'match_date': matchDate?.toIso8601String(),
            'location': location,
          })
          .select()
          .single();
      
      print('Open challenge created: ${response['id']}');
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('Error creating open challenge: $e');
      throw Exception('Açık meydan okuma oluşturulamadı: $e');
    }
  }

  /// Join an open challenge
  Future<String?> joinOpenChallenge(String openChallengeId, String joiningTeamId) async {
    try {
      final result = await _supabase.rpc('join_open_challenge', params: {
        'p_open_challenge_id': openChallengeId,
        'p_joining_team_id': joiningTeamId,
      });
      
      print('Joined open challenge, new challenge id: $result');
      return result?.toString();
    } catch (e) {
      print('Error joining open challenge: $e');
      throw Exception('Açık meydan okumaya katılınamadı: $e');
    }
  }

  /// Close an open challenge (team owner)
  Future<bool> closeOpenChallenge(String openChallengeId) async {
    try {
      await _supabase
          .from('open_challenges')
          .update({'status': 'closed'})
          .eq('id', openChallengeId);
      
      print('Open challenge closed: $openChallengeId');
      return true;
    } catch (e) {
      print('Error closing open challenge: $e');
      throw Exception('Açık meydan okuma kapatılamadı: $e');
    }
  }

  /// Get my team's open challenges
  Future<List<Map<String, dynamic>>> getMyOpenChallenges(String teamId) async {
    try {
      final response = await _supabase
          .from('open_challenges')
          .select('*')
          .eq('team_id', teamId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching my open challenges: $e');
      return [];
    }
  }
}
