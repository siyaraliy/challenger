import { Injectable } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';

export interface TeamInvitation {
    id: string;
    team_id: string;
    invite_code: string;
    invited_user_id?: string;
    status: 'pending' | 'accepted' | 'rejected' | 'expired';
    expires_at: string;
    created_by?: string;
    created_at: string;
    updated_at: string;
}

export interface InvitationWithTeam extends TeamInvitation {
    team?: {
        id: string;
        name: string;
        logo_url?: string;
    };
}

@Injectable()
export class InvitationsService {
    constructor(private readonly supabase: SupabaseService) { }

    /**
     * Generate a random 8-character invite code
     */
    private generateInviteCode(): string {
        const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
        let code = '';
        for (let i = 0; i < 8; i++) {
            code += chars.charAt(Math.floor(Math.random() * chars.length));
        }
        return code;
    }

    /**
     * Create a new invitation for a team
     */
    async createInvitation(
        teamId: string,
        createdBy: string,
        invitedUserId?: string
    ): Promise<TeamInvitation> {
        const client = this.supabase.getClient();

        // Generate unique invite code
        let inviteCode = this.generateInviteCode();
        let attempts = 0;

        // Ensure code is unique
        while (attempts < 10) {
            const { data: existing } = await client
                .from('team_invitations')
                .select('id')
                .eq('invite_code', inviteCode)
                .maybeSingle();

            if (!existing) break;
            inviteCode = this.generateInviteCode();
            attempts++;
        }

        const { data, error } = await client
            .from('team_invitations')
            .insert({
                team_id: teamId,
                invite_code: inviteCode,
                invited_user_id: invitedUserId,
                created_by: createdBy,
                status: 'pending',
                expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
            })
            .select()
            .single();

        if (error) {
            throw new Error(`Davet oluşturulamadı: ${error.message}`);
        }

        return data;
    }

    /**
     * Get invitation by code
     */
    async getInvitationByCode(inviteCode: string): Promise<InvitationWithTeam | null> {
        const client = this.supabase.getClient();

        const { data, error } = await client
            .from('team_invitations')
            .select(`
        *,
        team:teams(id, name, logo_url)
      `)
            .eq('invite_code', inviteCode.toUpperCase())
            .maybeSingle();

        if (error) {
            throw new Error(`Davet bulunamadı: ${error.message}`);
        }

        return data;
    }

    /**
     * Get all invitations for a team
     */
    async getTeamInvitations(teamId: string): Promise<TeamInvitation[]> {
        const client = this.supabase.getClient();

        const { data, error } = await client
            .from('team_invitations')
            .select('*')
            .eq('team_id', teamId)
            .order('created_at', { ascending: false });

        if (error) {
            throw new Error(`Davetler getirilemedi: ${error.message}`);
        }

        return data || [];
    }

    /**
     * Get invitations for a specific user
     */
    async getUserInvitations(userId: string): Promise<InvitationWithTeam[]> {
        const client = this.supabase.getClient();

        const { data, error } = await client
            .from('team_invitations')
            .select(`
        *,
        team:teams(id, name, logo_url)
      `)
            .eq('invited_user_id', userId)
            .eq('status', 'pending')
            .order('created_at', { ascending: false });

        if (error) {
            throw new Error(`Davetler getirilemedi: ${error.message}`);
        }

        return data || [];
    }

    /**
     * Accept an invitation and join the team
     */
    async acceptInvitation(inviteCode: string, userId: string): Promise<{ team_id: string }> {
        const client = this.supabase.getClient();

        // Get invitation
        const invitation = await this.getInvitationByCode(inviteCode);

        if (!invitation) {
            throw new Error('Davet bulunamadı');
        }

        if (invitation.status !== 'pending') {
            throw new Error('Bu davet artık geçerli değil');
        }

        if (new Date(invitation.expires_at) < new Date()) {
            throw new Error('Davet süresi dolmuş');
        }

        // Check if user is already a member
        const { data: existingMember } = await client
            .from('team_members')
            .select('id')
            .eq('team_id', invitation.team_id)
            .eq('user_id', userId)
            .maybeSingle();

        if (existingMember) {
            throw new Error('Zaten bu takımın üyesisiniz');
        }

        // Add user to team
        const { error: memberError } = await client
            .from('team_members')
            .insert({
                team_id: invitation.team_id,
                user_id: userId,
                can_login: true,
            });

        if (memberError) {
            throw new Error(`Takıma katılınamadı: ${memberError.message}`);
        }

        // Update invitation status
        const { error: updateError } = await client
            .from('team_invitations')
            .update({ status: 'accepted', updated_at: new Date().toISOString() })
            .eq('id', invitation.id);

        if (updateError) {
            // Rollback: remove member if update fails
            await client
                .from('team_members')
                .delete()
                .eq('team_id', invitation.team_id)
                .eq('user_id', userId);
            throw new Error(`Davet güncellenemedi: ${updateError.message}`);
        }

        return { team_id: invitation.team_id };
    }

    /**
     * Reject an invitation
     */
    async rejectInvitation(invitationId: string, userId: string): Promise<void> {
        const client = this.supabase.getClient();

        const { error } = await client
            .from('team_invitations')
            .update({ status: 'rejected', updated_at: new Date().toISOString() })
            .eq('id', invitationId)
            .eq('invited_user_id', userId);

        if (error) {
            throw new Error(`Davet reddedilemedi: ${error.message}`);
        }
    }

    /**
     * Cancel/delete an invitation (only captain)
     */
    async cancelInvitation(invitationId: string): Promise<void> {
        const client = this.supabase.getClient();

        const { error } = await client
            .from('team_invitations')
            .delete()
            .eq('id', invitationId);

        if (error) {
            throw new Error(`Davet iptal edilemedi: ${error.message}`);
        }
    }

    /**
     * Expire old invitations
     */
    async expireOldInvitations(): Promise<number> {
        const client = this.supabase.getClient();

        const { data, error } = await client
            .from('team_invitations')
            .update({ status: 'expired', updated_at: new Date().toISOString() })
            .eq('status', 'pending')
            .lt('expires_at', new Date().toISOString())
            .select('id');

        if (error) {
            throw new Error(`Davetler güncellenemedi: ${error.message}`);
        }

        return data?.length || 0;
    }
}
