-- ============================================
-- CHAT SYSTEM MIGRATION
-- Challenger App - Real-time Chat with Supabase
-- Created: 2024-12-15
-- ============================================

-- ============================================
-- 1. CHAT ROOMS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS chat_rooms (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  type VARCHAR(20) NOT NULL CHECK (type IN ('direct', 'team_group')),
  name VARCHAR(100),  -- For group chats
  team_id UUID REFERENCES teams(id) ON DELETE CASCADE,  -- For team_group type
  created_by UUID REFERENCES profiles(id),
  last_message_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for team lookup
CREATE INDEX IF NOT EXISTS idx_chat_rooms_team ON chat_rooms(team_id);
CREATE INDEX IF NOT EXISTS idx_chat_rooms_last_message ON chat_rooms(last_message_at DESC);

-- ============================================
-- 2. CHAT PARTICIPANTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS chat_participants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
  participant_type VARCHAR(10) NOT NULL CHECK (participant_type IN ('user', 'team')),
  participant_id UUID NOT NULL,
  status VARCHAR(20) DEFAULT 'approved' CHECK (status IN ('pending', 'approved', 'rejected')),
  role VARCHAR(20) DEFAULT 'member' CHECK (role IN ('admin', 'member')),
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(room_id, participant_type, participant_id)
);

-- Indexes for participant lookup
CREATE INDEX IF NOT EXISTS idx_chat_participants_room ON chat_participants(room_id);
CREATE INDEX IF NOT EXISTS idx_chat_participants_user ON chat_participants(participant_id, status);
CREATE INDEX IF NOT EXISTS idx_chat_participants_pending ON chat_participants(room_id, status) WHERE status = 'pending';

-- ============================================
-- 3. CHAT MESSAGES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
  sender_type VARCHAR(10) NOT NULL CHECK (sender_type IN ('user', 'team')),
  sender_id UUID NOT NULL,
  content TEXT NOT NULL,
  message_type VARCHAR(20) DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'video', 'system')),
  media_url TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for message queries
