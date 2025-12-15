import {
    Controller,
    Post,
    Get,
    Delete,
    Patch,
    Param,
    Body,
    Headers,
    HttpException,
    HttpStatus,
} from '@nestjs/common';
import { InvitationsService } from './invitations.service';
import { SupabaseService } from '../supabase/supabase.service';

interface CreateInvitationDto {
    invitedUserId?: string;
}

@Controller('invitations')
export class InvitationsController {
    constructor(
        private readonly invitationsService: InvitationsService,
        private readonly supabase: SupabaseService,
    ) { }

    /**
     * Helper: Get user ID from authorization header
     */
    private async getUserIdFromToken(authHeader: string): Promise<string> {
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            throw new HttpException('Yetkilendirme gerekli', HttpStatus.UNAUTHORIZED);
        }

        const token = authHeader.replace('Bearer ', '');
        const client = this.supabase.getClient();

        const { data: { user }, error } = await client.auth.getUser(token);

        if (error || !user) {
            throw new HttpException('Geçersiz token', HttpStatus.UNAUTHORIZED);
        }

        return user.id;
    }

    /**
     * Helper: Verify user is team captain
     */
    private async verifyCaptain(teamId: string, userId: string): Promise<void> {
        const client = this.supabase.getClient();

        const { data: team } = await client
            .from('teams')
            .select('captain_id')
            .eq('id', teamId)
            .single();

        if (!team || team.captain_id !== userId) {
            throw new HttpException('Bu işlem için kaptan yetkisi gerekli', HttpStatus.FORBIDDEN);
        }
    }

    /**
     * Helper: Verify user is team member
     */
    private async verifyMember(teamId: string, userId: string): Promise<void> {
        const client = this.supabase.getClient();

        const { data: member } = await client
            .from('team_members')
            .select('id')
            .eq('team_id', teamId)
            .eq('user_id', userId)
            .maybeSingle();

        if (!member) {
            throw new HttpException('Bu işlem için takım üyesi olmalısınız', HttpStatus.FORBIDDEN);
        }
    }

    /**
     * POST /invitations/teams/:teamId
     * Create a new invitation for a team
     */
    @Post('teams/:teamId')
    async createInvitation(
        @Param('teamId') teamId: string,
        @Body() body: CreateInvitationDto,
        @Headers('authorization') authHeader: string,
    ) {
        try {
            const userId = await this.getUserIdFromToken(authHeader);

            // Verify user is a team member (not just captain, any member can invite)
            await this.verifyMember(teamId, userId);

            const invitation = await this.invitationsService.createInvitation(
                teamId,
                userId,
                body.invitedUserId,
            );

            return {
                success: true,
                invitation,
                inviteCode: invitation.invite_code,
                expiresAt: invitation.expires_at,
            };
        } catch (error) {
            if (error instanceof HttpException) throw error;
            throw new HttpException(
                error.message || 'Davet oluşturulamadı',
                HttpStatus.BAD_REQUEST,
            );
        }
    }

    /**
     * GET /invitations/teams/:teamId
     * Get all invitations for a team
     */
    @Get('teams/:teamId')
    async getTeamInvitations(
        @Param('teamId') teamId: string,
        @Headers('authorization') authHeader: string,
    ) {
        try {
            const userId = await this.getUserIdFromToken(authHeader);
            await this.verifyMember(teamId, userId);

            const invitations = await this.invitationsService.getTeamInvitations(teamId);

            return {
                success: true,
                invitations,
            };
        } catch (error) {
            if (error instanceof HttpException) throw error;
            throw new HttpException(
                error.message || 'Davetler getirilemedi',
                HttpStatus.BAD_REQUEST,
            );
        }
    }

    /**
     * DELETE /invitations/:invitationId
     * Cancel an invitation (captain only)
     */
    @Delete(':invitationId')
    async cancelInvitation(
        @Param('invitationId') invitationId: string,
        @Headers('authorization') authHeader: string,
    ) {
        try {
            const userId = await this.getUserIdFromToken(authHeader);

            // Get invitation to find team
            const client = this.supabase.getClient();
            const { data: invitation } = await client
                .from('team_invitations')
                .select('team_id')
                .eq('id', invitationId)
                .single();

            if (!invitation) {
                throw new HttpException('Davet bulunamadı', HttpStatus.NOT_FOUND);
            }

            await this.verifyCaptain(invitation.team_id, userId);
            await this.invitationsService.cancelInvitation(invitationId);

            return {
                success: true,
                message: 'Davet iptal edildi',
            };
        } catch (error) {
            if (error instanceof HttpException) throw error;
            throw new HttpException(
                error.message || 'Davet iptal edilemedi',
                HttpStatus.BAD_REQUEST,
            );
        }
    }

    /**
     * GET /invitations/code/:inviteCode
     * Get invitation details by code (for preview before joining)
     */
    @Get('code/:inviteCode')
    async getInvitationByCode(@Param('inviteCode') inviteCode: string) {
        try {
            const invitation = await this.invitationsService.getInvitationByCode(inviteCode);

            if (!invitation) {
                throw new HttpException('Davet bulunamadı', HttpStatus.NOT_FOUND);
            }

            return {
                success: true,
                invitation: {
                    id: invitation.id,
                    status: invitation.status,
                    expiresAt: invitation.expires_at,
                    team: invitation.team,
                },
            };
        } catch (error) {
            if (error instanceof HttpException) throw error;
            throw new HttpException(
                error.message || 'Davet bulunamadı',
                HttpStatus.NOT_FOUND,
            );
        }
    }

    /**
     * POST /invitations/join/:inviteCode
     * Accept an invitation and join the team
     */
    @Post('join/:inviteCode')
    async joinTeam(
        @Param('inviteCode') inviteCode: string,
        @Headers('authorization') authHeader: string,
    ) {
        try {
            const userId = await this.getUserIdFromToken(authHeader);

            const result = await this.invitationsService.acceptInvitation(inviteCode, userId);

            // Get team info
            const client = this.supabase.getClient();
            const { data: team } = await client
                .from('teams')
                .select('id, name, logo_url')
                .eq('id', result.team_id)
                .single();

            return {
                success: true,
                message: 'Takıma başarıyla katıldınız',
                team,
            };
        } catch (error) {
            if (error instanceof HttpException) throw error;
            throw new HttpException(
                error.message || 'Takıma katılınamadı',
                HttpStatus.BAD_REQUEST,
            );
        }
    }

    /**
     * GET /invitations/my
     * Get all invitations for the current user
     */
    @Get('my')
    async getMyInvitations(@Headers('authorization') authHeader: string) {
        try {
            const userId = await this.getUserIdFromToken(authHeader);

            const invitations = await this.invitationsService.getUserInvitations(userId);

            return {
                success: true,
                invitations,
            };
        } catch (error) {
            if (error instanceof HttpException) throw error;
            throw new HttpException(
                error.message || 'Davetler getirilemedi',
                HttpStatus.BAD_REQUEST,
            );
        }
    }

    /**
     * PATCH /invitations/:invitationId/reject
     * Reject an invitation
     */
    @Patch(':invitationId/reject')
    async rejectInvitation(
        @Param('invitationId') invitationId: string,
        @Headers('authorization') authHeader: string,
    ) {
        try {
            const userId = await this.getUserIdFromToken(authHeader);

            await this.invitationsService.rejectInvitation(invitationId, userId);

            return {
                success: true,
                message: 'Davet reddedildi',
            };
        } catch (error) {
            if (error instanceof HttpException) throw error;
            throw new HttpException(
                error.message || 'Davet reddedilemedi',
                HttpStatus.BAD_REQUEST,
            );
        }
    }
}
