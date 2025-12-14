-- Open Challenges Migration (Only new parts)
-- Run this after the main challenge migration

-- =============================================
-- OPEN CHALLENGES TABLE (Herkese Açık Meydan Okumalar)
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

-- Drop existing policies if any
DROP POLICY IF EXISTS "Open challenges are viewable by everyone" ON open_challenges;
DROP POLICY IF EXISTS "Team members can create open challenges" ON open_challenges;
DROP POLICY IF EXISTS "Team can update own open challenges" ON open_challenges;
DROP POLICY IF EXISTS "Team can delete own open challenges" ON open_challenges;

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