CREATE INDEX IF NOT EXISTS idx_chat_messages_room ON chat_messages(room_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender ON chat_messages(sender_id);

-- ============================================
-- 4. ENABLE REALTIME
-- ============================================
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;

-- ============================================
-- 5. RLS POLICIES
-- ============================================

-- Enable RLS
ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Chat Rooms Policies
CREATE POLICY "Users can view their chat rooms"
  ON chat_rooms FOR SELECT
  USING (
    id IN (
      SELECT room_id FROM chat_participants 
      WHERE participant_id = auth.uid() AND status = 'approved'
    )
  );

CREATE POLICY "Users can create direct chat rooms"
  ON chat_rooms FOR INSERT
  WITH CHECK (
    type = 'direct' AND created_by = auth.uid()
  );

-- Chat Participants Policies
CREATE POLICY "Users can view participants of their rooms"
  ON chat_participants FOR SELECT
  USING (
    room_id IN (
      SELECT room_id FROM chat_participants 
      WHERE participant_id = auth.uid() AND status = 'approved'
    )
    OR participant_id = auth.uid()  -- Can see own pending requests
  );

CREATE POLICY "Users can join rooms"
  ON chat_participants FOR INSERT
  WITH CHECK (
    participant_id = auth.uid()
  );

CREATE POLICY "Admins can update participant status"
  ON chat_participants FOR UPDATE
  USING (
    room_id IN (
      SELECT room_id FROM chat_participants 
      WHERE participant_id = auth.uid() AND role = 'admin' AND status = 'approved'
    )
  );

-- Chat Messages Policies
CREATE POLICY "Approved participants can view messages"
  ON chat_messages FOR SELECT
  USING (
    room_id IN (
      SELECT room_id FROM chat_participants 
      WHERE participant_id = auth.uid() AND status = 'approved'
    )
  );

CREATE POLICY "Approved participants can send messages"
  ON chat_messages FOR INSERT
  WITH CHECK (
    room_id IN (
      SELECT room_id FROM chat_participants 
      WHERE participant_id = auth.uid() AND status = 'approved'
    )
    AND sender_id = auth.uid()
  );

-- ============================================
-- 6. TRIGGERS
-- ============================================

-- Function to update last_message_at on new message
CREATE OR REPLACE FUNCTION update_chat_room_last_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE chat_rooms 
  SET last_message_at = NEW.created_at, updated_at = NOW()
  WHERE id = NEW.room_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_last_message
  AFTER INSERT ON chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION update_chat_room_last_message();

-- Function to auto-create team chat room when team is created
CREATE OR REPLACE FUNCTION create_team_chat_room()
RETURNS TRIGGER AS $$
DECLARE
  new_room_id UUID;
BEGIN
  -- Create a chat room for the team
  INSERT INTO chat_rooms (type, name, team_id, created_by)
  VALUES ('team_group', NEW.name || ' Sohbeti', NEW.id, NEW.captain_id)
  RETURNING id INTO new_room_id;
  
  -- Add captain as admin participant (auto-approved)
  INSERT INTO chat_participants (room_id, participant_type, participant_id, status, role)
  VALUES (new_room_id, 'user', NEW.captain_id, 'approved', 'admin');
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for new teams
DROP TRIGGER IF EXISTS trigger_create_team_chat ON teams;
CREATE TRIGGER trigger_create_team_chat
  AFTER INSERT ON teams
  FOR EACH ROW
  EXECUTE FUNCTION create_team_chat_room();

-- Function to auto-add team member to chat with pending status
CREATE OR REPLACE FUNCTION add_member_to_team_chat()
RETURNS TRIGGER AS $$
DECLARE
  team_room_id UUID;
BEGIN
  -- Find the team's chat room
  SELECT id INTO team_room_id
  FROM chat_rooms
  WHERE team_id = NEW.team_id AND type = 'team_group'
  LIMIT 1;
  
  -- If room exists, add member with pending status
  IF team_room_id IS NOT NULL THEN
    INSERT INTO chat_participants (room_id, participant_type, participant_id, status, role)
    VALUES (team_room_id, 'user', NEW.user_id, 'pending', 'member')
    ON CONFLICT (room_id, participant_type, participant_id) DO NOTHING;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for new team members
DROP TRIGGER IF EXISTS trigger_add_member_to_chat ON team_members;
CREATE TRIGGER trigger_add_member_to_chat
  AFTER INSERT ON team_members
  FOR EACH ROW
  EXECUTE FUNCTION add_member_to_team_chat();

-- ============================================
-- 7. HELPER FUNCTIONS
-- ============================================

-- Function to get or create direct chat room between two users
CREATE OR REPLACE FUNCTION get_or_create_direct_chat(user1_id UUID, user2_id UUID)
RETURNS UUID AS $$
DECLARE
  existing_room_id UUID;
  new_room_id UUID;
BEGIN
  -- Check if direct chat already exists
  SELECT cr.id INTO existing_room_id
  FROM chat_rooms cr
  WHERE cr.type = 'direct'
    AND EXISTS (
      SELECT 1 FROM chat_participants cp1 
      WHERE cp1.room_id = cr.id AND cp1.participant_id = user1_id
    )
    AND EXISTS (
      SELECT 1 FROM chat_participants cp2 
      WHERE cp2.room_id = cr.id AND cp2.participant_id = user2_id
    )
  LIMIT 1;
  
  IF existing_room_id IS NOT NULL THEN
    RETURN existing_room_id;
  END IF;
  
  -- Create new direct chat room
  INSERT INTO chat_rooms (type, created_by)
  VALUES ('direct', user1_id)
  RETURNING id INTO new_room_id;
  
  -- Add both participants as approved
  INSERT INTO chat_participants (room_id, participant_type, participant_id, status, role)
  VALUES 
    (new_room_id, 'user', user1_id, 'approved', 'member'),
    (new_room_id, 'user', user2_id, 'approved', 'member');
  
  RETURN new_room_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 8. CREATE CHAT ROOMS FOR EXISTING TEAMS
-- ============================================
-- Run this only if you have existing teams without chat rooms
DO $$
DECLARE
  team_record RECORD;
  new_room_id UUID;
BEGIN
  FOR team_record IN 
    SELECT t.id, t.name, t.captain_id 
    FROM teams t 
    WHERE NOT EXISTS (
      SELECT 1 FROM chat_rooms cr WHERE cr.team_id = t.id
    )
  LOOP
    -- Create chat room
    INSERT INTO chat_rooms (type, name, team_id, created_by)
    VALUES ('team_group', team_record.name || ' Sohbeti', team_record.id, team_record.captain_id)
    RETURNING id INTO new_room_id;
    
    -- Add captain as admin
    INSERT INTO chat_participants (room_id, participant_type, participant_id, status, role)
    VALUES (new_room_id, 'user', team_record.captain_id, 'approved', 'admin');
    
    -- Add existing members with approved status (since they were already in team)
    INSERT INTO chat_participants (room_id, participant_type, participant_id, status, role)
    SELECT new_room_id, 'user', tm.user_id, 'approved', 'member'
    FROM team_members tm
    WHERE tm.team_id = team_record.id AND tm.user_id != team_record.captain_id;
    
  END LOOP;
END $$;

-- ============================================
-- DONE!
-- ============================================
