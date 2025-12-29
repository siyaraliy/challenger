-- ============================================
-- FINAL CHAT RLS FIX
-- Bu SQL'i Supabase SQL Editor'da çalıştırın
-- ============================================

-- ============================================
-- 1. RPC FONKSİYONUNU SECURITY DEFINER YAP
-- Bu, fonksiyonun RLS'i bypass etmesini sağlar
-- ============================================

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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 2. TEAM CHAT ROOM FONKSİYONUNU DA GÜNCELLE
-- ============================================

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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 3. MEMBER EKLEME FONKSİYONUNU DA GÜNCELLE
-- ============================================

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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- DONE!
-- ============================================
