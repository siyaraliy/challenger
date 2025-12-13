import { Controller, Post, Get, Body, Headers, Param, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { TeamAuthService } from './team-auth.service';
import { RegisterTeamCredentialsDto } from './dto/register-team-credentials.dto';
import { TeamLoginDto } from './dto/team-login.dto';

@Controller('auth/team')
export class TeamAuthController {
    constructor(
        private readonly teamAuthService: TeamAuthService,
        private readonly jwtService: JwtService,
    ) { }

    @Post('register')
    async registerCredentials(
        @Body() dto: RegisterTeamCredentialsDto,
        @Headers('authorization') authHeader: string,
    ) {
        const userId = this.extractUserId(authHeader);
        return this.teamAuthService.registerCredentials(dto, userId);
    }

    @Post('login')
    async login(
        @Body() dto: TeamLoginDto,
        @Headers('authorization') authHeader: string,
    ) {
        const userId = this.extractUserId(authHeader);
        return this.teamAuthService.login(dto, userId);
    }

    @Post('logout')
    async logout(@Headers('authorization') teamToken: string) {
        const token = teamToken?.replace('Bearer ', '');
        if (!token) {
            throw new UnauthorizedException('No token provided');
        }
        return this.teamAuthService.logout(token);
    }

    @Get('sessions/:teamId')
    async getSessions(@Param('teamId') teamId: string) {
        return this.teamAuthService.getSessions(teamId);
    }

    private extractUserId(authHeader: string): string {
        if (!authHeader) {
            throw new UnauthorizedException('No authorization header');
        }

        const token = authHeader.replace('Bearer ', '');

        try {
            // Decode JWT without verification (Supabase already verified it)
            const decoded = this.jwtService.decode(token) as any;
            console.log('Decoded JWT:', decoded);
            if (!decoded || !decoded.sub) {
                throw new UnauthorizedException('Invalid token');
            }
            console.log('Extracted userId:', decoded.sub);
            return decoded.sub; // User ID from Supabase JWT
        } catch (e) {
            console.error('JWT decode error:', e);
            throw new UnauthorizedException('Invalid token');
        }
    }
}
