-- Team Follow System Migration
-- Date: 2025-12-28
-- Description: Table for following teams and triggers to update followers_count

-- =============================================
-- 1. TEAM FOLLOWS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS team_follows (
  follower_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (follower_id, team_id)
);

-- =============================================
-- 2. ADD COLUMN TO TEAMS
-- =============================================
ALTER TABLE teams ADD COLUMN IF NOT EXISTS followers_count INT DEFAULT 0;

-- =============================================
-- 3. INDEXES
-- =============================================
CREATE INDEX IF NOT EXISTS idx_team_follows_team ON team_follows(team_id);
CREATE INDEX IF NOT EXISTS idx_team_follows_follower ON team_follows(follower_id);

-- =============================================
-- 4. ENABLE RLS
-- =============================================
ALTER TABLE team_follows ENABLE ROW LEVEL SECURITY;

-- Everyone can see team follows
CREATE POLICY "Team follows are viewable by everyone"
  ON team_follows FOR SELECT
  USING (true);

-- Authenticated users can follow teams
CREATE POLICY "Users can follow teams"
  ON team_follows FOR INSERT
  WITH CHECK (follower_id = auth.uid());

-- Users can unfollow teams
CREATE POLICY "Users can unfollow teams"
  ON team_follows FOR DELETE
  USING (follower_id = auth.uid());

-- =============================================
-- 5. TRIGGER FOR TEAM FOLLOWERS COUNT
-- =============================================

-- Increment team followers count
CREATE OR REPLACE FUNCTION increment_team_followers_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE teams SET followers_count = followers_count + 1 WHERE id = NEW.team_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Decrement team followers count
CREATE OR REPLACE FUNCTION decrement_team_followers_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE teams SET followers_count = GREATEST(followers_count - 1, 0) WHERE id = OLD.team_id;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_team_follow_added
  AFTER INSERT ON team_follows
  FOR EACH ROW
  EXECUTE FUNCTION increment_team_followers_count();

CREATE TRIGGER on_team_follow_removed
  AFTER DELETE ON team_follows
  FOR EACH ROW
  EXECUTE FUNCTION decrement_team_followers_count();
