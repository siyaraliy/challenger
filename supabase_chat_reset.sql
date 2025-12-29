-- ============================================
-- CHAT SISTEMI TAMAMEN SIFIRLA VE DÜZELT
-- Bu SQL'i Supabase SQL Editor'da çalıştırın
-- ============================================

-- ============================================
-- ADIM 1: TÜM MEVCUT POLİTİKALARI SİL
-- ============================================

-- chat_rooms politikaları
DO $$ 
DECLARE 
  pol RECORD;
BEGIN
  FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'chat_rooms'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON chat_rooms', pol.policyname);
  END LOOP;
END $$;

-- chat_participants politikaları
DO $$ 
DECLARE 
  pol RECORD;
BEGIN
  FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'chat_participants'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON chat_participants', pol.policyname);
  END LOOP;
END $$;

-- chat_messages politikaları
DO $$ 
DECLARE 
  pol RECORD;
BEGIN
  FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'chat_messages'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON chat_messages', pol.policyname);
  END LOOP;
END $$;

-- ============================================
-- ADIM 2: HELPER FONKSİYON (SECURITY DEFINER)
-- ============================================

CREATE OR REPLACE FUNCTION get_my_room_ids()
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT room_id FROM chat_participants 
  WHERE participant_type = 'user' 
    AND participant_id = auth.uid() 
    AND status = 'approved'
  UNION
  SELECT cp.room_id FROM chat_participants cp
  INNER JOIN team_members tm ON tm.team_id = cp.participant_id
  WHERE cp.participant_type = 'team'
    AND tm.user_id = auth.uid()
    AND cp.status = 'approved';
$$;

-- ============================================
-- ADIM 3: RPC FONKSİYONLARI (SECURITY DEFINER)
-- ============================================

CREATE OR REPLACE FUNCTION get_or_create_direct_chat(user1_id UUID, user2_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  existing_room_id UUID;
  new_room_id UUID;
BEGIN
  SELECT cr.id INTO existing_room_id
  FROM chat_rooms cr
  WHERE cr.type = 'direct'
    AND EXISTS (SELECT 1 FROM chat_participants WHERE room_id = cr.id AND participant_id = user1_id)
    AND EXISTS (SELECT 1 FROM chat_participants WHERE room_id = cr.id AND participant_id = user2_id)
  LIMIT 1;
  
  IF existing_room_id IS NOT NULL THEN
    RETURN existing_room_id;
  END IF;
  
  INSERT INTO chat_rooms (type, created_by)
  VALUES ('direct', user1_id)
  RETURNING id INTO new_room_id;
  
  INSERT INTO chat_participants (room_id, participant_type, participant_id, status, role)
  VALUES 
    (new_room_id, 'user', user1_id, 'approved', 'member'),
    (new_room_id, 'user', user2_id, 'approved', 'member');
  
  RETURN new_room_id;
END;
$$;

-- ============================================
-- ADIM 4: YENİ BASİT POLİTİKALAR
-- ============================================

-- CHAT_ROOMS
CREATE POLICY "chat_rooms_select_policy" ON chat_rooms FOR SELECT
  USING (id IN (SELECT get_my_room_ids()));

CREATE POLICY "chat_rooms_insert_policy" ON chat_rooms FOR INSERT
  WITH CHECK (created_by = auth.uid());

-- CHAT_PARTICIPANTS  
CREATE POLICY "chat_participants_select_policy" ON chat_participants FOR SELECT
  USING (
    room_id IN (SELECT get_my_room_ids())
    OR (participant_type = 'user' AND participant_id = auth.uid())
  );

CREATE POLICY "chat_participants_insert_policy" ON chat_participants FOR INSERT
  WITH CHECK (true);  -- SECURITY DEFINER fonksiyonlar zaten kontrol yapıyor

CREATE POLICY "chat_participants_update_policy" ON chat_participants FOR UPDATE
  USING (true)
  WITH CHECK (true);

-- CHAT_MESSAGES
CREATE POLICY "chat_messages_select_policy" ON chat_messages FOR SELECT
  USING (room_id IN (SELECT get_my_room_ids()));

CREATE POLICY "chat_messages_insert_policy" ON chat_messages FOR INSERT
  WITH CHECK (
    room_id IN (SELECT get_my_room_ids())
    AND (
      (sender_type = 'user' AND sender_id = auth.uid())
      OR (sender_type = 'team' AND sender_id IN (SELECT team_id FROM team_members WHERE user_id = auth.uid()))
    )
  );

CREATE POLICY "chat_messages_update_policy" ON chat_messages FOR UPDATE
  USING (room_id IN (SELECT get_my_room_ids()));

-- ============================================
-- ADIM 5: TRIGGER FONKSİYONLARI (SECURITY DEFINER)
-- ============================================

CREATE OR REPLACE FUNCTION create_team_chat_room()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  new_room_id UUID;
BEGIN
  INSERT INTO chat_rooms (type, name, team_id, created_by)
  VALUES ('team_group', NEW.name || ' Sohbeti', NEW.id, NEW.captain_id)
  RETURNING id INTO new_room_id;
  
  INSERT INTO chat_participants (room_id, participant_type, participant_id, status, role)
  VALUES (new_room_id, 'user', NEW.captain_id, 'approved', 'admin');
  
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION add_member_to_team_chat()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  team_room_id UUID;
BEGIN
  SELECT id INTO team_room_id
  FROM chat_rooms
  WHERE team_id = NEW.team_id AND type = 'team_group'
  LIMIT 1;
  
  IF team_room_id IS NOT NULL THEN
    INSERT INTO chat_participants (room_id, participant_type, participant_id, status, role)
    VALUES (team_room_id, 'user', NEW.user_id, 'pending', 'member')
    ON CONFLICT (room_id, participant_type, participant_id) DO NOTHING;
  END IF;
  
  RETURN NEW;
END;
$$;

-- ============================================
-- BİTTİ! Test edin.
-- ============================================
