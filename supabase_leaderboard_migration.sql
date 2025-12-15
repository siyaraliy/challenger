-- Leaderboard & Stats Migration
-- Date: 2024-12-15
-- Description: team_rankings view for leaderboard

-- =============================================
-- 1. TEAM RANKINGS VIEW
-- =============================================
CREATE OR REPLACE VIEW team_rankings AS
SELECT 
  t.id,
  t.name,
  t.logo_url,
  COALESCE(tp.total_points, 0) as total_points,
  COALESCE(tp.matches_played, 0) as matches_played,
  (SELECT COUNT(*) FROM team_members tm WHERE tm.team_id = t.id) as member_count,
  ROW_NUMBER() OVER (ORDER BY COALESCE(tp.total_points, 0) DESC, t.created_at ASC) as rank
FROM teams t
LEFT JOIN team_points tp ON t.id = tp.team_id
ORDER BY COALESCE(tp.total_points, 0) DESC;

-- =============================================
-- 2. GRANT SELECT ON VIEW
-- =============================================
-- Anyone can read leaderboard (public data)
GRANT SELECT ON team_rankings TO anon, authenticated;

-- =============================================
-- 3. TEAM STATS FUNCTION
-- =============================================
CREATE OR REPLACE FUNCTION get_team_stats(p_team_id UUID)
RETURNS TABLE (
  team_id UUID,
  team_name TEXT,
  logo_url TEXT,
  total_points INT,
  matches_played INT,
  member_count BIGINT,
  rank BIGINT,
  recent_challenges JSON
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    tr.id as team_id,
    tr.name as team_name,
    tr.logo_url,
    tr.total_points::INT,
    tr.matches_played::INT,
    tr.member_count,
    tr.rank,
    (
      SELECT json_agg(c ORDER BY c.updated_at DESC)
      FROM (
        SELECT 
          ch.id,
          ch.status,
          ch.points_awarded,
          ch.updated_at,
          CASE 
            WHEN ch.challenger_team_id = p_team_id THEN ch.challenged_team_id
            ELSE ch.challenger_team_id
          END as opponent_team_id
        FROM challenges ch
        WHERE (ch.challenger_team_id = p_team_id OR ch.challenged_team_id = p_team_id)
          AND ch.status = 'completed'
        LIMIT 5
      ) c
    ) as recent_challenges
  FROM team_rankings tr
  WHERE tr.id = p_team_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON VIEW team_rankings IS 'Leaderboard view - teams ranked by points';
COMMENT ON FUNCTION get_team_stats IS 'Get detailed stats for a specific team including recent challenges';
