-- Team Authentication System Migration
-- Date: 2024-12-12
-- Description: Add team credentials and sessions for team authentication

-- 1. Team Credentials Table
CREATE TABLE IF NOT EXISTS team_credentials (
  team_id UUID PRIMARY KEY REFERENCES teams(id) ON DELETE CASCADE,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Team Sessions Table
CREATE TABLE IF NOT EXISTS team_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  active BOOLEAN DEFAULT TRUE,
  logged_in_at TIMESTAMPTZ DEFAULT NOW(),
  last_activity TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(team_id, user_id)
);

-- 3. Update team_members table
ALTER TABLE team_members 
ADD COLUMN IF NOT EXISTS can_login BOOLEAN DEFAULT TRUE;

-- 4. Indexes for performance
CREATE INDEX IF NOT EXISTS idx_team_credentials_email ON team_credentials(email);
CREATE INDEX IF NOT EXISTS idx_team_sessions_team ON team_sessions(team_id);
CREATE INDEX IF NOT EXISTS idx_team_sessions_user ON team_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_team_sessions_active ON team_sessions(active) WHERE active = TRUE;

-- 5. Enable RLS
ALTER TABLE team_credentials ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_sessions ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies for team_credentials

-- Captains can manage their team's credentials
CREATE POLICY "Captains can manage team credentials"
  ON team_credentials
  FOR ALL
  USING (
    team_id IN (
      SELECT id FROM teams WHERE captain_id = auth.uid()
    )
  );

-- Team members can view credentials (read-only)
CREATE POLICY "Team members can view credentials"
  ON team_credentials
  FOR SELECT
  USING (
    team_id IN (
      SELECT team_id FROM team_members WHERE user_id = auth.uid()
    )
  );

-- 7. RLS Policies for team_sessions

-- Team members can view all sessions of their team
CREATE POLICY "Team members can view team sessions"
  ON team_sessions
  FOR SELECT
  USING (
    team_id IN (
      SELECT team_id FROM team_members WHERE user_id = auth.uid()
    )
  );

-- Users can manage their own sessions
CREATE POLICY "Users can manage own team sessions"
  ON team_sessions
  FOR ALL
  USING (user_id = auth.uid());

-- 8. Function to automatically create team credentials when team is created
CREATE OR REPLACE FUNCTION create_team_credentials()
RETURNS TRIGGER AS $$
BEGIN
  -- Team credentials will be created manually when captain sets them
  -- This trigger placeholder can be used for auto-generation if needed
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Optional: Create trigger (commented out for manual credential creation)
-- CREATE TRIGGER on_team_created
--   AFTER INSERT ON teams
--   FOR EACH ROW
--   EXECUTE FUNCTION create_team_credentials();

-- 9. Function to update last_activity on team sessions
CREATE OR REPLACE FUNCTION update_team_session_activity()
RETURNS TRIGGER AS $$
BEGIN
  NEW.last_activity = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_team_session_activity_trigger
  BEFORE UPDATE ON team_sessions
  FOR EACH ROW
  EXECUTE FUNCTION update_team_session_activity();

-- 10. Comments for documentation
COMMENT ON TABLE team_credentials IS 'Stores email and password for team authentication';
COMMENT ON TABLE team_sessions IS 'Tracks which users are logged into which teams';
COMMENT ON COLUMN team_members.can_login IS 'Whether this member can login to the team account';
