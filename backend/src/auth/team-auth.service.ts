import { Injectable, UnauthorizedException, BadRequestException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { SupabaseService } from '../supabase/supabase.service';
import { RegisterTeamCredentialsDto } from './dto/register-team-credentials.dto';
import { TeamLoginDto } from './dto/team-login.dto';

@Injectable()
export class TeamAuthService {
    constructor(
        private readonly supabaseService: SupabaseService,
        private readonly jwtService: JwtService,
    ) { }

    async registerCredentials(dto: RegisterTeamCredentialsDto, userId: string) {
        console.log('=== registerCredentials called ===');
        console.log('userId:', userId);
        console.log('teamId:', dto.teamId);
        console.log('email:', dto.email);

        // 1. Verify team exists and user is captain
        const { data: team, error: teamError } = await this.supabaseService.client
            .from('teams')
            .select('id, name, captain_id')
            .eq('id', dto.teamId)
            .single();

        console.log('Team query result:', { team, teamError });

        if (teamError || !team) {
            console.error('Team not found error:', teamError);
            throw new BadRequestException('Team not found');
        }

        // Verify user is captain of this team
        if (team.captain_id !== userId) {
            throw new BadRequestException('You are not the captain of this team');
        }

        // 2. Check if credentials already exist
        const { data: existing } = await this.supabaseService.client
            .from('team_credentials')
            .select('email')
            .eq('team_id', team.id)
            .maybeSingle();

        if (existing) {
            throw new BadRequestException('Team credentials already exist');
        }

        // 3. Hash password
        const passwordHash = await bcrypt.hash(dto.password, 10);

        console.log('Inserting credentials for team:', team.id);

        // 4. Create credentials
        const { data: credentials, error: credError } = await this.supabaseService.client
            .from('team_credentials')
            .insert({
                team_id: team.id,
                email: dto.email,
                password_hash: passwordHash,
            })
            .select('email, created_at')
            .single();

        console.log('Credentials insert result:', { credentials, credError });

        if (credError) {
            console.error('Credential insert error:', credError);
            throw new BadRequestException('Failed to create team credentials: ' + credError.message);
        }

        return {
            team: { id: team.id, name: team.name },
            credentials: { email: credentials.email, createdAt: credentials.created_at },
        };
    }

    async login(dto: TeamLoginDto, userId: string) {
        console.log('=== Team Login called ===');
        console.log('email:', dto.email);
        console.log('userId:', userId);

        // 1. Find team credentials by email
        const { data: credentials, error: credError } = await this.supabaseService.client
            .from('team_credentials')
            .select('team_id, password_hash')
            .eq('email', dto.email)
            .maybeSingle();

        console.log('Credentials query:', { credentials: credentials ? 'found' : null, credError });

        if (credError || !credentials) {
            throw new UnauthorizedException('Invalid email or password');
        }

        // 2. Verify password
        const isValidPassword = await bcrypt.compare(dto.password, credentials.password_hash);
        console.log('Password valid:', isValidPassword);
        if (!isValidPassword) {
            throw new UnauthorizedException('Invalid email or password');
        }

        // 3. Check if user is team member
        const { data: member, error: memberError } = await this.supabaseService.client
            .from('team_members')
            .select('user_id, can_login')
            .eq('team_id', credentials.team_id)
            .eq('user_id', userId)
            .maybeSingle();

        console.log('Member query:', { member, memberError });

        if (memberError || !member) {
            throw new UnauthorizedException('You are not a member of this team');
        }

        // Allow login if can_login is true OR null (default)
        if (member.can_login === false) {
            throw new UnauthorizedException('You do not have permission to login to this team');
        }

        // 4. Get team details
        console.log('Getting team details for:', credentials.team_id);
        const { data: team, error: teamError } = await this.supabaseService.client
            .from('teams')
            .select('id, name, logo_url')
            .eq('id', credentials.team_id)
            .single();

        console.log('Team details:', { team, teamError });

        if (teamError || !team) {
            throw new BadRequestException('Team not found');
        }

        // 5. Create or update team session
        console.log('Creating session for team:', team.id);
        const { error: sessionError } = await this.supabaseService.client
            .from('team_sessions')
            .upsert({
                team_id: team.id,
                user_id: userId,
                active: true,
                logged_in_at: new Date().toISOString(),
                last_activity: new Date().toISOString(),
            }, {
                onConflict: 'team_id,user_id'
            });

        if (sessionError) {
            console.error('Failed to create session:', sessionError);
            // Continue anyway - session is not critical
        } else {
            console.log('Session created successfully');
        }

        // 6. Generate team JWT token
        console.log('Generating JWT token');
        const teamToken = this.jwtService.sign({
            sub: userId,
            contextType: 'team',
            contextId: team.id,
        });
        console.log('JWT token generated successfully');

        const response = {
            teamToken,
            team: {
                id: team.id,
                name: team.name,
                logoUrl: team.logo_url,
            },
        };
        console.log('Login successful, returning:', { teamId: team.id, teamName: team.name });
        return response;
    }

    async logout(teamToken: string) {
        try {
            const payload = this.jwtService.verify(teamToken);

            const { error } = await this.supabaseService.client
                .from('team_sessions')
                .update({ active: false })
                .eq('team_id', payload.contextId)
                .eq('user_id', payload.sub);

            if (error) {
                console.error('Failed to deactivate session:', error);
            }

            return { success: true };
        } catch (error) {
            throw new UnauthorizedException('Invalid token');
        }
    }

    async getSessions(teamId: string) {
        const { data: sessions, error } = await this.supabaseService.client
            .from('team_sessions')
            .select(`
        user_id,
        logged_in_at,
        last_activity,
        profiles:user_id (display_name, avatar_url)
      `)
            .eq('team_id', teamId)
            .eq('active', true);

        if (error) {
            throw new BadRequestException('Failed to fetch sessions: ' + error.message);
        }

        return sessions || [];
    }
}
