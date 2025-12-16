import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/models/team.dart';

class TeamRepository {
  final SupabaseClient _supabase;

  TeamRepository(this._supabase);

  /// Create a new team
  /// Automatically adds current user as captain to team_members table
  Future<Team> createTeam(String name, {File? logo}) async {
    try {
      // Get current user ID (captain)
      final captainId = _supabase.auth.currentUser?.id;
      if (captainId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      String? logoUrl;

      // Upload logo if provided
      if (logo != null) {
        logoUrl = await _uploadTeamLogo(logo, captainId);
      }

      // Create team
      final teamData = {
        'name': name,
        'captain_id': captainId,
        'logo_url': logoUrl,
      };

      final response = await _supabase
          .from('teams')
          .insert(teamData)
          .select()
          .single();

      final team = Team.fromJson(response);

      // Add captain to team_members (automatic) with login permission
      await _supabase.from('team_members').insert({
        'team_id': team.id,
        'user_id': captainId,
        'can_login': true,
      });

      return team;
    } catch (e) {
      throw Exception('Takım oluşturulamadı: ${e.toString()}');
    }
  }

  /// Get team by captain ID
  Future<Team?> getMyTeam(String userId) async {
    try {
      final response = await _supabase
          .from('teams')
          .select()
          .eq('captain_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return Team.fromJson(response);
    } catch (e) {
      throw Exception('Takım getirilemedi: ${e.toString()}');
    }
  }

  /// Get team by ID
  Future<Team?> getTeam(String teamId) async {
    try {
      final response = await _supabase
          .from('teams')
          .select()
          .eq('id', teamId)
          .maybeSingle();

      if (response == null) return null;
      return Team.fromJson(response);
    } catch (e) {
      throw Exception('Takım getirilemedi: ${e.toString()}');
    }
  }

  /// Update team
  Future<void> updateTeam(Team team) async {
    try {
      await _supabase
          .from('teams')
          .update(team.toJson())
          .eq('id', team.id);
    } catch (e) {
      throw Exception('Takım güncellenemedi: ${e.toString()}');
    }
  }

  /// Delete team
  Future<void> deleteTeam(String teamId) async {
    try {
      await _supabase.from('teams').delete().eq('id', teamId);
    } catch (e) {
      throw Exception('Takım silinemedi: ${e.toString()}');
    }
  }

  /// Upload team logo to Supabase Storage
  Future<String> _uploadTeamLogo(File file, String captainId) async {
    try {
      final fileExt = file.path.split('.').last;
      final fileName = 'teams/$captainId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await _supabase.storage.from('avatars').upload(
            fileName,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      throw Exception('Logo yüklenemedi: ${e.toString()}');
    }
  }

  /// Get team members
  Future<List<String>> getTeamMembers(String teamId) async {
    try {
      final response = await _supabase
          .from('team_members')
          .select('user_id')
          .eq('team_id', teamId);

      return (response as List)
          .map((member) => member['user_id'] as String)
          .toList();
    } catch (e) {
      throw Exception('Takım üyeleri getirilemedi: ${e.toString()}');
    }
  }

  /// Add member to team
  Future<void> addTeamMember(String teamId, String userId) async {
    try {
      await _supabase.from('team_members').insert({
        'team_id': teamId,
        'user_id': userId,
      });
    } catch (e) {
      throw Exception('Üye eklenemedi: ${e.toString()}');
    }
  }

  /// Remove member from team
  Future<void> removeTeamMember(String teamId, String userId) async {
    try {
      await _supabase
          .from('team_members')
          .delete()
          .eq('team_id', teamId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Üye çıkarılamadı: ${e.toString()}');
    }
  }

  /// Get all teams where user is a member (including as captain)
  Future<List<Team>> getMyTeams(String userId) async {
    try {
      // Get team IDs where user is a member
      final membershipResponse = await _supabase
          .from('team_members')
          .select('team_id')
          .eq('user_id', userId);

      final teamIds = (membershipResponse as List)
          .map((m) => m['team_id'] as String)
          .toList();

      if (teamIds.isEmpty) return [];

      // Get team details
      final teamsResponse = await _supabase
          .from('teams')
          .select()
          .inFilter('id', teamIds);

      return (teamsResponse as List)
          .map((json) => Team.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Takımlar getirilemedi: ${e.toString()}');
    }
  }
}
