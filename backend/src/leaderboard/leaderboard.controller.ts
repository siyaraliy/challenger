import {
    Controller,
    Get,
    Param,
    Query,
    NotFoundException,
    Logger,
} from '@nestjs/common';
import { LeaderboardService } from './leaderboard.service';

@Controller('leaderboard')
export class LeaderboardController {
    private readonly logger = new Logger(LeaderboardController.name);

    constructor(private readonly leaderboardService: LeaderboardService) { }

    /**
     * GET /leaderboard/teams
     * Get team rankings for leaderboard
     */
    @Get('teams')
    async getTeamLeaderboard(@Query('limit') limit?: string) {
        this.logger.log('GET /leaderboard/teams');
        const rankings = await this.leaderboardService.getTeamLeaderboard(
            limit ? parseInt(limit) : 50,
        );
        return { data: rankings };
    }

    /**
     * GET /leaderboard/teams/:id/stats
     * Get detailed stats for a specific team
     */
    @Get('teams/:id/stats')
    async getTeamStats(@Param('id') teamId: string) {
        this.logger.log(`GET /leaderboard/teams/${teamId}/stats`);
        const stats = await this.leaderboardService.getTeamStats(teamId);

        if (!stats) {
            throw new NotFoundException(`Team with ID ${teamId} not found`);
        }

        return { data: stats };
    }
}
