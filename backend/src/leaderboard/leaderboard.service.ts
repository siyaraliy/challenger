import { Injectable, Logger } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';

export interface TeamRanking {
    id: string;
    name: string;
    logo_url: string | null;
    total_points: number;
    matches_played: number;
    member_count: number;
    rank: number;
}

export interface TeamStats {
    team_id: string;
    team_name: string;
    logo_url: string | null;
    total_points: number;
    matches_played: number;
    member_count: number;
    rank: number;
    recent_challenges: Array<{
        id: string;
        status: string;
        points_awarded: number;
        updated_at: string;
        opponent_team_id: string;
    }> | null;
}

@Injectable()
export class LeaderboardService {
    private readonly logger = new Logger(LeaderboardService.name);

    constructor(private readonly supabaseService: SupabaseService) { }

    /**
     * Get team leaderboard rankings
     */
    async getTeamLeaderboard(limit: number = 50): Promise<TeamRanking[]> {
        this.logger.log(`Fetching team leaderboard with limit: ${limit}`);

        const { data, error } = await this.supabaseService
            .from('team_rankings')
            .select('*')
            .limit(limit);

        if (error) {
            this.logger.error(`Failed to fetch leaderboard: ${error.message}`);
            throw error;
        }

        return data as TeamRanking[];
    }

    /**
     * Get detailed stats for a specific team
     */
    async getTeamStats(teamId: string): Promise<TeamStats | null> {
        this.logger.log(`Fetching stats for team: ${teamId}`);

        const { data, error } = await this.supabaseService
            .getClient()
            .rpc('get_team_stats', { p_team_id: teamId });

        if (error) {
            this.logger.error(`Failed to fetch team stats: ${error.message}`);
            throw error;
        }

        if (!data || data.length === 0) {
            return null;
        }

        return data[0] as TeamStats;
    }

    /**
     * Get team's rank position
     */
    async getTeamRank(teamId: string): Promise<number | null> {
        const { data, error } = await this.supabaseService
            .from('team_rankings')
            .select('rank')
            .eq('id', teamId)
            .single();

        if (error) {
            this.logger.error(`Failed to fetch team rank: ${error.message}`);
            return null;
        }

        return data?.rank ?? null;
    }
}
