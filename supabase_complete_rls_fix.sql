-- ============================================
-- COMPLETE RLS FIX - Infinite Recursion Çözümü
-- Bu SQL'i Supabase SQL Editor'da çalıştırın
-- ============================================

-- ============================================
-- 1. TÜM MEVCUT POLİTİKALARI KALDIR
-- ============================================

-- chat_rooms policies
DROP POLICY IF EXISTS "Users can view their chat rooms" ON chat_rooms;
DROP POLICY IF EXISTS "Users and teams can view their chat rooms" ON chat_rooms;
DROP POLICY IF EXISTS "Users can create direct chat rooms" ON chat_rooms;
DROP POLICY IF EXISTS "Users can create chat rooms" ON chat_rooms;
DROP POLICY IF EXISTS "chat_rooms_select" ON chat_rooms;
DROP POLICY IF EXISTS "chat_rooms_insert" ON chat_rooms;

-- chat_participants policies
DROP POLICY IF EXISTS "Users can view participants of their rooms" ON chat_participants;
DROP POLICY IF EXISTS "Users can join rooms" ON chat_participants;
DROP POLICY IF EXISTS "Users can add participants" ON chat_participants;
DROP POLICY IF EXISTS "Admins can update participant status" ON chat_participants;
DROP POLICY IF EXISTS "chat_participants_select" ON chat_participants;
DROP POLICY IF EXISTS "chat_participants_insert" ON chat_participants;

-- chat_messages policies
DROP POLICY IF EXISTS "Approved participants can view messages" ON chat_messages;
DROP POLICY IF EXISTS "Approved participants can send messages" ON chat_messages;
DROP POLICY IF EXISTS "Users and teams can view messages" ON chat_messages;
DROP POLICY IF EXISTS "Users and teams can send messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can mark messages as read" ON chat_messages;
DROP POLICY IF EXISTS "Team members can send as team" ON chat_messages;
DROP POLICY IF EXISTS "chat_messages_select" ON chat_messages;
DROP POLICY IF EXISTS "chat_messages_insert" ON chat_messages;

-- ============================================
-- 2. HELPER FUNCTION: Kullanıcının erişebileceği room_id'ler
-- Bu fonksiyon SECURITY DEFINER ile çalışır, RLS bypass eder
-- ============================================

CREATE OR REPLACE FUNCTION get_user_accessible_rooms(p_user_id UUID)
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  -- Kullanıcının direkt katılımcı olduğu odalar
  SELECT room_id FROM chat_participants 
  WHERE participant_type = 'user' 
    AND participant_id = p_user_id 
    AND status = 'approved'
  UNION
  -- Kullanıcının takımlarının katılımcı olduğu odalar
  SELECT cp.room_id FROM chat_participants cp
  INNER JOIN team_members tm ON tm.team_id = cp.participant_id
  WHERE cp.participant_type = 'team'
    AND tm.user_id = p_user_id
    AND cp.status = 'approved'
$$;

-- ============================================
-- 3. CHAT_ROOMS POLİTİKALARI
-- ============================================

-- SELECT: Kullanıcı erişebildiği odaları görebilir
CREATE POLICY "chat_rooms_select" ON chat_rooms FOR SELECT
  USING (id IN (SELECT get_user_accessible_rooms(auth.uid())));

-- INSERT: Kullanıcı oda oluşturabilir
CREATE POLICY "chat_rooms_insert" ON chat_rooms FOR INSERT
  WITH CHECK (created_by = auth.uid());

-- ============================================
-- 4. CHAT_PARTICIPANTS POLİTİKALARI
-- ============================================

-- SELECT: Kullanıcı erişebildiği odaların katılımcılarını görebilir
CREATE POLICY "chat_participants_select" ON chat_participants FOR SELECT
  USING (
    room_id IN (SELECT get_user_accessible_rooms(auth.uid()))
    OR
    -- Kendi bekleyen isteklerini de görebilir
    (participant_type = 'user' AND participant_id = auth.uid())
  );

-- INSERT: Katılımcı ekleme
CREATE POLICY "chat_participants_insert" ON chat_participants FOR INSERT
  WITH CHECK (
    -- Kendini ekleyebilir
    (participant_type = 'user' AND participant_id = auth.uid())
    OR
    -- Oluşturduğu odaya başkalarını ekleyebilir
    room_id IN (SELECT id FROM chat_rooms WHERE created_by = auth.uid())
  );

-- UPDATE: Admin katılımcı durumunu güncelleyebilir
CREATE POLICY "chat_participants_update" ON chat_participants FOR UPDATE
  USING (
    room_id IN (
      SELECT room_id FROM chat_participants 
      WHERE participant_id = auth.uid() 
        AND role = 'admin' 
        AND status = 'approved'
        AND participant_type = 'user'
    )
  );

-- ============================================
-- 5. CHAT_MESSAGES POLİTİKALARI
-- ============================================

-- SELECT: Kullanıcı erişebildiği odalardaki mesajları görebilir
CREATE POLICY "chat_messages_select" ON chat_messages FOR SELECT
  USING (room_id IN (SELECT get_user_accessible_rooms(auth.uid())));

-- INSERT: Mesaj gönderme
CREATE POLICY "chat_messages_insert" ON chat_messages FOR INSERT
  WITH CHECK (
    -- Erişebildiği odaya mesaj atabilir
    room_id IN (SELECT get_user_accessible_rooms(auth.uid()))
    AND
    (
      -- Kendi adına mesaj atıyor
      (sender_type = 'user' AND sender_id = auth.uid())
      OR
      -- Takım adına mesaj atıyor (takım üyesi olmalı)
      (sender_type = 'team' AND sender_id IN (
        SELECT team_id FROM team_members WHERE user_id = auth.uid()
      ))
    )
  );

-- UPDATE: Mesaj okundu olarak işaretleme
CREATE POLICY "chat_messages_update" ON chat_messages FOR UPDATE
  USING (room_id IN (SELECT get_user_accessible_rooms(auth.uid())))
  WITH CHECK (is_read = true);

-- ============================================
-- DONE!
-- ============================================
