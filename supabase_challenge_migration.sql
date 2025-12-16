-- Challenge System Migration
-- Date: 2024-12-14
-- Description: Challenges and team_points tables with RLS

-- =============================================
-- 1. CHALLENGES TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS challenges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  challenger_team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  challenged_team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  status VARCHAR(20) DEFAULT 'pending' 
    CHECK (status IN ('pending', 'accepted', 'rejected', 'completed', 'cancelled')),
  match_date TIMESTAMPTZ,
  location TEXT,
  message TEXT,
  points_awarded INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraint: Cannot challenge yourself
  CONSTRAINT different_teams CHECK (challenger_team_id != challenged_team_id)
);

-- =============================================
-- 2. TEAM POINTS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS team_points (
  team_id UUID PRIMARY KEY REFERENCES teams(id) ON DELETE CASCADE,
  total_points INT DEFAULT 0,
  matches_played INT DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- 3. INDEXES
-- =============================================
CREATE INDEX IF NOT EXISTS idx_challenges_challenger ON challenges(challenger_team_id, status);
CREATE INDEX IF NOT EXISTS idx_challenges_challenged ON challenges(challenged_team_id, status);
CREATE INDEX IF NOT EXISTS idx_challenges_status ON challenges(status);
CREATE INDEX IF NOT EXISTS idx_team_points_total ON team_points(total_points DESC);

-- =============================================
-- 4. ENABLE RLS
-- =============================================
ALTER TABLE challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_points ENABLE ROW LEVEL SECURITY;

-- =============================================
-- 5. RLS POLICIES FOR CHALLENGES
-- =============================================

-- Everyone can view challenges (for leaderboard/stats)
CREATE POLICY "Challenges are viewable by everyone"
  ON challenges FOR SELECT
  USING (true);

-- Team members can create challenges for their team
CREATE POLICY "Team members can create challenges"
  ON challenges FOR INSERT
  WITH CHECK (
    challenger_team_id IN (
      SELECT team_id FROM team_members WHERE user_id = auth.uid()
    )
  );

-- Only involved teams can update challenge status
CREATE POLICY "Involved teams can update challenges"
  ON challenges FOR UPDATE
  USING (
    challenger_team_id IN (SELECT team_id FROM team_members WHERE user_id = auth.uid())
    OR
    challenged_team_id IN (SELECT team_id FROM team_members WHERE user_id = auth.uid())
  );

-- =============================================
-- 6. RLS POLICIES FOR TEAM POINTS
-- =============================================

-- Everyone can view team points (leaderboard)
CREATE POLICY "Team points are viewable by everyone"
  ON team_points FOR SELECT
  USING (true);

-- Only system can insert/update (via functions)
CREATE POLICY "Team points insert by team members"
  ON team_points FOR INSERT
  WITH CHECK (
    team_id IN (SELECT team_id FROM team_members WHERE user_id = auth.uid())
  );

CREATE POLICY "Team points update by involved users"
  ON team_points FOR UPDATE
  USING (
    team_id IN (SELECT team_id FROM team_members WHERE user_id = auth.uid())
  );

-- =============================================
-- 7. FUNCTION: Add points to team
-- =============================================
CREATE OR REPLACE FUNCTION add_team_points(p_team_id UUID, p_points INT)
RETURNS void AS $$
BEGIN
  INSERT INTO team_points (team_id, total_points, matches_played)
  VALUES (p_team_id, p_points, 1)
  ON CONFLICT (team_id) DO UPDATE SET
    total_points = team_points.total_points + p_points,
    matches_played = team_points.matches_played + 1,
    updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- 8. FUNCTION: Complete challenge (adds points to both teams)
-- =============================================
CREATE OR REPLACE FUNCTION complete_challenge(p_challenge_id UUID, p_points INT DEFAULT 100)
RETURNS void AS $$
DECLARE
  v_challenger_id UUID;
  v_challenged_id UUID;
  v_status VARCHAR(20);
BEGIN
  -- Get challenge info
  SELECT challenger_team_id, challenged_team_id, status 
  INTO v_challenger_id, v_challenged_id, v_status
  FROM challenges 
  WHERE id = p_challenge_id;
  
  -- Check if challenge exists and is accepted
  IF v_status != 'accepted' THEN
    RAISE EXCEPTION 'Challenge must be accepted before completing';
  END IF;
  
  -- Add points to both teams
  PERFORM add_team_points(v_challenger_id, p_points);
  PERFORM add_team_points(v_challenged_id, p_points);
  
  -- Update challenge status
  UPDATE challenges 
  SET status = 'completed', 
      points_awarded = p_points,
      updated_at = NOW()
  WHERE id = p_challenge_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- 9. UPDATED_AT TRIGGERS
-- =============================================
CREATE OR REPLACE FUNCTION update_challenges_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_challenges_updated_at_trigger
  BEFORE UPDATE ON challenges
  FOR EACH ROW
  EXECUTE FUNCTION update_challenges_updated_at();

-- =============================================
-- COMMENTS
-- =============================================
COMMENT ON TABLE challenges IS 'Challenge/match requests between teams';
COMMENT ON TABLE team_points IS 'Team points and match statistics';
COMMENT ON FUNCTION complete_challenge IS 'Complete a challenge and award points to both teams';

-- =============================================
-- 10. OPEN CHALLENGES TABLE (Herkese Açık Meydan Okumalar)
-- =============================================
CREATE TABLE IF NOT EXISTS open_challenges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT,
  match_date TIMESTAMPTZ,
  location TEXT,
  status VARCHAR(20) DEFAULT 'open' 
    CHECK (status IN ('open', 'closed', 'matched')),
  matched_team_id UUID REFERENCES teams(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for open challenges
CREATE INDEX IF NOT EXISTS idx_open_challenges_status ON open_challenges(status, created_at DESC);

-- Enable RLS
ALTER TABLE open_challenges ENABLE ROW LEVEL SECURITY;

-- Everyone can view open challenges
CREATE POLICY "Open challenges are viewable by everyone"
  ON open_challenges FOR SELECT
  USING (true);

-- Team members can create open challenges
CREATE POLICY "Team members can create open challenges"
  ON open_challenges FOR INSERT
  WITH CHECK (
    team_id IN (SELECT team_id FROM team_members WHERE user_id = auth.uid())
  );

-- Team that created can update
CREATE POLICY "Team can update own open challenges"
  ON open_challenges FOR UPDATE
  USING (
    team_id IN (SELECT team_id FROM team_members WHERE user_id = auth.uid())
  );

-- Team can delete own open challenges
CREATE POLICY "Team can delete own open challenges"
  ON open_challenges FOR DELETE
  USING (
    team_id IN (SELECT team_id FROM team_members WHERE user_id = auth.uid())
  );

-- Function: Join an open challenge (creates a private challenge)
CREATE OR REPLACE FUNCTION join_open_challenge(p_open_challenge_id UUID, p_joining_team_id UUID)
RETURNS UUID AS $$
DECLARE
  v_host_team_id UUID;
  v_match_date TIMESTAMPTZ;
  v_location TEXT;
  v_new_challenge_id UUID;
BEGIN
  -- Get open challenge info
  SELECT team_id, match_date, location 
  INTO v_host_team_id, v_match_date, v_location
  FROM open_challenges 
  WHERE id = p_open_challenge_id AND status = 'open';
  
  IF v_host_team_id IS NULL THEN
    RAISE EXCEPTION 'Open challenge not found or already matched';
  END IF;
  
  IF v_host_team_id = p_joining_team_id THEN
    RAISE EXCEPTION 'Cannot join your own open challenge';
  END IF;
  
  -- Create a private challenge
  INSERT INTO challenges (challenger_team_id, challenged_team_id, match_date, location, status)
  VALUES (p_joining_team_id, v_host_team_id, v_match_date, v_location, 'pending')
  RETURNING id INTO v_new_challenge_id;
  
  -- Update open challenge status
  UPDATE open_challenges 
  SET status = 'matched', 
      matched_team_id = p_joining_team_id,
      updated_at = NOW()
  WHERE id = p_open_challenge_id;
  
  RETURN v_new_challenge_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON TABLE open_challenges IS 'Open challenges visible to all teams for joining';
COMMENT ON FUNCTION join_open_challenge IS 'Join an open challenge and create a private challenge';
