import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/models/team_invitation.dart';
import '../../../../core/models/team.dart';

class InvitationRepository {
  final SupabaseClient _supabase;

  InvitationRepository(this._supabase);

  /// Generate a random 8-character invite code
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final buffer = StringBuffer();
    for (int i = 0; i < 8; i++) {
      final index = DateTime.now().microsecondsSinceEpoch % chars.length;
      buffer.write(chars[(index + i * 7) % chars.length]);
    }
    return buffer.toString();
  }

  /// Create a new invitation for a team
  Future<TeamInvitation> createInvitation(String teamId, {String? invitedUserId}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Generate unique invite code
      String inviteCode = _generateInviteCode();
      int attempts = 0;
      
      while (attempts < 10) {
        final existing = await _supabase
            .from('team_invitations')
            .select('id')
            .eq('invite_code', inviteCode)
            .maybeSingle();
        
        if (existing == null) break;
        inviteCode = _generateInviteCode();
        attempts++;
      }

      final expiresAt = DateTime.now().add(const Duration(days: 7));

      final response = await _supabase
          .from('team_invitations')
          .insert({
            'team_id': teamId,
            'invite_code': inviteCode,
            'invited_user_id': invitedUserId,
            'created_by': userId,
            'status': 'pending',
            'expires_at': expiresAt.toIso8601String(),
          })
          .select()
          .single();

      return TeamInvitation.fromJson(response);
    } catch (e) {
      throw Exception('Davet oluşturulamadı: ${e.toString()}');
    }
  }

  /// Get invitation by code
  Future<TeamInvitation?> getInvitationByCode(String inviteCode) async {
    try {
      final response = await _supabase
          .from('team_invitations')
          .select('''
            *,
            team:teams(id, name, logo_url)
          ''')
          .eq('invite_code', inviteCode.toUpperCase())
          .maybeSingle();

      if (response == null) return null;
      return TeamInvitation.fromJson(response);
    } catch (e) {
      throw Exception('Davet bulunamadı: ${e.toString()}');
    }
  }

  /// Get all invitations for a team
  Future<List<TeamInvitation>> getTeamInvitations(String teamId) async {
    try {
      final response = await _supabase
          .from('team_invitations')
          .select()
          .eq('team_id', teamId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => TeamInvitation.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Davetler getirilemedi: ${e.toString()}');
    }
  }

  /// Get invitations for current user
  Future<List<TeamInvitation>> getMyInvitations() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('team_invitations')
          .select('''
            *,
            team:teams(id, name, logo_url)
          ''')
          .eq('invited_user_id', userId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => TeamInvitation.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Davetler getirilemedi: ${e.toString()}');
    }
  }

  /// Accept an invitation and join the team
  Future<Team> acceptInvitation(String inviteCode) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Get invitation
      final invitation = await getInvitationByCode(inviteCode);
      
      if (invitation == null) {
        throw Exception('Davet bulunamadı');
      }

      if (invitation.status != InvitationStatus.pending) {
        throw Exception('Bu davet artık geçerli değil');
      }

      if (invitation.isExpired) {
        throw Exception('Davet süresi dolmuş');
      }

      // Check if user is already a member
      final existingMember = await _supabase
          .from('team_members')
          .select('id')
          .eq('team_id', invitation.teamId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingMember != null) {
        throw Exception('Zaten bu takımın üyesisiniz');
      }

      // Add user to team
      await _supabase
          .from('team_members')
          .insert({
            'team_id': invitation.teamId,
            'user_id': userId,
            'can_login': true,
          });

      // Update invitation status
      await _supabase
          .from('team_invitations')
          .update({'status': 'accepted', 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', invitation.id);

      // Get team info
      final teamResponse = await _supabase
          .from('teams')
          .select()
          .eq('id', invitation.teamId)
          .single();

      return Team.fromJson(teamResponse);
    } catch (e) {
      throw Exception('Takıma katılınamadı: ${e.toString()}');
    }
  }

  /// Reject an invitation
  Future<void> rejectInvitation(String invitationId) async {
    try {
      await _supabase
          .from('team_invitations')
          .update({'status': 'rejected', 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', invitationId);
    } catch (e) {
      throw Exception('Davet reddedilemedi: ${e.toString()}');
    }
  }

  /// Cancel/delete an invitation (captain only)
  Future<void> cancelInvitation(String invitationId) async {
    try {
      await _supabase
          .from('team_invitations')
          .delete()
          .eq('id', invitationId);
    } catch (e) {
      throw Exception('Davet iptal edilemedi: ${e.toString()}');
    }
  }
}
